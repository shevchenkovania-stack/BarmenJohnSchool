/// Результат валидации ингредиентов
class IngredientValidationResult {
  final bool isSafe;
  final List<String> warnings;
  final List<String> errors;
  final List<String> blockedIngredients;
  final List<String> allergenWarnings;

  const IngredientValidationResult({
    required this.isSafe,
    this.warnings = const [],
    this.errors = const [],
    this.blockedIngredients = const [],
    this.allergenWarnings = const [],
  });

  bool get hasWarnings => warnings.isNotEmpty || allergenWarnings.isNotEmpty;
  bool get hasErrors => errors.isNotEmpty;
}

/// Результат валидации сочетания
class CombinationValidationResult {
  final bool isSafe;
  final String? warning;
  final String? alternative;
  final RiskLevel riskLevel;

  const CombinationValidationResult({
    required this.isSafe,
    this.warning,
    this.alternative,
    this.riskLevel = RiskLevel.none,
  });
}

enum RiskLevel {
  none,
  low,
  medium,
  high,
  critical,
}

/// Модель ингредиента с данными для валидации
class IngredientData {
  final String name;
  final double abv; // Alcohol by Volume (0-100)
  final double sugarGramsPer100ml;
  final List<String> allergens;
  final IngredientCategory category;
  final bool isRaw; // Сырой продукт (яйца, рыба)

  const IngredientData({
    required this.name,
    this.abv = 0,
    this.sugarGramsPer100ml = 0,
    this.allergens = const [],
    required this.category,
    this.isRaw = false,
  });
}

enum IngredientCategory {
  spirit, // Крепкий алкоголь (водка, виски, джин)
  liqueur, // Ликёр
  wine, // Вино, вермут
  beer, // Пиво
  sparkling, // Игристое, шампанское
  juice, // Сок
  soda, // Газировка
  syrup, // Сироп
  fruit, // Фрукт/ягода
  herb, // Трава, специя
  dairy, // Молочные
  egg, // Яйца
  bitter, // Биттеры
  other, // Прочее
}

/// Сервис безопасности для конструктора коктейлей.
///
/// Проверяет:
/// - Опасные/несъедобные ингредиенты
/// - Рискованные сочетания (алкоголь + энергетики)
/// - Аллергены
/// - Предупреждения для начинающих
class CocktailSafetyService {
  // ════════════════════════════════════════════════════════════════════════════
  //  🚫 BLACKLIST — Полностью запрещённые ингредиенты
  // ════════════════════════════════════════════════════════════════════════════

  static const _absoluteBlacklist = {
    // Бытовая химия
    'мыло', 'soap', 'моющее', 'detergent', 'bleach', 'хлорка', 'аммиак',
    'ammonia', 'ацетон', 'acetone', 'бензин', 'gasoline', 'керосин',
    'kerosene', 'растворитель', 'solvent',

    // Лекарства (без консультации)
    'аспирин', 'aspirin', 'ибупрофен', 'ibuprofen', 'парацетамол',
    'paracetamol', 'антибиотик', 'antibiotic', 'валериана', 'valerian',
    'успокоительное', 'sedative', 'снотворное', 'sleeping pill',

    // Наркотики
    'марихуана', 'marijuana', 'кокаин', 'cocaine', 'экстази', 'ecstasy',

    // Токсичные растения
    'белладонна', 'belladonna', 'дурман', 'datura', 'болиголов',
    'hemlock', 'аконит', 'aconite', 'олеандр', 'oleander',

    // Прочее опасное
    'чернила', 'ink', 'краска', 'paint', 'клей', 'glue', 'парафин',
    'paraffin', 'свечи', 'candles',
  };

  // ════════════════════════════════════════════════════════════════════════════
  //  ⚠️ GREYLIST — Требуют предупреждения
  // ════════════════════════════════════════════════════════════════════════════

