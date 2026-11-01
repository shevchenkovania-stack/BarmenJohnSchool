/// Сгенерированный коктейль от AI миксолога.
///
/// Содержит полную информацию о коктейле:
/// - название и описание
/// - ингредиенты с пропорциями
/// - пошаговая инструкция
/// - метод приготовления
/// - тип бокала
/// - ПРОФИЛЬ: ABV, сахар, калории, аллергены
/// - ВАУ-эффект и объяснение
/// - совет профи, факт и секрет
import 'package:coin/features/cocktail_builder/models/cocktail_types.dart';
import 'package:coin/features/cocktail_builder/models/flavor_profile.dart';
import 'package:coin/features/cocktail_builder/models/mixology_explanation.dart';

/// Тип коктейля по классификации
enum CocktailType {
  classic,
  signature,
  experimental,
}

class GeneratedCocktail {
  final String name;
  final String description;
  final List<CocktailIngredient> ingredients;
  final List<String> steps;
  final CocktailMethod method; // Метод приготовления
  final CocktailGlass glass; // Тип бокала

  // ════════════════════════════════════════════════════════════════════════════
  //  🎯 ПОЛЯ ДЛЯ ВАРИАНТОВ КОКТЕЙЛЕЙ
  // ════════════════════════════════════════════════════════════════════════════

  final List<String> usedIngredients; // Использованные ингредиенты
  final List<String> skippedIngredients; // Пропущенные ингредиенты
  final List<String> skippedReasons; // Причины пропуска
  final double matchScore; // Оценка совпадения (0.0-1.0)
  final CocktailType
      cocktailType; // Тип коктейля (classic/signature/experimental)

  // 🖼️ Связь с базой данных
  final String? imageUrl; // URL картинки из TheCocktailDB
  final String? sourceCocktailId; // ID из базы если это классический рецепт

  // 💡 Подсказки AI
  final String?
      missingForClassic; // "До классического Мохито не хватает только мяты"
  final List<String> suggestedReplacements; // Предложенные замены

  // ════════════════════════════════════════════════════════════════════════════
  //  📊 ПРОФЕССИОНАЛЬНЫЕ МЕТРИКИ
  // ════════════════════════════════════════════════════════════════════════════

  final double abv; // Alcohol by Volume %
  final double sugarGrams; // Граммы сахара
  final int calories; // Калории
  final List<String> allergens; // Аллергены

  // ════════════════════════════════════════════════════════════════════════════
  //  ✨ ДОПОЛНИТЕЛЬНАЯ ИНФОРМАЦИЯ
  // ════════════════════════════════════════════════════════════════════════════

  final String wowEffect; // ВАУ-эффект
  final String whyItWorks; // Объяснение почему работает
  final String? garnish; // Украшение
  final String? serving; // Как подавать
  final FlavorProfile? flavorProfile; // Профиль вкуса (опционально)
  final MixologyExplanation? explanation; // Объяснение миксолога (опционально)
  final String? proTip; // Совет профи
  final String? fact; // Факт
  final String? secret; // Секрет

  const GeneratedCocktail({
    required this.name,
    required this.description,
    required this.ingredients,
    required this.steps,
    required this.method,
    required this.glass,
    this.usedIngredients = const [],
    this.skippedIngredients = const [],
    this.skippedReasons = const [],
    this.matchScore = 0.0,
    this.cocktailType = CocktailType.signature,
    this.imageUrl,
    this.sourceCocktailId,
    this.missingForClassic,
    this.suggestedReplacements = const [],
    this.abv = 0,
    this.sugarGrams = 0,
    this.calories = 0,
    this.allergens = const [],
    required this.wowEffect,
    required this.whyItWorks,
    this.garnish,
    this.serving,
    this.flavorProfile,
    this.explanation,
    this.proTip,
    this.fact,
    this.secret,
  });

