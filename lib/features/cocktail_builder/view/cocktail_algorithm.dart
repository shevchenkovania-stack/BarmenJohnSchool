// lib/features/cocktail_builder/utils/cocktail_algorithm.dart
//
// ПРОФЕССИОНАЛЬНЫЙ АЛГОРИТМ ДЛЯ СОЗДАНИЯ КОКТЕЙЛЕЙ
// Основано на IBA (International Bartenders Association) стандартах

import '../models/cocktail_types.dart';
import '../models/style_preset.dart' show StylePreset, StylePresetX;
import '../services/cocktail_safety_service.dart';

/// Результат анализа профиля коктейля
class CocktailProfileResult {
  final double abv; // Alcohol by Volume %
  final double sugarGrams; // Граммы сахара на порцию
  final double volumeMl; // Общий объём
  final int calories; // Примерные калории
  final List<String> allergens; // Аллергены
  final String strengthCategory; // Лёгкий/Средний/Крепкий
  final String sweetnessCategory; // Сухой/Полусухой/Сладкий
  final DifficultyLevel difficulty; // Сложность приготовления

  const CocktailProfileResult({
    required this.abv,
    required this.sugarGrams,
    required this.volumeMl,
    required this.calories,
    required this.allergens,
    required this.strengthCategory,
    required this.sweetnessCategory,
    required this.difficulty,
  });
}

enum DifficultyLevel {
  easy, // Build — просто налить
  medium, // Stir — перемешать
  advanced, // Shake — шейкер
  expert, // Muddle/Layered/Blend — техники
}

/// Расширенный метод приготовления
class CocktailMethodExtended {
  final CocktailMethod base;
  final String technique;
  final String techniqueDescription;
  final String iceType;
  final int difficultyScore;

  const CocktailMethodExtended({
    required this.base,
    required this.technique,
    required this.techniqueDescription,
    required this.iceType,
    required this.difficultyScore,
  });
}

class CocktailAlgorithm {
  static final _safetyService = CocktailSafetyService();

  // ════════════════════════════════════════════════════════════════════════════
  //  🧪 ОПРЕДЕЛЕНИЕ МЕТОДА ПРИГОТОВЛЕНИЯ
  // ════════════════════════════════════════════════════════════════════════════