  static const _greylistItems = {
    // Сырые яйца — риск сальмонеллы
    'яйцо': '⚠️ Сырое яйцо: риск сальмонеллы. Используйте пастеризованные.',
    'яйца': '⚠️ Сырые яйца: риск сальмонеллы. Используйте пастеризованные.',
    'egg': '⚠️ Raw egg: salmonella risk. Use pasteurized.',

    // Сырая рыба
    'рыба': '⚠️ Сырая рыба: риск паразитов. Используйте суши-класс.',
    'суши': '⚠️ Сырая рыба: требуется суши-класс.',

    // Энергетики + алкоголь
    'энергетик': '⚠️ Энергетик + алкоголь: нагрузка на сердце!',
    'red bull': '⚠️ Energy + alcohol: heart strain risk!',
    'monster': '⚠️ Energy + alcohol: heart strain risk!',

    // Высокая концентрация алкоголя
    'absinthe': '⚠️ Абсент: до 72% ABV. Пейте осторожно!',
    'абсент': '⚠️ Абсент: до 72% ABV. Пейте осторожно!',
    'everclear': '⚠️ Everclear: до 95% ABV. Опасно в чистом виде!',
    'спирт': '⚠️ Чистый спирт: используйте только как добавку (5-10 мл)!',
  };

  // ════════════════════════════════════════════════════════════════════════════
  //  🥜 ALLERGENS — Распространённые аллергены
  // ════════════════════════════════════════════════════════════════════════════

  static const _allergenMap = {
    // Молочные
    'молоко': 'молочные продукты',
    'сливки': 'молочные продукты',
    'молочные': 'молочные продукты',
    'cream': 'dairy',
    'milk': 'dairy',

    // Орехи
    'миндаль': 'орехи',
    'фундук': 'орехи',
    'грецкий': 'орехи',
    'кальвадос': 'орехи (яблочный бренди)',
    'амаретто': 'орехи (миндаль)',
    ' almond': 'nuts',
    'hazelnut': 'nuts',

    // Глютен
    'пиво': 'глютен',
    'виски': 'глютен',
    'beer': 'gluten',
    'whiskey': 'gluten',
    'whisky': 'gluten',

    // Яйца
    'яйцо': 'яйца',
    'яйца': 'яйца',
    'egg': 'eggs',

    // Соя
    'соя': 'соя',
    'soy': 'soy',

    // Цитрусовые
    'апельсин': 'цитрусовые',
    'лимон': 'цитрусовые',
    'лайм': 'цитрусовые',
    'грейпфрут': 'цитрусовые',
    'orange': 'citrus',
    'lemon': 'citrus',
    'lime': 'citrus',
    'grapefruit': 'citrus',
  };

  // ════════════════════════════════════════════════════════════════════════════
  //  🧪 CONFLICTING COMBINATIONS — Несовместимые сочетания
  // ════════════════════════════════════════════════════════════════════════════

  static const _conflictingCombinations = [
    _ConflictRule(
      ingredients: ['молоко', 'лимон'],
      ingredientsEn: ['milk', 'lemon'],
      issue: 'Молоко + кислота = створаживание',
      issueEn: 'Milk + acid = curdling',
      alternative: 'Используйте сливки 33% или кокосовое молоко',
    ),
    _ConflictRule(
      ingredients: ['молоко', 'лайм'],
      ingredientsEn: ['milk', 'lime'],
      issue: 'Молоко + кислота = створаживание',
      issueEn: 'Milk + acid = curdling',
      alternative: 'Используйте сливки 33% или кокосовое молоко',
    ),
    _ConflictRule(
      ingredients: ['сливки', 'лимон'],
      ingredientsEn: ['cream', 'lemon'],
      issue: 'Сливки + высокая кислотность = расслоение',
      issueEn: 'Cream + high acid = separation',
      alternative: 'Снизьте кислоту или используйте жирные сливки 35%+',
    ),
    _ConflictRule(
      ingredients: ['энергетик', 'водка'],
      ingredientsEn: ['energy', 'vodka'],
      issue: 'Алкоголь + энергетик = нагрузка на сердце',
      issueEn: 'Alcohol + energy drink = heart strain',
      alternative: 'Замените энергетик на содовую или тоник',
      riskLevel: RiskLevel.high,
    ),
    _ConflictRule(
      ingredients: ['энергетик', 'джин'],
      ingredientsEn: ['energy', 'gin'],
      issue: 'Алкоголь + энергетик = нагрузка на сердце',
      issueEn: 'Alcohol + energy drink = heart strain',
      alternative: 'Замените энергетик на тоник',
      riskLevel: RiskLevel.high,
    ),
    _ConflictRule(
      ingredients: ['кола', 'молоко'],
      ingredientsEn: ['cola', 'milk'],
      issue: 'Кола + молоко = неприятная реакция',
      issueEn: 'Cola + milk = unpleasant reaction',
      alternative: 'Не смешивайте',
    ),
  ];