  /// Создать из JSON
  factory GeneratedCocktail.fromJson(Map<String, dynamic> json) {
    // Парсим ингредиенты
    final ingredientsList = json['ingredients'] as List? ?? [];
    final ingredients =
        ingredientsList.map((i) => CocktailIngredient.fromJson(i)).toList();

    // Парсим шаги (массив строк)
    final stepsList = json['steps'] as List? ?? [];
    final steps = stepsList.map((s) => s.toString()).toList();

    // Парсим метод приготовления (расширенный)
    CocktailMethod method;
    switch ((json['method'] as String? ?? '').toLowerCase()) {
      case 'stir':
        method = CocktailMethod.stir;
        break;
      case 'build':
        method = CocktailMethod.build;
        break;
      case 'muddle':
        method = CocktailMethod.muddle;
        break;
      case 'blend':
        method = CocktailMethod.blend;
        break;
      case 'layered':
        method = CocktailMethod.layered;
        break;
      default:
        method = CocktailMethod.shake;
    }

    // Парсим тип бокала
    CocktailGlass glass;
    switch ((json['glass'] as String? ?? '').toLowerCase()) {
      case 'rocks':
        glass = CocktailGlass.rocks;
        break;
      case 'highball':
        glass = CocktailGlass.highball;
        break;
      case 'martini':
        glass = CocktailGlass.martini;
        break;
      case 'flute':
        glass = CocktailGlass.flute;
        break;
      case 'shot':
        glass = CocktailGlass.shot;
        break;
      case 'coupe':
        glass = CocktailGlass.coupe;
        break;
      default:
        glass = CocktailGlass.coupe;
    }

    // Парсим аллергены
    final allergensList = json['allergens'] as List? ?? [];
    final allergens = allergensList.map((a) => a.toString()).toList();

    // Парсим новые поля для вариантов
    final usedIngredientsList =
        json['used'] as List? ?? json['usedIngredients'] as List? ?? [];
    final usedIngredients =
        usedIngredientsList.map((i) => i.toString()).toList();

    final skippedIngredientsList =
        json['skipped'] as List? ?? json['skippedIngredients'] as List? ?? [];
    final skippedIngredients =
        skippedIngredientsList.map((i) => i.toString()).toList();

    final skippedReasonsList = json['reason_skipped'] as List? ??
        json['skippedReasons'] as List? ??
        [];
    final skippedReasons = skippedReasonsList.map((i) => i.toString()).toList();

    final matchScore = (json['match_score'] as num?)?.toDouble() ??
        (json['matchScore'] as num?)?.toDouble() ??
        0.0;

    CocktailType cocktailType;
    switch ((json['cocktailType'] as String? ?? json['type'] ?? 'signature')
        .toLowerCase()) {
      case 'classic':
        cocktailType = CocktailType.classic;
        break;
      case 'experimental':
        cocktailType = CocktailType.experimental;
        break;
      default:
        cocktailType = CocktailType.signature;
    }

    // Парсим новые поля подсказок
    final missingForClassic = json['missing_for_classic'] as String? ??
        json['missingForClassic'] as String?;
    final replacementsList = json['suggested_replacements'] as List? ??
        json['suggestedReplacements'] as List? ??
        [];
    final suggestedReplacements =
        replacementsList.map((i) => i.toString()).toList();

    // Парсим поля связи с базой
    final imageUrl =
        json['imageUrl'] as String? ?? json['image_url'] as String?;
    final sourceCocktailId = json['sourceCocktailId'] as String? ??
        json['source_cocktail_id'] as String?;

    return GeneratedCocktail(
      name: json['name'] ?? 'Без названия',
      description: json['description'] ?? '',
      ingredients: ingredients,
      steps: steps,
      method: method,
      glass: glass,
      usedIngredients: usedIngredients,
      skippedIngredients: skippedIngredients,
      skippedReasons: skippedReasons,
      matchScore: matchScore,
      cocktailType: cocktailType,
      imageUrl: imageUrl,
      sourceCocktailId: sourceCocktailId,
      missingForClassic: missingForClassic,
      suggestedReplacements: suggestedReplacements,
      abv: (json['abv'] as num?)?.toDouble() ?? 0,
      sugarGrams: (json['sugarGrams'] as num?)?.toDouble() ?? 0,
      calories: json['calories'] as int? ?? 0,
      allergens: allergens,
      wowEffect: json['wowEffect'] ?? json['why_it_works'] ?? '',
      whyItWorks: json['whyItWorks'] ?? json['explanation'] ?? '',
      garnish: json['garnish'],
      serving: json['serving'],
      flavorProfile: json['flavorProfile'] != null
          ? FlavorProfile.fromJson(json['flavorProfile'])
          : json['flavor_profile'] != null
              ? FlavorProfile.fromJson(json['flavor_profile'])
              : null,
      explanation: json['explanation'] != null && json['explanation'] is! String
          ? MixologyExplanation.fromJson(json['explanation'])
          : null,
      proTip: json['pro_tip'] ?? json['proTip'],
      fact: json['fact'],
      secret: json['secret'],
    );
  }

