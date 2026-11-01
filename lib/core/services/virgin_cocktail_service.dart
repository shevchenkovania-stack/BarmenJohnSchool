import 'package:coin/core/models/cocktail.dart';

/// Сервис для создания безалкогольных (virgin) версий коктейлей.
///
/// **Принцип работы:**
/// 1. Определяет алкогольные ингредиенты по базе из 50+ спиртных
/// 2. Удаляет все алкогольные ингредиенты из рецепта
/// 3. Если осталось ≥ 2 ингредиентов → создаёт Virgin версию
/// 4. Если осталось < 2 → коктейль НЕЛЬЗЯ сделать безалкогольным
///
/// **Примеры:**
/// ✅ Mojito → Mint + Lime + Sugar + Soda (4 ингредиента осталось)
/// ✅ Margarita → Lime + Salt (2 ингредиента осталось)
/// ❌ Martini → 0 ингредиентов (невозможно)
class VirginCocktailService {
  // ════════════════════════════════════════════════════════════════════════════
  //  База алкогольных ингредиентов (50+ позиций)
  // ════════════════════════════════════════════════════════════════════════════

  static const List<String> _alcoholicIngredients = [
    // Vodka
    'vodka',

    // Rum
    'rum', 'white rum', 'dark rum', 'golden rum', 'spiced rum', 'light rum',
    'bacardi', 'malibu',

    // Gin
    'gin', 'dry gin', 'london dry gin', 'plymouth gin',

    // Whiskey/Whisky
    'whiskey', 'whisky', 'scotch', 'bourbon', 'irish whiskey',
    'rye whiskey', 'canadian whisky', 'blended scotch',
    'jack daniels', 'jameson',

    // Tequila
    'tequila', 'silver tequila', 'gold tequila', 'reposado tequila',

    // Brandy/Cognac
    'brandy', 'cognac', 'armagnac', 'calvados',

    // Liqueurs
    'triple sec', 'curaçao', 'blue curaçao',
    'kahlua', 'baileys', 'amaretto', 'frangelico',
    'grand marnier', 'cointreau', 'chambord',
    'midori', 'peach schnapps', 'sloe gin',
    'drambuie', 'southern comfort', 'tia maria',

    // Vermouth & Aperitifs
    'vermouth', 'dry vermouth', 'sweet vermouth',
    'campari', 'aperol', 'pimm',

    // Wine & Sparkling
    'wine', 'red wine', 'white wine', 'rose wine',
    'champagne', 'prosecco', 'sparkling wine',
    'port', 'sherry', 'marsala',

    // Beer & Others
    'beer', 'lager', 'ale', 'stout',
    'sake', 'soju', 'mei kwei lu chiew',

    // Generic
    'liquor', 'spirit', 'alcohol',
  ];

  // ════════════════════════════════════════════════════════════════════════════
  //  Публичные методы
  // ════════════════════════════════════════════════════════════════════════════

  /// Проверить является ли ингредиент алкогольным
  bool isAlcoholic(String ingredient) {
    final lower = ingredient.toLowerCase().trim();
    return _alcoholicIngredients.any((alcohol) => lower.contains(alcohol));
  }

  /// Получить безалкогольные ингредиенты из списка
  List<String> getNonAlcoholicIngredients(List<String> ingredients) {
    return ingredients.where((ing) => !isAlcoholic(ing)).toList();
  }

  /// Можно ли сделать коктейль безалкогольным?
  ///
  /// **Критерий миксолога:** После удаления алкоголя должно остаться ≥ 2 ингредиентов
  /// И хотя бы один из них должен быть "базой" (liquid) а не просто garnish
  bool canMakeVirgin(List<String> ingredients) {
    final nonAlcoholic = getNonAlcoholicIngredients(ingredients);

    // Минимум 2 ингредиента
    if (nonAlcoholic.length < 2) {
      return false;
    }

    // Проверяем есть ли "жидкая база" (не просто фрукты/листья)
    final hasBase = nonAlcoholic.any((ing) => _isLiquidBase(ing));

    // Если только фрукты/украшения без жидкости - не коктейль
    if (!hasBase && nonAlcoholic.length < 3) {
      return false;
    }

    return true;
  }

  /// Проверить является ли ингредиент "жидкой базой" коктейля
  bool _isLiquidBase(String ingredient) {
    final liquidBases = [
      'juice',
      'soda',
      'tonic',
      'water',
      'cola',
      'ginger',
      'coffee',
      'tea',
      'milk',
      'cream',
      'coconut',
      'pineapple',
      'cranberry',
      'orange',
      'lime',
      'lemon',
      'grapefruit',
      'apple',
      'syrup',
      'grenadine',
      'chocolate',
    ];

    final lower = ingredient.toLowerCase();
    return liquidBases.any((base) => lower.contains(base));
  }