  // ════════════════════════════════════════════════════════════════════════════
  //  📊 БАЗА ДАННЫХ ИНГРЕДИЕНТОВ (для расчётов)
  // ════════════════════════════════════════════════════════════════════════════

  static const _ingredientDatabase = {
    // Крепкий алкоголь
    'водка': IngredientData(
        name: 'водка', abv: 40, category: IngredientCategory.spirit),
    'vodka': IngredientData(
        name: 'vodka', abv: 40, category: IngredientCategory.spirit),
    'джин': IngredientData(
        name: 'джин', abv: 40, category: IngredientCategory.spirit),
    'gin': IngredientData(
        name: 'gin', abv: 40, category: IngredientCategory.spirit),
    'виски': IngredientData(
        name: 'виски',
        abv: 40,
        category: IngredientCategory.spirit,
        allergens: ['глютен']),
    'whiskey': IngredientData(
        name: 'whiskey',
        abv: 40,
        category: IngredientCategory.spirit,
        allergens: ['gluten']),
    'ром': IngredientData(
        name: 'ром', abv: 40, category: IngredientCategory.spirit),
    'rum': IngredientData(
        name: 'rum', abv: 40, category: IngredientCategory.spirit),
    'текила': IngredientData(
        name: 'текила', abv: 40, category: IngredientCategory.spirit),
    'tequila': IngredientData(
        name: 'tequila', abv: 40, category: IngredientCategory.spirit),
    'бренди': IngredientData(
        name: 'бренди', abv: 40, category: IngredientCategory.spirit),
    'brandy': IngredientData(
        name: 'brandy', abv: 40, category: IngredientCategory.spirit),
    'коньяк': IngredientData(
        name: 'коньяк', abv: 40, category: IngredientCategory.spirit),
    'cognac': IngredientData(
        name: 'cognac', abv: 40, category: IngredientCategory.spirit),

    // Ликёры
    'трипл-сек': IngredientData(
        name: 'трипл-сек',
        abv: 30,
        sugarGramsPer100ml: 35,
        category: IngredientCategory.liqueur),
    'triple sec': IngredientData(
        name: 'triple sec',
        abv: 30,
        sugarGramsPer100ml: 35,
        category: IngredientCategory.liqueur),
    'куантро': IngredientData(
        name: 'куантро',
        abv: 40,
        sugarGramsPer100ml: 25,
        category: IngredientCategory.liqueur),
    'cointreau': IngredientData(
        name: 'cointreau',
        abv: 40,
        sugarGramsPer100ml: 25,
        category: IngredientCategory.liqueur),
    'амаретто': IngredientData(
        name: 'амаретто',
        abv: 28,
        sugarGramsPer100ml: 30,
        category: IngredientCategory.liqueur,
        allergens: ['орехи']),
    'amaretto': IngredientData(
        name: 'amaretto',
        abv: 28,
        sugarGramsPer100ml: 30,
        category: IngredientCategory.liqueur,
        allergens: ['nuts']),
    'бейлиз': IngredientData(
        name: 'бейлиз',
        abv: 17,
        sugarGramsPer100ml: 20,
        category: IngredientCategory.liqueur,
        allergens: ['молочные']),
    'baileys': IngredientData(
        name: 'baileys',
        abv: 17,
        sugarGramsPer100ml: 20,
        category: IngredientCategory.liqueur,
        allergens: ['dairy']),
    'калуа': IngredientData(
        name: 'калуа',
        abv: 20,
        sugarGramsPer100ml: 35,
        category: IngredientCategory.liqueur),
    'kahlua': IngredientData(
        name: 'kahlua',
        abv: 20,
        sugarGramsPer100ml: 35,
        category: IngredientCategory.liqueur),

    // Вина
    'вермут': IngredientData(
        name: 'вермут',
        abv: 16,
        sugarGramsPer100ml: 15,
        category: IngredientCategory.wine),
    'vermouth': IngredientData(
        name: 'vermouth',
        abv: 16,
        sugarGramsPer100ml: 15,
        category: IngredientCategory.wine),
    'шампанское': IngredientData(
        name: 'шампанское', abv: 12, category: IngredientCategory.sparkling),
    'champagne': IngredientData(
        name: 'champagne', abv: 12, category: IngredientCategory.sparkling),
    'просекко': IngredientData(
        name: 'просекко', abv: 11, category: IngredientCategory.sparkling),
    'prosecco': IngredientData(
        name: 'prosecco', abv: 11, category: IngredientCategory.sparkling),
    'вино белое': IngredientData(
        name: 'вино белое', abv: 12, category: IngredientCategory.wine),
    'white wine': IngredientData(
        name: 'white wine', abv: 12, category: IngredientCategory.wine),
    'вино красное': IngredientData(
        name: 'вино красное', abv: 13, category: IngredientCategory.wine),
    'red wine': IngredientData(
        name: 'red wine', abv: 13, category: IngredientCategory.wine),

    // Соки
    'апельсиновый сок': IngredientData(
        name: 'апельсиновый сок',
        sugarGramsPer100ml: 9,
        category: IngredientCategory.juice,
        allergens: ['цитрусовые']),
    'orange juice': IngredientData(
        name: 'orange juice',
        sugarGramsPer100ml: 9,
        category: IngredientCategory.juice,
        allergens: ['citrus']),
    'лимонный сок': IngredientData(
        name: 'лимонный сок',
        sugarGramsPer100ml: 3,
        category: IngredientCategory.juice,
        allergens: ['цитрусовые']),
    'lemon juice': IngredientData(
        name: 'lemon juice',
        sugarGramsPer100ml: 3,
        category: IngredientCategory.juice,
        allergens: ['citrus']),
    'лаймовый сок': IngredientData(
        name: 'лаймовый сок',
        sugarGramsPer100ml: 2,
        category: IngredientCategory.juice,
        allergens: ['цитрусовые']),
    'lime juice': IngredientData(
        name: 'lime juice',
        sugarGramsPer100ml: 2,
        category: IngredientCategory.juice,
        allergens: ['citrus']),
    'клюквенный сок': IngredientData(
        name: 'клюквенный сок',
        sugarGramsPer100ml: 12,
        category: IngredientCategory.juice),
    'cranberry juice': IngredientData(
        name: 'cranberry juice',
        sugarGramsPer100ml: 12,
        category: IngredientCategory.juice),
    'ананасовый сок': IngredientData(
        name: 'ананасовый сок',
        sugarGramsPer100ml: 10,
        category: IngredientCategory.juice),
    'pineapple juice': IngredientData(
        name: 'pineapple juice',
        sugarGramsPer100ml: 10,
        category: IngredientCategory.juice),

    // Сиропы
    'сахарный сироп': IngredientData(
        name: 'сахарный сироп',
        sugarGramsPer100ml: 67,
        category: IngredientCategory.syrup),
    'simple syrup': IngredientData(
        name: 'simple syrup',
        sugarGramsPer100ml: 67,
        category: IngredientCategory.syrup),
    'кленовый сироп': IngredientData(
        name: 'кленовый сироп',
        sugarGramsPer100ml: 67,
        category: IngredientCategory.syrup),
    'maple syrup': IngredientData(
        name: 'maple syrup',
        sugarGramsPer100ml: 67,
        category: IngredientCategory.syrup),

    // Газировки
    'тоник': IngredientData(
        name: 'тоник',
        sugarGramsPer100ml: 8,
        category: IngredientCategory.soda),
    'tonic': IngredientData(
        name: 'tonic',
        sugarGramsPer100ml: 8,
        category: IngredientCategory.soda),
    'содовая':
        IngredientData(name: 'содовая', category: IngredientCategory.soda),
    'soda': IngredientData(name: 'soda', category: IngredientCategory.soda),
    'кола': IngredientData(
        name: 'кола',
        sugarGramsPer100ml: 11,
        category: IngredientCategory.soda),
    'cola': IngredientData(
        name: 'cola',
        sugarGramsPer100ml: 11,
        category: IngredientCategory.soda),

    // Молочные
    'сливки': IngredientData(
        name: 'сливки',
        sugarGramsPer100ml: 3,
        category: IngredientCategory.dairy,
        allergens: ['молочные']),
    'cream': IngredientData(
        name: 'cream',
        sugarGramsPer100ml: 3,
        category: IngredientCategory.dairy,
        allergens: ['dairy']),
    'молоко': IngredientData(
        name: 'молоко',
        sugarGramsPer100ml: 5,
        category: IngredientCategory.dairy,
        allergens: ['молочные']),
    'milk': IngredientData(
        name: 'milk',
        sugarGramsPer100ml: 5,
        category: IngredientCategory.dairy,
        allergens: ['dairy']),

    // Биттеры
    'ангостура': IngredientData(
        name: 'ангостура', abv: 45, category: IngredientCategory.bitter),
    'angostura': IngredientData(
        name: 'angostura', abv: 45, category: IngredientCategory.bitter),
  };