  static CocktailMethodExtended detectMethodExtended(
    List<String> ingredients,
    bool sparkling,
    int strength,
  ) {
    final lower = ingredients.map((e) => e.toLowerCase()).toList();

    // ── MUDDLE: есть травы/ягоды которые нужно помять
    if (lower.any((i) =>
        i.contains('мята') ||
        i.contains('базилик') ||
        i.contains('розмарин') ||
        i.contains('muddle') ||
        i.contains('muddl') ||
        (i.contains('ягод') && !i.contains('сок')))) {
      return const CocktailMethodExtended(
        base: CocktailMethod.muddle,
        technique: 'Muddle & Shake',
        techniqueDescription:
            'Помни ингредиенты пестиком, затем встряхни в шейкере',
        iceType: 'кубики',
        difficultyScore: 4,
      );
    }

    // ── BLEND: замороженные/сливочные коктейли
    if (lower.any((i) =>
        i.contains('морожен') ||
        i.contains('ice cream') ||
        i.contains('банан') ||
        i.contains('banana') ||
        i.contains('клубника') && i.contains('заморож') ||
        i.contains('frozen') ||
        i.contains('blend'))) {
      return const CocktailMethodExtended(
        base: CocktailMethod.blend,
        technique: 'Blend',
        techniqueDescription: 'Смешай в блендере до однородности',
        iceType: 'дроблёный',
        difficultyScore: 3,
      );
    }

    // ── LAYERED: для шотов с разной плотностью
    if (strength >= 8 ||
        lower.any((i) =>
            i.contains('layered') ||
            i.contains('слоёный') ||
            i.contains('baileys') ||
            i.contains('бейлиз'))) {
      // Проверяем есть ли ингредиенты с разной плотностью
      final hasCream = lower.any((i) =>
          i.contains('сливк') || i.contains('cream') || i.contains('бейлиз'));
      final hasSpirit = lower.any((i) =>
          i.contains('водка') ||
          i.contains('джин') ||
          i.contains('виски') ||
          i.contains('vodka') ||
          i.contains('gin') ||
          i.contains('whiskey'));

      if (hasCream && hasSpirit) {
        return const CocktailMethodExtended(
          base: CocktailMethod.layered,
          technique: 'Layered',
          techniqueDescription:
              'Наливай по барной ложке, начиная с самого плотного',
          iceType: 'нет',
          difficultyScore: 5,
        );
      }
    }

    // ── BUILD: газированные напитки — НЕ ТРЯСТИ!
    if (sparkling ||
        lower.any((i) =>
            i.contains('содовая') ||
            i.contains('тоник') ||
            i.contains('газ') ||
            i.contains('шампан') ||
            i.contains('просекко') ||
            i.contains('кола') ||
            i.contains('soda') ||
            i.contains('tonic') ||
            i.contains('champagne') ||
            i.contains('prosecco'))) {
      return const CocktailMethodExtended(
        base: CocktailMethod.build,
        technique: 'Build in Glass',
        techniqueDescription:
            'Налей ингредиенты прямо в бокал со льдом, аккуратно перемешай',
        iceType: 'кубики',
        difficultyScore: 1,
      );
    }

    // ── SHAKE: соки, сливки, яйца — нужно охлаждение и смешивание
    if (lower.any((i) =>
        i.contains('сок') ||
        i.contains('juice') ||
        i.contains('апельсин') ||
        i.contains('orange') ||
        i.contains('лимон') ||
        i.contains('lemon') ||
        i.contains('лайм') ||
        i.contains('lime') ||
        i.contains('грейпфрут') ||
        i.contains('grapefruit') ||
        i.contains('сливк') ||
        i.contains('cream') ||
        i.contains('яйц') ||
        i.contains('egg') ||
        i.contains('кефир') ||
        i.contains('сироп'))) {
      return const CocktailMethodExtended(
        base: CocktailMethod.shake,
        technique: 'Shake & Strain',
        techniqueDescription:
            'Встряхни в шейкере со льдом 10-15 секунд, перелей через ситечко',
        iceType: 'кубики',
        difficultyScore: 3,
      );
    }

    // ── STIR: только алкоголь — классический метод
    return const CocktailMethodExtended(
      base: CocktailMethod.stir,
      technique: 'Stir',
      techniqueDescription:
          'Перемешай барной ложкой 30 секунд — охлади без разбавления',
      iceType: 'кубики (много)',
      difficultyScore: 2,
    );
  }

