import 'package:coin/core/models/cocktail.dart';
import 'package:coin/core/repositories/cocktail_repository.dart';
import 'package:coin/features/cocktail_builder/models/generated_cocktail.dart';
import 'package:coin/features/cocktail_builder/models/cocktail_types.dart';
import 'package:coin/features/cocktail_builder/models/flavor_profile.dart';
import 'package:coin/features/cocktail_builder/models/mixology_explanation.dart';
import 'package:coin/features/cocktail_builder/view/cocktail_algorithm.dart';
import 'package:coin/features/cocktail_builder/services/cocktail_safety_service.dart';

class MatchedCocktail {
  final Cocktail source;
  final List<String> usedIngredients;
  final List<String> missingIngredients;
  final double matchScore;
  final CocktailType cocktailType;

  const MatchedCocktail({
    required this.source,
    required this.usedIngredients,
    required this.missingIngredients,
    required this.matchScore,
    required this.cocktailType,
  });

  bool get isExactMatch => missingIngredients.isEmpty;
  int get missingCount => missingIngredients.length;
}

class CocktailMatcherService {
  final CocktailRepository _cocktailRepo;
  final CocktailSafetyService _safetyService = CocktailSafetyService();

  CocktailMatcherService(this._cocktailRepo);

  bool get isDatabaseLoaded => _cocktailRepo.getAllCached().isNotEmpty;

  List<MatchedCocktail> match(List<String> userIngredients) {
    if (userIngredients.length < 2) return [];

    final userLower =
        userIngredients.map((i) => i.toLowerCase().trim()).toSet();
    final allCocktails = _cocktailRepo.getAllCached();

    if (allCocktails.isEmpty) return [];

    final results = <_ScoredMatch>[];

    for (final cocktail in allCocktails) {
      if (cocktail.ingredients.isEmpty) continue;

      final used = <String>[];
      final missing = <String>[];

      for (final ing in cocktail.ingredients) {
        final lower = ing.toLowerCase().trim();
        if (userLower.contains(lower)) {
          used.add(ing);
        } else {
          missing.add(ing);
        }
      }

      if (used.length < 2) continue;

      final score = used.length / cocktail.ingredients.length;

      results.add(_ScoredMatch(
        cocktail: cocktail,
        usedIngredients: used,
        missingIngredients: missing,
        score: score,
      ));
    }

    results.sort((a, b) => b.score.compareTo(a.score));

    final top = results.take(5).toList();

    return top.map((r) {
      final type = r.score >= 1.0
          ? CocktailType.classic
          : r.score >= 0.7
              ? CocktailType.classic
              : CocktailType.signature;

      return MatchedCocktail(
        source: r.cocktail,
        usedIngredients: r.usedIngredients,
        missingIngredients: r.missingIngredients,
        matchScore: double.parse(r.score.toStringAsFixed(2)),
        cocktailType: type,
      );
    }).toList();
  }

  GeneratedCocktail toGeneratedCocktail(MatchedCocktail match) {
    final src = match.source;
    final ingredients = src.ingredients;
    final measures = src.measures;

    final cocktailIngredients = <CocktailIngredient>[];
    for (var i = 0; i < ingredients.length; i++) {
      cocktailIngredients.add(CocktailIngredient(
        name: ingredients[i],
        amountMl: _parseMeasureToMl(measures.length > i ? measures[i] : ''),
      ));
    }

    final ingredientNames = ingredients.map((i) => i.toLowerCase()).toList();
    final method = CocktailAlgorithm.detectMethod(ingredientNames, false);
    final glass = _parseGlass(src.strGlass);

    final wow = CocktailAlgorithm.detectWowEffect(ingredientNames);

    return GeneratedCocktail(
      name: src.strDrink,
      description: _buildDescription(match),
      ingredients: cocktailIngredients,
      steps: _parseInstructions(src.strInstructions),
      method: method,
      glass: glass,
      usedIngredients: match.usedIngredients,
      skippedIngredients: match.missingIngredients,
      skippedReasons:
          match.missingIngredients.map((_) => 'нет в наличии').toList(),
      matchScore: match.matchScore,
      cocktailType: match.cocktailType,
      imageUrl: src.strDrinkThumb,
      sourceCocktailId: src.idDrink,
      missingForClassic: match.isExactMatch ? null : _buildMissingHint(match),
      suggestedReplacements: _buildReplacements(match),
      abv: _estimateAbv(cocktailIngredients),
      sugarGrams: _estimateSugar(cocktailIngredients),
      calories: _estimateCalories(cocktailIngredients),
      allergens: _safetyService.detectAllergens(ingredientNames),
      wowEffect: wow,
      whyItWorks: match.isExactMatch
          ? 'Классический рецепт, проверенный временем'
          : 'Авторская вариация на основе доступных ингредиентов',
      garnish: null,
      serving: 'Подавать в бокале ${src.strGlass}',
      flavorProfile: null,
      explanation: null,
      proTip: _buildProTip(match),
      fact: null,
      secret: null,
    );
  }