  /// Создать безалкогольную версию коктейля
  ///
  /// **Возвращает:**
  /// - Модифицированный Cocktail с пометкой "Virgin"
  /// - null если невозможно (осталось < 2 ингредиентов)
  Cocktail? createVirginFromCocktail(Cocktail cocktail) {
    // Получаем безалкогольные ингредиенты
    final nonAlcoholicIngredients = <String>[];
    final nonAlcoholicMeasures = <String>[];

    for (var i = 0; i < cocktail.ingredients.length; i++) {
      if (!isAlcoholic(cocktail.ingredients[i])) {
        nonAlcoholicIngredients.add(cocktail.ingredients[i]);
        if (i < cocktail.measures.length) {
          nonAlcoholicMeasures.add(cocktail.measures[i]);
        }
      }
    }

    // Проверяем что осталось достаточно ингредиентов
    if (nonAlcoholicIngredients.length < 2) {
      return null; // Невозможно сделать virgin
    }

    // Создаём virgin версию сохраняя ВСЕ поля оригинала
    return Cocktail(
      idDrink: 'virgin_${cocktail.idDrink}',
      strDrink: '${cocktail.strDrink} (Virgin)',
      strCategory: cocktail.strCategory,
      strAlcoholic: 'Non alcoholic',
      strGlass: cocktail.strGlass,
      strInstructions: _createVirginInstruction(
          cocktail.strInstructions, cocktail.ingredients),
      strDrinkThumb: cocktail.strDrinkThumb, // ✅ СОХРАНЯЕМ КАРТИНКУ!
      ingredients: nonAlcoholicIngredients,
      measures: nonAlcoholicMeasures,
    );
  }

  /// Создать virgin инструкцию (убрать упоминания алкоголя)
  String _createVirginInstruction(
      String? originalInstruction, List<String> originalIngredients) {
    if (originalInstruction == null || originalInstruction.isEmpty) {
      return 'Безалкогольная версия коктейля';
    }

    var instruction = originalInstruction;

    // Находим все алкогольные ингредиенты
    final alcoholicIngredients =
        originalIngredients.where(isAlcoholic).toList();

    if (alcoholicIngredients.isEmpty) {
      return instruction; // Нет алкоголя - оставляем как есть
    }

    // Разбиваем инструкцию на предложения
    final sentences = instruction.split(RegExp(r'(?<=[.!?])\s+'));

    // Фильтруем предложения которые содержат алкоголь
    final virginSentences = <String>[];

    for (final sentence in sentences) {
      final hasAlcohol = alcoholicIngredients.any(
          (alcohol) => sentence.toLowerCase().contains(alcohol.toLowerCase()));

      if (!hasAlcohol) {
        virginSentences.add(sentence);
      }
      // Иначе пропускаем предложение с алкоголем
    }

    // Собираем обратно
    if (virginSentences.isEmpty) {
      return 'Подавайте со льдом и украсьте по вкусу';
    }

    return 'Безалкогольная версия: ${virginSentences.join(' ')}';
  }

  /// Отфильтровать список коктейлей - оставить только те что можно сделать virgin
  List<Cocktail> filterVirginCapable(List<Cocktail> cocktails) {
    final result = <Cocktail>[];

    for (final cocktail in cocktails) {
      final virginVersion = createVirginFromCocktail(cocktail);
      if (virginVersion != null) {
        result.add(virginVersion);
      }
    }

    return result;
  }

  /// Статистика: сколько коктейлей можно сделать безалкогольными
  VirginStats getStats(List<Cocktail> cocktails) {
    int total = cocktails.length;
    int virginCapable = 0;
    int notCapable = 0;

    for (final cocktail in cocktails) {
      if (canMakeVirgin(cocktail.ingredients)) {
        virginCapable++;
      } else {
        notCapable++;
      }
    }

    return VirginStats(
      total: total,
      virginCapable: virginCapable,
      notCapable: notCapable,
      percentage: total > 0 ? (virginCapable / total * 100).round() : 0,
    );
  }
}

/// Статистика безалкогольных коктейлей
class VirginStats {
  final int total;
  final int virginCapable;
  final int notCapable;
  final int percentage;

  const VirginStats({
    required this.total,
    required this.virginCapable,
    required this.notCapable,
    required this.percentage,
  });

  @override
  String toString() {
    return 'VirginStats: $virginCapable/$total ($percentage%) можно сделать безалкогольными';
  }
}