  // Стандартный метод (для обратной совместимости)
  static CocktailMethod detectMethod(List<String> ingredients, bool sparkling) {
    return detectMethodExtended(ingredients, sparkling, 5).base;
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  🥃 ОПРЕДЕЛЕНИЕ БОКАЛА
  // ════════════════════════════════════════════════════════════════════════════

  static CocktailGlass detectGlass(
    List<String> ingredients,
    bool sparkling,
    CocktailMethod method,
    int strength,
  ) {
    final lower = ingredients.map((e) => e.toLowerCase()).toList();

    // ── ФЛЮТЕ: игристые вина
    if (lower.any((i) =>
        i.contains('шампан') ||
        i.contains('champagne') ||
        i.contains('просекко') ||
        i.contains('prosecco') ||
        i.contains('кава') ||
        i.contains('cava') ||
        i.contains('игрист'))) {
      return CocktailGlass.flute;
    }

    // ── HIGHBALL: газированные/лонг-дринки
    if (sparkling || method == CocktailMethod.build) {
      return CocktailGlass.highball;
    }

    // ── MARTINI: для слоёных шотов и крепких аперитивов
    if (method == CocktailMethod.layered ||
        (strength >= 8 && method == CocktailMethod.stir)) {
      return CocktailGlass.martini;
    }

    // ── ROCKS: крепкие спиртные (Old Fashioned, Negroni)
    if (strength >= 7 && method == CocktailMethod.stir) {
      return CocktailGlass.rocks;
    }

    // ── COUPE: классический коктейльный бокал (Shake напитки)
    if (method == CocktailMethod.shake || method == CocktailMethod.muddle) {
      return CocktailGlass.coupe;
    }

    // ── Дефолт: Coupe
    return CocktailGlass.coupe;
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  ✨ ВАУ-ЭФФЕКТ ПО ИНГРЕДИЕНТАМ
  // ════════════════════════════════════════════════════════════════════════════

  static String detectWowEffect(List<String> ingredients) {
    final lower = ingredients.map((e) => e.toLowerCase()).toList();

    // Цитрусовая цедра
    if (lower.any((i) => i.contains('апельсин') || i.contains('orange'))) {
      return '🔥 Выжми цедру апельсина над бокалом через спичку — подожги эфирные масла!';
    }

    if (lower.any((i) => i.contains('грейпфрут') || i.contains('grapefruit'))) {
      return 'Выжми цедру грейпфрута прямо над бокалом — горько-сладкий аромат раскроется мгновенно';
    }

    if (lower.any((i) => i.contains('лимон') || i.contains('lemon'))) {
      return 'Срежь длинную полоску цедры, сверни спиралью — укрась край бокала';
    }

    if (lower.any((i) => i.contains('лайм') || i.contains('lime'))) {
      return 'Положи тонкое колечко лайма на край бокала — это и гарниш, и аромат при каждом глотке';
    }

    // Ягоды
    if (lower.any((i) => i.contains('вишн') || i.contains('cherry'))) {
      return 'Брось коктейльную вишню в бокал — классика никогда не стареет';
    }

    if (lower.any((i) =>
        i.contains('малин') ||
        i.contains('raspberry') ||
        i.contains('клубник') ||
        i.contains('strawberry'))) {
      return 'Слегка раздави ягоду перед добавлением — больше сока и аромата';
    }

    // Травы
    if (lower.any((i) => i.contains('мят') || i.contains('mint'))) {
      return 'Хлопни листья мяты между ладонями — эфирные масла раскроются ярче';
    }

    if (lower.any((i) => i.contains('базилик') || i.contains('basil'))) {
      return 'Положи лист базилика сверху — он будет медленно тонуть, добавляя аромат';
    }

    if (lower.any((i) => i.contains('розмарин') || i.contains('rosemary'))) {
      return 'Подожги веточку розмарина на 5 секунд — дымный аромат впечатлит';
    }

    // Специи
    if (lower.any((i) => i.contains('имбир') || i.contains('ginger'))) {
      return 'Свежий имбирь нарежь тонкими слайсами — острота и аромат гарантированы';
    }

    if (lower.any((i) =>
        i.contains('корица') ||
        i.contains('cinnamon') ||
        i.contains('кардамон') ||
        i.contains('cardamom'))) {
      return 'Посыпь щепотку корицы сверху — визуал + тёплый пряный аромат';
    }

    // Шоколад/кофе
    if (lower.any((i) =>
        i.contains('шоколад') ||
        i.contains('chocolate') ||
        i.contains('какао') ||
        i.contains('cocoa'))) {
      return 'Сделай ободок из какао/тёртого шоколада — барная классика';
    }

    if (lower.any((i) =>
        i.contains('кофе') ||
        i.contains('coffee') ||
        i.contains('калуа') ||
        i.contains('kahlua'))) {
      return 'Укрась тремя кофейными зёрнами — символ «глаз тигра»';
    }

    // Соль/сахар
    if (lower.any((i) => i.contains('соль') || i.contains('salt'))) {
      return 'Сделай солевой ободок (rim) — идеально для маргариты';
    }

    if (lower.any((i) => i.contains('сахар') || i.contains('sugar'))) {
      return 'Сахарный ободок + долька цитруса — сладко-кислый баланс с первого глотка';
    }

    // Дефолт
    return 'Подай в охлаждённом бокале (минут 5 в морозилке) — совсем другой опыт!';
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  📊 РАСЧЁТ ПРОФИЛЯ КОКТЕЙЛЯ
  // ════════════════════════════════════════════════════════════════════════════

  /// Рассчитать профиль коктейля на основе ингредиентов и объёмов
  static CocktailProfileResult calculateProfile(
    List<MapEntry<String, int>> ingredientsWithAmounts,
  ) {
    double totalMl = 0;
    double alcoholMl = 0;
    double sugarGrams = 0;
    final allergens = <String>[];

    for (final entry in ingredientsWithAmounts) {
      final name = entry.key;
      final amountMl = entry.value.toDouble();
      totalMl += amountMl;

      final data = _safetyService.getIngredientData(name);
      if (data != null) {
        // Алкоголь
        if (data.abv > 0) {
          alcoholMl += amountMl * (data.abv / 100);
        }
        // Сахар
        if (data.sugarGramsPer100ml > 0) {
          sugarGrams += (amountMl / 100) * data.sugarGramsPer100ml;
        }
        // Аллергены
        for (final allergen in data.allergens) {
          if (!allergens.contains(allergen)) {
            allergens.add(allergen);
          }
        }
      }
    }

    // ABV
    final abv = totalMl > 0 ? (alcoholMl / totalMl) * 100 : 0;

    // Калории (примерно: алкоголь 7 ккал/г, сахар 4 ккал/г)
    final calories = (alcoholMl * 0.789 * 7 + sugarGrams * 4).round();

    // Категории
    String strengthCategory;
    if (abv <= 10) {
      strengthCategory = 'Лёгкий';
    } else if (abv <= 20) {
      strengthCategory = 'Средний';
    } else {
      strengthCategory = 'Крепкий';
    }

    String sweetnessCategory;
    if (sugarGrams <= 5) {
      sweetnessCategory = 'Сухой';
    } else if (sugarGrams <= 15) {
      sweetnessCategory = 'Полусладкий';
    } else {
      sweetnessCategory = 'Сладкий';
    }

    return CocktailProfileResult(
      abv: double.parse(abv.toStringAsFixed(1)),
      sugarGrams: double.parse(sugarGrams.toStringAsFixed(1)),
      volumeMl: totalMl,
      calories: calories,
      allergens: allergens,
      strengthCategory: strengthCategory,
      sweetnessCategory: sweetnessCategory,
      difficulty: DifficultyLevel.easy, // Будет переопределено
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  📝 ПРОМПТ ДЛЯ AI (ПРОФЕССИОНАЛЬНЫЙ)
  // ════════════════════════════════════════════════════════════════════════════

  static String buildPrompt({
    required List<String> ingredients,
    required int strength,
    required int sweetness,
    required int acidity,
    required int bitterness,
    required bool sparkling,
    required String aroma,
    required String texture,
    String? goal, // 🎯 Убрали из обязательных
    StylePreset? preset, // 🎨 Новый параметр — пресет стиля
    int? balance, // 🎨 Баланс сухой/сладкий
    int? intensity, // 🎨 Интенсивность
    bool hasUsedAdvanced = false, // 📊 Прогрессивное раскрытие
  }) {
    final methodExt = detectMethodExtended(ingredients, sparkling, strength);
    final glass = detectGlass(ingredients, sparkling, methodExt.base, strength);
    final wow = detectWowEffect(ingredients);

    // Валидация безопасности
    final safetyResult = _safetyService.validateIngredients(ingredients);
    final combinationResult = _safetyService.validateCombination(ingredients);
    final allergens = _safetyService.detectAllergens(ingredients);

    // Предупреждения для AI
    final safetyWarnings = <String>[
      ...safetyResult.errors,
      ...safetyResult.warnings,
      if (combinationResult.warning != null) combinationResult.warning!,
    ];

    // Преобразуем слайдеры в конкретные рекомендации
    final strengthGuidance = _getStrengthGuidance(strength, ingredients);
    final sweetnessGuidance = _getSweetnessGuidance(sweetness);
    final acidityGuidance = _getAcidityGuidance(acidity);

    // 🎨 Формируем описание пресета для AI
    final presetDescription = preset != null
        ? '''\n🎨 СТИЛЬ КОКТЕЙЛЯ: ${preset.label}
→ ${preset.description}
→ Базовый профиль: крепость ${preset.baseStrength}/10, сладость ${preset.baseSweetness}/10'''
        : '';

    // 🎨 Формируем описание баланса
    final balanceDescription = balance != null
        ? '\n→ Баланс: ${balance <= 3 ? 'Сухой (кислотный)' : balance <= 7 ? 'Сбалансированный' : 'Сладкий'} ($balance/10)'
        : '';

    // 🎨 Формируем описание интенсивности
    final intensityDescription = intensity != null
        ? '\n→ Интенсивность: ${intensity <= 3 ? 'Лёгкий' : intensity <= 6 ? 'Средний' : intensity <= 8 ? 'Крепкий' : 'Очень крепкий'} ($intensity/10)'
        : '';

    // 📊 Расширенные параметры (только если пользователь открыл расширенные настройки)
    final advancedParams = hasUsedAdvanced
        ? '''
ДОПОЛНИТЕЛЬНО:
• Ароматический профиль: $aroma
• Текстура: $texture
${goal != null ? '• Цель коктейля: $goal' : ''}
• Газация: ${sparkling ? 'ДА' : 'НЕТ'}
• Горечь: $bitterness/10'''
        : '';

    return '''
Ты — шеф-миксолог премиум-бара с 20-летним опытом. Создаёшь коктейли по стандартам IBA.

══════════════════════════════════════════════════════════════
📂 ВХОДНЫЕ ДАННЫЕ
══════════════════════════════════════════════════════════════

ИНГРЕДИЕНТЫ: ${ingredients.join(', ')}$presetDescription$balanceDescription$intensityDescription

ПРОФИЛЬ ВКУСА (пользовательские пожелания):
• Крепость: $strength/10 → $strengthGuidance
• Сладость: $sweetness/10 → $sweetnessGuidance
• Кислотность: $acidity/10 → $acidityGuidance
$advancedParams

══════════════════════════════════════════════════════════════
🔧 РЕКОМЕНДАЦИИ АЛГОРИТМА
══════════════════════════════════════════════════════════════

МЕТОД: ${methodExt.base.name.toUpperCase()}
→ Техника: ${methodExt.technique}
→ Описание: ${methodExt.techniqueDescription}
→ Лёд: ${methodExt.iceType}

БОКАЛ: ${glass.name.toUpperCase()}
→ ${glass.label}

💫 ПРОФЕССИОНАЛЬНАЯ ПОДАЧА: $wow

══════════════════════════════════════════════════════════════
⚠️ БЕЗОПАСНОСТЬ
══════════════════════════════════════════════════════════════

${safetyWarnings.isNotEmpty ? 'ВНИМАНИЕ:\n${safetyWarnings.map((w) => '• $w').join('\n')}' : 'Все ингредиенты безопасны.'}

${allergens.isNotEmpty ? 'АЛЛЕРГЕНЫ: ${allergens.join(', ')}' : ''}

══════════════════════════════════════════════════════════════
📋 ТРЕБОВАНИЯ К РЕЦЕПТУ
══════════════════════════════════════════════════════════════

1. ИСПОЛЬЗУЙ ТОЛЬКО перечисленные ингредиенты (можно не все)
2. ОБЪЁМЫ В МЛ — реалистичные пропорции:
   • Базовый алкоголь: 40-60 мл
   • Ликёр/модификатор: 15-30 мл
   • Сок/миксер: 20-60 мл
   • Сироп: 5-15 мл
   • Биттер: 2-4 дэш (1-2 мл)

3. РАССЧИТАЙ ABV (Alcohol by Volume) исходя из объёмов:
   • Формула: (сумма мл_алкоголь × ABV%) / общий объём × 100
   • Пример: 50мл водки 40% + 100мл сока = (50×0.4)/150 = 13.3% ABV

4. РАССЧИТАЙ САХАР исходя из ингредиентов:
   • Сироп сахарный: ~67г сахара на 100мл
   • Ликёры: 20-35г на 100мл
   • Соки: 5-12г на 100мл

5. БАЛАНС ВКУСОВ — учитывай пожелания пользователя:
   • strength 8-10: больше алкоголя, меньше миксера
   • sweetness 8-10: добавь сироп/ликёр
   • acidity 8-10: больше цитрусового сока

6. НЕВЫПОЛНИМЫЕ ЗАПРОСЫ:
   • Если ингредиенты конфликтуют → НЕ создавай рецепт, верни ошибку
   • Если профиль невозможен → предложи альтернативу

══════════════════════════════════════════════════════════════
📄 ФОРМАТ ОТВЕТА (СТРОГО JSON)
══════════════════════════════════════════════════════════════

{
  "name": "Яркое название с характером",
  "description": "2-3 предложения: эмоция + вкус + повод",
  "ingredients": [
    {"name": "Название", "amountMl": 50}
  ],
  "method": "${methodExt.base.name}",
  "glass": "${glass.name}",
  "steps": [
    "1. Конкретное действие с объёмом",
    "2. Конкретное действие с техникой",
    "3. Подача"
  ],
  "abv": 15.0,
  "sugarGrams": 12.5,
  "calories": 180,
  "allergens": [],
  "wowEffect": "$wow",
  "whyItWorks": "Почему сочетание работает: X = база, Y = баланс, Z = акцент",
  "proTip": "Один профессиональный совет",
  "fact": "Интересный факт о коктейле или ингредиенте",
  "flavorProfile": {
    "strength": $strength,
    "sweetness": $sweetness,
    "acidity": $acidity,
    "bitterness": $bitterness,
    "sparkling": $sparkling
  }
}

Важно: Шаги должны быть КОНКРЕТНЫМИ с объёмами, НЕ «смешай», а «налей 50мл X».
''';
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  🎯 ПРОМПТ ДЛЯ ВАРИАНТОВ КОКТЕЙЛЕЙ (2-3 варианта)
  // ════════════════════════════════════════════════════════════════════════════

  /// Создаёт промпт для генерации 2-3 вариантов коктейлей
  /// Каждый вариант использует 3-5 ингредиентов с правильным балансом
  static String buildVariantsPrompt({
    required List<String> ingredients,
    required int strength,
    required int sweetness,
    required int acidity,
    required int bitterness,
    required bool sparkling,
    required String aroma,
    required String texture,
    String? goal, // 🎯 Убрали из обязательных
    StylePreset? preset,
    int? balance,
    int? intensity,
    bool hasUsedAdvanced = false,
  }) {
    // Валидация безопасности
    final safetyResult = _safetyService.validateIngredients(ingredients);
    final combinationResult = _safetyService.validateCombination(ingredients);
    final allergens = _safetyService.detectAllergens(ingredients);

    // Предупреждения
    final safetyWarnings = <String>[
      ...safetyResult.errors,
      ...safetyResult.warnings,
      if (combinationResult.warning != null) combinationResult.warning!,
    ];

    // Преобразуем слайдеры в рекомендации
    final strengthGuidance = _getStrengthGuidance(strength, ingredients);
    final sweetnessGuidance = _getSweetnessGuidance(sweetness);
    final acidityGuidance = _getAcidityGuidance(acidity);

    return '''
Ты — старший миксолог премиум-бара. Из списка ингредиентов составь РОВНО 2-3 варианта коктейлей.

══════════════════════════════════════════════════════════════
📂 ВХОДНЫЕ ДАННЫЕ
══════════════════════════════════════════════════════════════

ИНГРЕДИЕНТЫ: ${ingredients.join(', ')}

ПРОФИЛЬ ВКУСА:
• Крепость: $strength/10 → $strengthGuidance
• Сладость: $sweetness/10 → $sweetnessGuidance
• Кислотность: $acidity/10 → $acidityGuidance

══════════════════════════════════════════════════════════════
⚠️ БЕЗОПАСНОСТЬ
══════════════════════════════════════════════════════════════

${safetyWarnings.isNotEmpty ? 'ВНИМАНИЕ:\n${safetyWarnings.map((w) => '• $w').join('\n')}' : 'Все ингредиенты безопасны.'}

${allergens.isNotEmpty ? 'АЛЛЕРГЕНЫ: ${allergens.join(', ')}' : ''}

═════════════════════════════════════════════════════════════
📋 ПРАВИЛА ГЕНЕРАЦИИ
═════════════════════════════════════════════════════════════
🎯 РЕЖИМ: ОПТИМАЛЬНЫЕ ПОДМНОЖЕСТВА
1. Каждый рецепт использует 3-5 ингредиентов. НЕ смешивай всё в один.
2. Соблюдай классический баланс: base (1) + sour/sweet (1-2) + mixer/aroma (1-2).
3. Если ингредиент не вошёл — укажи причину: "conflict", "overpowering", "not needed for balance".

🏆 ПРИОРИТЕТ: ИЩИ КЛАССИЧЕСКИЕ КОКТЕЙЛИ!
Проверь, можно ли из выбранных ингредиентов собрать известный классический коктейль:
• Мохито: ром + лайм + мята + сахар + содовая
• Джин-тоник: джин + тоник + лимон/лайм
• Водка-тоник: водка + тоник + лимон
• Маргарита: текила + трипл-сек + лайм
• Олд фэшн: виски + сахар + биттер
• Негрони: джин + кампари + вермут
• Эспрессо мартини: водка + кофейный ликёр + эспрессо
• Москву мул: водка + имбирное пиво + лайм
• Американо: кампари + вермут + содовая
• Уайт леди: джин + трипл-сек + лимон

💡 ОБЯЗАТЕЛЬНЫЕ ПОДСКАЗКИ:
• ЕСЛИ до классического коктейля не хватает 1-2 ингредиентов → ОБЯЗАТЕЛЬНО укажи в "missing_for_classic"
• ЕСЛИ ингредиент конфликтует → ОБЯЗАТЕЛЬНО предложи замену в "suggested_replacements"
• ПРИМЕР: выбрана водка + лимон → "missing_for_classic": "До классической Водка-тоник не хватает только тоника"
• ПРИМЕР: молоко + лимон → "suggested_replacements": ["Замените молоко на кокосовое молоко или сливки 35%+"]

ТИПЫ КОКТЕЙЛЕЙ:
• classic — ПРИОРИТЕТ! Известный коктейль (Mojito, Gin Tonic, Old Fashioned)
• signature — авторский коктейль с уникальным twist
• experimental — необычное сочетание, требующее смелости

══════════════════════════════════════════════════════════════
📄 ФОРМАТ ОТВЕТА (СТРОГО JSON, БЕЗ MARKDOWN)
══════════════════════════════════════════════════════════════

{
  "variants": [
    {
      "name": "Название коктейля 1",
      "type": "classic",
      "description": "Краткое описание (1-2 предложения)",
      "used": ["ингредиент1", "ингредиент2", "ингредиент3"],
      "skipped": ["ингредиент4", "ингредиент5"],
      "reason_skipped": ["конфликтует с профилем", "избыточен для баланса"],
      "match_score": 0.85,
      "missing_for_classic": "До классического Мохито не хватает только мяты",
      "suggested_replacements": ["Можно заменить молоко на кокосовое молоко"],
      "ingredients": [
        {"name": "ингредиент", "amountMl": 50}
      ],
      "method": "shake",
      "glass": "coupe",
      "steps": [
        "1. Конкретное действие",
        "2. Конкретное действие"
      ],
      "garnish": "Украшение",
      "abv": 15.0,
      "sugarGrams": 12.5,
      "calories": 180,
      "allergens": [],
      "wowEffect": "ВАУ-эффект",
      "whyItWorks": "Почему работает",
      "proTip": "Совет профи",
      "fact": "Интересный факт",
      "flavorProfile": {
        "strength": 5,
        "sweetness": 3,
        "acidity": 4,
        "bitterness": 1,
        "sparkling": false
      }
    },
    {
      "name": "Название коктейля 2",
      "type": "classic",
      "description": "...",
      "used": ["..."],
      "skipped": ["..."],
      "reason_skipped": ["..."],
      "match_score": 0.78,
      "missing_for_classic": "До классического Джин-тоник не хватает только тоника",
      "suggested_replacements": [],
      "...остальные поля..."
    },
    {
      "name": "Название коктейля 3",
      "type": "experimental",
      "description": "...",
      "used": ["..."],
      "skipped": ["..."],
      "reason_skipped": ["..."],
      "match_score": 0.65,
      "missing_for_classic": null,
      "suggested_replacements": ["Можно заменить молоко на кокосовое молоко"],
      "...остальные поля..."
    }
  ]
}

⚠️ КРИТИЧЕСКИ ВАЖНО:
• Верни РОВНО 3 варианта (НЕ 2, а 3!)
• ВАРИАНТЫ ДОЛЖНЫ БЫТЬ РАЗНЫМИ: разные ингредиенты, разные стили, разные типы
• Хотя бы 1 вариант должен быть type: "classic" если возможно
• match_score: 0.0-1.0 (насколько хорошо ингредиенты подходят для этого коктейля)
• used: ингредиенты которые вошли в рецепт
• skipped: ингредиенты которые НЕ вошли
• reason_skipped: причина для каждого пропущенного (1 фраза)
• missing_for_classic: ОБЯЗАТЕЛЬНО если до классики не хватает 1-2 ингредиентов
• suggested_replacements: ОБЯЗАТЕЛЬНО если есть конфликт
• Ответ БЕЗ markdown, БЕЗ пояснений — только чистый JSON
''';
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  🎯 ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ
  // ════════════════════════════════════════════════════════════════════════════

  static String _getStrengthGuidance(int strength, List<String> ingredients) {
    final hasSpirit = ingredients.any((i) {
      final lower = i.toLowerCase();
      return lower.contains('водка') ||
          lower.contains('vodka') ||
          lower.contains('джин') ||
          lower.contains('gin') ||
          lower.contains('виски') ||
          lower.contains('whiskey') ||
          lower.contains('ром') ||
          lower.contains('rum') ||
          lower.contains('текила') ||
          lower.contains('tequila');
    });

    if (!hasSpirit) return 'Без крепкого алкоголя — безалкогольный коктейль';

    if (strength <= 3)
      return 'Лёгкий: 30-40мл алкоголя, много миксера (100-150мл)';
    if (strength <= 5)
      return 'Средний: 45-50мл алкоголя, средний миксер (60-80мл)';
    if (strength <= 7)
      return 'Крепкий: 50-60мл алкоголя, минимум миксера (30-50мл)';
    return 'Очень крепкий: 60-80мл алкоголя, акцент на вкус алкоголя';
  }

  static String _getSweetnessGuidance(int sweetness) {
    if (sweetness <= 2) return 'Сухой: без сиропа, можно каплю биттера';
    if (sweetness <= 4) return 'Полусухой: 5-10мл сиропа или сладкого ликёра';
    if (sweetness <= 6) return 'Сбалансированный: 10-15мл сиропа или ликёра';
    if (sweetness <= 8) return 'Сладкий: 15-25мл сиропа + сладкий ликёр';
    return 'Десертный: 25-40мл сладких ингредиентов, возможно мороженое';
  }

  static String _getAcidityGuidance(int acidity) {
    if (acidity <= 2) return 'Минимальная кислотность: без цитрусовых';
    if (acidity <= 4)
      return 'Лёгкая кислинка: 10-15мл лимонного/лаймового сока';
    if (acidity <= 6) return 'Сбалансированная: 20-30мл цитрусового сока';
    if (acidity <= 8) return 'Яркая кислотность: 30-45мл сока (лимон/лайм)';
    return 'Доминирующая кислота: 50-60мл цитрусового, кислый профиль';
  }
}