  // ════════════════════════════════════════════════════════════════════════════
  //  PUBLIC API
  // ════════════════════════════════════════════════════════════════════════════

  /// Валидация списка ингредиентов
  IngredientValidationResult validateIngredients(List<String> ingredients) {
    final errors = <String>[];
    final warnings = <String>[];
    final blocked = <String>[];
    final allergens = <String>[];

    for (final ingredient in ingredients) {
      final lower = ingredient.toLowerCase().trim();

      // Проверка блэклиста
      for (final banned in _absoluteBlacklist) {
        if (lower.contains(banned)) {
          errors.add('🚫 "$ingredient" — запрещённый ингредиент');
          blocked.add(ingredient);
        }
      }

      // Проверка greylist
      for (final entry in _greylistItems.entries) {
        if (lower.contains(entry.key)) {
          warnings.add(entry.value);
        }
      }

      // Проверка аллергенов
      for (final entry in _allergenMap.entries) {
        if (lower.contains(entry.key)) {
          if (!allergens.contains(entry.value)) {
            allergens.add(entry.value);
          }
        }
      }
    }

    return IngredientValidationResult(
      isSafe: errors.isEmpty,
      warnings: warnings,
      errors: errors,
      blockedIngredients: blocked,
      allergenWarnings: allergens.map((a) => '🥜 Аллерген: $a').toList(),
    );
  }