  String _buildDescription(MatchedCocktail match) {
    if (match.isExactMatch) {
      return 'Классический коктейль «${match.source.strDrink}». Все ингредиенты есть в наличии.';
    }
    return 'Коктейль «${match.source.strDrink}». Не хватает: ${match.missingIngredients.join(', ')}.';
  }

  String? _buildMissingHint(MatchedCocktail match) {
    if (match.missingIngredients.isEmpty) return null;
    final missing = match.missingIngredients.join(', ');
    return 'До «${match.source.strDrink}» не хватает: $missing';
  }

  List<String> _buildReplacements(MatchedCocktail match) {
    final replacements = <String>[];
    for (final missing in match.missingIngredients) {
      final similar = _findSimilarIngredient(missing);
      if (similar != null) {
        replacements.add('$missing → $similar');
      }
    }
    return replacements;
  }

  String? _findSimilarIngredient(String ingredient) {
    final lower = ingredient.toLowerCase();

    if (lower.contains('vodka') || lower.contains('водк')) return 'джин';
    if (lower.contains('gin') || lower.contains('джин')) return 'водка';
    if (lower.contains('whiskey') ||
        lower.contains('виски') ||
        lower.contains('burbo')) return 'ром';
    if (lower.contains('rum') || lower.contains('ром')) return 'виски';
    if (lower.contains('lime') || lower.contains('лайм')) return 'лимонный сок';
    if (lower.contains('lemon') || lower.contains('лимон'))
      return 'лаймовый сок';
    if (lower.contains('triple sec') || lower.contains('трипл'))
      return 'куантро';
    if (lower.contains('vermouth') || lower.contains('вермут'))
      return 'сухой вермут';
    if (lower.contains('simple syrup') || lower.contains('сахарный'))
      return 'кленовый сироп';
    if (lower.contains('mint') || lower.contains('мят')) return 'базилик';
    if (lower.contains('soda') || lower.contains('содовая')) return 'тоник';
    if (lower.contains('tonic') || lower.contains('тоник')) return 'содовая';

    return null;
  }

  String _buildProTip(MatchedCocktail match) {
    if (match.isExactMatch) {
      return 'Все ингредиенты в наличии — можешь готовить прямо сейчас!';
    }
    return 'Добавь ${match.missingIngredients.first} для полного рецепта';
  }

  double _estimateAbv(List<CocktailIngredient> ingredients) {
    double totalMl = 0;
    double alcoholMl = 0;

    for (final ing in ingredients) {
      totalMl += ing.amountMl;
      final data = _safetyService.getIngredientData(ing.name);
      if (data != null && data.abv > 0) {
        alcoholMl += ing.amountMl * (data.abv / 100);
      }
    }

    if (totalMl == 0) return 0;
    return double.parse(((alcoholMl / totalMl) * 100).toStringAsFixed(1));
  }

  double _estimateSugar(List<CocktailIngredient> ingredients) {
    double total = 0;
    for (final ing in ingredients) {
      final data = _safetyService.getIngredientData(ing.name);
      if (data != null && data.sugarGramsPer100ml > 0) {
        total += (ing.amountMl / 100) * data.sugarGramsPer100ml;
      }
    }
    return double.parse(total.toStringAsFixed(1));
  }

  int _estimateCalories(List<CocktailIngredient> ingredients) {
    final abv = _estimateAbv(ingredients);
    final sugar = _estimateSugar(ingredients);
    final totalMl = ingredients.fold(0, (sum, i) => sum + i.amountMl);
    final alcoholMl = totalMl * (abv / 100);
    return (alcoholMl * 0.789 * 7 + sugar * 4).round();
  }