  /// Конвертировать в JSON
  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'ingredients': ingredients.map((i) => i.toJson()).toList(),
        'steps': steps,
        'method': method.name,
        'glass': glass.name,
        'usedIngredients': usedIngredients,
        'skippedIngredients': skippedIngredients,
        'skippedReasons': skippedReasons,
        'matchScore': matchScore,
        'cocktailType': cocktailType.name,
        'imageUrl': imageUrl,
        'sourceCocktailId': sourceCocktailId,
        'missingForClassic': missingForClassic,
        'suggestedReplacements': suggestedReplacements,
        'abv': abv,
        'sugarGrams': sugarGrams,
        'calories': calories,
        'allergens': allergens,
        'wowEffect': wowEffect,
        'whyItWorks': whyItWorks,
        'garnish': garnish,
        'serving': serving,
        'flavorProfile': flavorProfile?.toJson(),
        'explanation': explanation?.toJson(),
        'proTip': proTip,
        'fact': fact,
        'secret': secret,
      };

  // ════════════════════════════════════════════════════════════════════════════
  //  🎯 ВЫЧИСЛЯЕМЫЕ СВОЙСТВА
  // ════════════════════════════════════════════════════════════════════════════

  /// Общий объём коктейля в мл
  double get totalVolumeMl =>
      ingredients.fold(0, (sum, ing) => sum + ing.amountMl);

  /// Категория крепости
  String get strengthCategory {
    if (abv <= 10) return 'Лёгкий';
    if (abv <= 20) return 'Средний';
    return 'Крепкий';
  }

  /// Категория сладости
  String get sweetnessCategory {
    if (sugarGrams <= 5) return 'Сухой';
    if (sugarGrams <= 15) return 'Полусладкий';
    return 'Сладкий';
  }

  /// Есть ли аллергены
  bool get hasAllergens => allergens.isNotEmpty;

  /// Стандартная порция алкоголя (1 стандартная = 10мл чистого этанола)
  double get standardDrinks => (abv / 100) * totalVolumeMl / 10;
}

/// Ингредиент коктейля с количеством.
class CocktailIngredient {
  final String name;
  final int amountMl; // Количество в мл

  const CocktailIngredient({
    required this.name,
    required this.amountMl,
  });

  /// Создать из JSON
  factory CocktailIngredient.fromJson(Map<String, dynamic> json) {
    return CocktailIngredient(
      name: json['name'] ?? json['ingredient'] ?? '',
      amountMl: _parseInt(json['amountMl'] ?? json['amount']),
    );
  }

  /// Конвертировать в JSON
  Map<String, dynamic> toJson() => {
        'name': name,
        'amountMl': amountMl,
      };

  /// Безопасный парсинг числа
  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) {
      // Удаляем "мл", "ml", "oz" и т.д.
      final cleaned = value.replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(cleaned)?.round() ?? 0;
    }
    return 0;
  }

  /// Красивое отображение количества
  String get formattedAmount => '$amountMl мл';
}