  /// Проверка сочетания ингредиентов
  CombinationValidationResult validateCombination(List<String> ingredients) {
    final lower = ingredients.map((e) => e.toLowerCase()).toList();

    for (final rule in _conflictingCombinations) {
      // Проверяем пару ингредиентов на конфликт
      bool found = false;
      for (final ing1 in lower) {
        for (final ing2 in lower) {
          if (ing1 == ing2) continue;

          final matchesRule1 = rule.ingredients.any((r) => ing1.contains(r)) ||
              rule.ingredientsEn.any((r) => ing1.contains(r));
          final matchesRule2 = rule.ingredients.any((r) => ing2.contains(r)) ||
              rule.ingredientsEn.any((r) => ing2.contains(r));

          if (matchesRule1 && matchesRule2) {
            found = true;
            break;
          }
        }
        if (found) break;
      }

      if (found) {
        return CombinationValidationResult(
          isSafe: rule.riskLevel != RiskLevel.critical,
          warning: rule.issue,
          alternative: rule.alternative,
          riskLevel: rule.riskLevel,
        );
      }
    }

    return const CombinationValidationResult(isSafe: true);
  }

  /// Получить данные ингредиента
  IngredientData? getIngredientData(String name) {
    final lower = name.toLowerCase().trim();

    for (final entry in _ingredientDatabase.entries) {
      if (lower.contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }
    return null;
  }

  /// Рассчитать примерный ABV коктейля
  double calculateAbv(List<MapEntry<String, int>> ingredientsWithAmounts) {
    double totalMl = 0;
    double alcoholMl = 0;

    for (final entry in ingredientsWithAmounts) {
      final name = entry.key;
      final amountMl = entry.value.toDouble();

      totalMl += amountMl;

      final data = getIngredientData(name);
      if (data != null && data.abv > 0) {
        alcoholMl += amountMl * (data.abv / 100);
      }
    }

    if (totalMl == 0) return 0;
    return (alcoholMl / totalMl) * 100;
  }

  /// Рассчитать примерное содержание сахара
  double calculateSugarGrams(
      List<MapEntry<String, int>> ingredientsWithAmounts) {
    double totalSugar = 0;

    for (final entry in ingredientsWithAmounts) {
      final name = entry.key;
      final amountMl = entry.value.toDouble();

      final data = getIngredientData(name);
      if (data != null && data.sugarGramsPer100ml > 0) {
        totalSugar += (amountMl / 100) * data.sugarGramsPer100ml;
      }
    }

    return totalSugar;
  }

  /// Получить категории выбранных ингредиентов
  Set<IngredientCategory> getIngredientCategories(List<String> ingredients) {
    final categories = <IngredientCategory>{};

    for (final name in ingredients) {
      final data = getIngredientData(name);
      if (data != null) {
        categories.add(data.category);
      }
    }

    return categories;
  }

  /// Проверить, есть ли среди ингредиентов аллергены
  List<String> detectAllergens(List<String> ingredients) {
    final allergens = <String>[];

    for (final ingredient in ingredients) {
      final lower = ingredient.toLowerCase();

      for (final entry in _allergenMap.entries) {
        if (lower.contains(entry.key)) {
          if (!allergens.contains(entry.value)) {
            allergens.add(entry.value);
          }
        }
      }
    }

    return allergens;
  }

  /// Получить предупреждения для начинающих
  List<String> getBeginnerWarnings(List<String> ingredients, int strength) {
    final warnings = <String>[];

    // Высокая крепость
    if (strength >= 8) {
      warnings.add(
          '💡 Крепость $strength/10 — уменьшите порцию или добавьте больше миксера');
    }

    // Много ингредиентов
    if (ingredients.length > 5) {
      warnings.add(
          '💡 ${ingredients.length} ингредиентов — начните с 3-4 для лучшего баланса');
    }

    // Нет базы (крепкий алкоголь)
    final categories = getIngredientCategories(ingredients);
    if (!categories.contains(IngredientCategory.spirit) &&
        !categories.contains(IngredientCategory.liqueur) &&
        !categories.contains(IngredientCategory.wine)) {
      warnings
          .add('💡 Нет базового алкоголя — добавьте водку/джин/ром для основы');
    }

    // Нет баланса (только алкоголь)
    if (!categories.contains(IngredientCategory.juice) &&
        !categories.contains(IngredientCategory.soda) &&
        !categories.contains(IngredientCategory.syrup) &&
        categories.contains(IngredientCategory.spirit)) {
      warnings.add('💡 Только алкоголь — добавьте сок или сироп для баланса');
    }

    return warnings;
  }
}

/// Внутреннее правило конфликта
class _ConflictRule {
  final List<String> ingredients;
  final List<String> ingredientsEn;
  final String issue;
  final String issueEn;
  final String alternative;
  final RiskLevel riskLevel;

  const _ConflictRule({
    required this.ingredients,
    required this.ingredientsEn,
    required this.issue,
    required this.issueEn,
    required this.alternative,
    this.riskLevel = RiskLevel.medium,
  });
}