  int _parseMeasureToMl(String measure) {
    if (measure.isEmpty) return 0;

    final lower = measure.toLowerCase().trim();

    double amount = 1;
    final numMatch = RegExp(r'([\d.\s/]+)').firstMatch(lower);
    if (numMatch != null) {
      amount = _parseFraction(numMatch.group(1)!);
    }

    if (lower.contains('oz')) return (amount * 30).round();
    if (lower.contains('ml')) return amount.round();
    if (lower.contains('cl')) return (amount * 10).round();
    if (lower.contains('shot')) return int.tryParse(amount.toString()) ?? 45;
    if (lower.contains('cup')) return (amount * 240).round();
    if (lower.contains('dash') || lower.contains('dashes'))
      return (amount * 1).round();
    if (lower.contains('tsp') ||
        lower.contains('teaspoon') ||
        lower.contains('чайн')) return (amount * 5).round();
    if (lower.contains('tbsp') ||
        lower.contains('tablespoon') ||
        lower.contains('столов')) return (amount * 15).round();
    if (lower.contains('drops') || lower.contains('drop'))
      return amount.round();

    if (lower.contains('part') || lower.contains('parts'))
      return (amount * 30).round();
    if (lower.contains('top') || lower.contains('fill')) return 60;

    if (amount > 0) return (amount * 30).round();

    return 30;
  }

  double _parseFraction(String s) {
    s = s.trim();
    if (s.contains('/')) {
      final parts = s.split(RegExp(r'\s+'));
      double total = 0;
      for (final part in parts) {
        if (part.contains('/')) {
          final frac = part.split('/');
          final num = double.tryParse(frac[0]) ?? 0;
          final den = double.tryParse(frac[1]) ?? 1;
          total += den > 0 ? num / den : 0;
        } else {
          total += double.tryParse(part) ?? 0;
        }
      }
      return total;
    }
    return double.tryParse(s) ?? 1;
  }

  List<String> _parseInstructions(String instructions) {
    if (instructions.isEmpty) return ['Инструкция отсутствует'];

    final steps = instructions
        .split(RegExp(r'[.\n]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && s.length > 5)
        .toList();

    if (steps.isEmpty) return [instructions];
    return steps;
  }

  CocktailGlass _parseGlass(String glass) {
    final lower = glass.toLowerCase();
    if (lower.contains('martini') || lower.contains('cocktail glass'))
      return CocktailGlass.martini;
    if (lower.contains('highball') || lower.contains('collins'))
      return CocktailGlass.highball;
    if (lower.contains('rocks') ||
        lower.contains('old-fashioned') ||
        lower.contains('old fashioned')) return CocktailGlass.rocks;
    if (lower.contains('shot')) return CocktailGlass.shot;
    if (lower.contains('flute')) return CocktailGlass.flute;
    if (lower.contains('coupe')) return CocktailGlass.coupe;
    return CocktailGlass.coupe;
  }

  List<GeneratedCocktail> generateVariants(List<String> userIngredients) {
    final matches = match(userIngredients);

    if (matches.isEmpty) {
      return [];
    }

    return matches.map((m) => toGeneratedCocktail(m)).toList();
  }

  GeneratedCocktail generateSingle(List<String> userIngredients) {
    final matches = match(userIngredients);

    if (matches.isEmpty) {
      return _createNoMatchCocktail(userIngredients);
    }

    return toGeneratedCocktail(matches.first);
  }

  GeneratedCocktail _createNoMatchCocktail(List<String> userIngredients) {
    final wow = CocktailAlgorithm.detectWowEffect(
      userIngredients.map((i) => i.toLowerCase()).toList(),
    );

    return GeneratedCocktail(
      name: 'Нет подходящего рецепта',
      description:
          'Из выбранных ингредиентов не найдено известных коктейлей. Попробуйте добавить другие ингредиенты.',
      ingredients: userIngredients
          .map((i) => CocktailIngredient(name: i, amountMl: 30))
          .toList(),
      steps: ['Нет инструкции для данного набора ингредиентов'],
      method: CocktailMethod.shake,
      glass: CocktailGlass.coupe,
      matchScore: 0,
      cocktailType: CocktailType.experimental,
      wowEffect: wow,
      whyItWorks: 'Сочетание не распознано',
      serving: '—',
      flavorProfile: const FlavorProfile(
        strength: 5,
        sweetness: 5,
        acidity: 5,
        bitterness: 2,
        sparkling: false,
      ),
      explanation: const MixologyExplanation(
        base: '—',
        balance: '—',
        aroma: '—',
        overall: 'Попробуйте другой набор ингредиентов',
      ),
      proTip:
          'Добавьте базовый алкоголь (водку, джин, ром) или цитрусовый сок для большего числа совпадений',
      fact: null,
      secret: null,
    );
  }
}

class _ScoredMatch {
  final Cocktail cocktail;
  final List<String> usedIngredients;
  final List<String> missingIngredients;
  final double score;

  const _ScoredMatch({
    required this.cocktail,
    required this.usedIngredients,
    required this.missingIngredients,
    required this.score,
  });
}
