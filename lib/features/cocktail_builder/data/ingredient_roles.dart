/// Роли ингредиентов в коктейле.
///
/// Каждая роль определяет функцию ингредиента в балансе коктейля:
/// - base: основной алкоголь (ядро характера)
/// - sour: кислотность (лимон, лайм)
/// - sweet: сладость (сиропы, мед)
/// - mixer: разбавитель (тоник, содовая)
/// - aroma: ароматика (мята, травы)
/// - bitter: горечь (биттеры, кампари)
/// - garnish: украшение
class IngredientRoles {
  IngredientRoles._();

  /// Маппинг ингредиентов на их роли
  static const Map<String, String> roleMap = {
    // ════════════════════════════════════════════════════════════════════════════
    //  🥃 BASE SPIRITS — Основа коктейля (40-60 мл)
    // ════════════════════════════════════════════════════════════════════════════
    'водка': 'base',
    'vodka': 'base',
    'джин': 'base',
    'gin': 'base',
    'виски': 'base',
    'whiskey': 'base',
    'whisky': 'base',
    'скотч': 'base',
    'scotch': 'base',
    'бурбон': 'base',
    'bourbon': 'base',
    'ром': 'base',
    'rum': 'base',
    'текила': 'base',
    'tequila': 'base',
    'коньяк': 'base',
    'cognac': 'base',
    'бренди': 'base',
    'brandy': 'base',
    'кальвадос': 'base',
    'calvados': 'base',
    'аквавит': 'base',
    'aquavit': 'base',
    'граппа': 'base',
    'grappa': 'base',
    'персиковый бренди': 'base',
    'peach brandy': 'base',
    'кашаса': 'base',
    'cachaça': 'base',
    'пайс': 'base',
    'pisco': 'base',
    'саке': 'base',
    'sake': 'base',
    'соджу': 'base',
    'soju': 'base',
    'бейлис': 'base',
    'baileys': 'base',

    // ════════════════════════════════════════════════════════════════════════════
    //  🍋 SOUR — Кислотность (15-30 мл)
    // ════════════════════════════════════════════════════════════════════════════
    'лимон': 'sour',
    'lemon': 'sour',
    'лимонный сок': 'sour',
    'lemon juice': 'sour',
    'лайм': 'sour',
    'lime': 'sour',
    'лаймовый сок': 'sour',
    'lime juice': 'sour',
    'апельсин': 'sour',
    'orange': 'sour',
    'апельсиновый сок': 'sour',
    'orange juice': 'sour',
    'грейпфрут': 'sour',
    'grapefruit': 'sour',
    'грейпфрутовый сок': 'sour',
    'grapefruit juice': 'sour',
    'клюквенный сок': 'sour',
    'cranberry juice': 'sour',
    'ананасовый сок': 'sour',
    'pineapple juice': 'sour',
    'яблочный сок': 'sour',
    'apple juice': 'sour',
    'виноградный сок': 'sour',
    'grape juice': 'sour',
    'томатный сок': 'sour',
    'tomato juice': 'sour',

    // ════════════════════════════════════════════════════════════════════════════
    //  🍯 SWEET — Сладость (10-20 мл)
    // ════════════════════════════════════════════════════════════════════════════
    'сахарный сироп': 'sweet',
    'simple syrup': 'sweet',
    'sugar syrup': 'sweet',
    'сироп': 'sweet',
    'syrup': 'sweet',
    'кленовый сироп': 'sweet',
    'maple syrup': 'sweet',
    'агавовый сироп': 'sweet',
    'agave syrup': 'sweet',
    'мед': 'sweet',
    'honey': 'sweet',
    'медовый сироп': 'sweet',
    'honey syrup': 'sweet',
    'сахар': 'sweet',
    'sugar': 'sweet',
    'коричневый сахар': 'sweet',
    'brown sugar': 'sweet',
    'тростниковый сахар': 'sweet',
    'cane sugar': 'sweet',
    'клубничный сироп': 'sweet',
    'strawberry syrup': 'sweet',
    'малиновый сироп': 'sweet',
    'raspberry syrup': 'sweet',
    'персиковый сироп': 'sweet',
    'peach syrup': 'sweet',
    'мятный сироп': 'sweet',
    'mint syrup': 'sweet',
    'гренадин': 'sweet',
    'grenadine': 'sweet',
    'карамельный сироп': 'sweet',
    'caramel syrup': 'sweet',
    'ванильный сироп': 'sweet',
    'vanilla syrup': 'sweet',
    'шоколадный сироп': 'sweet',
    'chocolate syrup': 'sweet',
    'калуа': 'sweet',
    'kahlúa': 'sweet',
    'трипл-сек': 'sweet',
    'triple sec': 'sweet',
    'куантро': 'sweet',
    'cointreau': 'sweet',
    'гран-марни': 'sweet',
    'grand marnier': 'sweet',

    // ════════════════════════════════════════════════════════════════════════════
    //  🥤 MIXER — Разбавители (30-120 мл)
    // ════════════════════════════════════════════════════════════════════════════
    'тоник': 'mixer',
    'tonic': 'mixer',
    'тоник water': 'mixer',
    'tonic water': 'mixer',
    'содовая': 'mixer',
    'soda': 'mixer',
    'club soda': 'mixer',
    'газированная вода': 'mixer',
    'sparkling water': 'mixer',
    'колу': 'mixer',
    'кола': 'mixer',
    'coke': 'mixer',
    'cola': 'mixer',
    'спрайт': 'mixer',
    'sprite': 'mixer',
    'гинджер эль': 'mixer',
    'ginger ale': 'mixer',
    'имбирный эль': 'mixer',
    'имбирное пиво': 'mixer',
    'ginger beer': 'mixer',
    'энергетик': 'mixer',
    'energy drink': 'mixer',
    'red bull': 'mixer',
    'монстер': 'mixer',
    'monster': 'mixer',
    'кокосовое молоко': 'mixer',
    'coconut milk': 'mixer',
    'кокосовые сливки': 'mixer',
    'coconut cream': 'mixer',
    'сливки': 'mixer',
    'cream': 'mixer',
    'молоко': 'mixer',
    'milk': 'mixer',

    // ════════════════════════════════════════════════════════════════════════════
    //  🌿 AROMA/GARNISH — Ароматика и украшения
    // ════════════════════════════════════════════════════════════════════════════
    'мята': 'aroma',
    'mint': 'aroma',
    'базилик': 'aroma',
    'basil': 'aroma',
    'розмарин': 'aroma',
    'rosemary': 'aroma',
    'тимьян': 'aroma',
    'thyme': 'aroma',
    'киндза': 'aroma',
    'cilantro': 'aroma',
    'корица': 'aroma',
    'cinnamon': 'aroma',
    'ваниль': 'aroma',
    'vanilla': 'aroma',
    'мускатный орех': 'aroma',
    'nutmeg': 'aroma',
    'огурец': 'aroma',
    'cucumber': 'aroma',
    'имбирь': 'aroma',
    'ginger': 'aroma',
    'чили': 'aroma',
    'chili': 'aroma',
    'перец': 'aroma',
    'pepper': 'aroma',
    'соль': 'aroma',
    'salt': 'aroma',
    'сельдерейная соль': 'aroma',
    'celery salt': 'aroma',
    'цедра': 'garnish',
    'zest': 'garnish',
    'апельсиновая цедра': 'garnish',
    'orange zest': 'garnish',
    'лимонная цедра': 'garnish',
    'lemon zest': 'garnish',
    'лаймовая цедра': 'garnish',
    'lime zest': 'garnish',
    'оливка': 'garnish',
    'olive': 'garnish',
    'коктейльная вишня': 'garnish',
    'cocktail cherry': 'garnish',
    'maraschino cherry': 'garnish',
    'ягода': 'garnish',
    'berry': 'garnish',
    'клубника': 'garnish',
    'strawberry': 'garnish',
    'малина': 'garnish',
    'raspberry': 'garnish',
    'черника': 'garnish',
    'blueberry': 'garnish',
    'ананас': 'garnish',
    'pineapple': 'garnish',

    // ════════════════════════════════════════════════════════════════════════════
    //  😠 BITTER — Горечь (2-10 мл / 2-3 дэша)
    // ════════════════════════════════════════════════════════════════════════════
    'ангостура': 'bitter',
    'angostura': 'bitter',
    'ангостура биттерс': 'bitter',
    'angostura bitters': 'bitter',
    'пешо биттер': 'bitter',
    'peychaud\'s bitters': 'bitter',
    'оранж биттер': 'bitter',
    'orange bitters': 'bitter',
    'кампари': 'bitter',
    'campari': 'bitter',
    'апероль': 'bitter',
    'aperol': 'bitter',
    'чино': 'bitter',
    'cina': 'bitter',
    'сухарный биттер': 'bitter',
    'бенедиктин': 'bitter',
    'bénédictine': 'bitter',
    'шартрез': 'bitter',
    'chartreuse': 'bitter',
    'ферне-бранка': 'bitter',
    'fernet-branca': 'bitter',
    'амаро': 'bitter',
    'amaro': 'bitter',
    'вермут': 'bitter',
    'vermouth': 'bitter',
    'красный вермут': 'bitter',
    'sweet vermouth': 'bitter',
    'сухой вермут': 'bitter',
    'dry vermouth': 'bitter',

    // ════════════════════════════════════════════════════════════════════════════
    //  🍷 WINE & FORTIFIED — Вина и креплёные
    // ════════════════════════════════════════════════════════════════════════════
    'шампанское': 'mixer',
    'champagne': 'mixer',
    'игристое': 'mixer',
    'sparkling wine': 'mixer',
    'просекко': 'mixer',
    'prosecco': 'mixer',
    'кава': 'mixer',
    'cava': 'mixer',
    'белое вино': 'mixer',
    'white wine': 'mixer',
    'красное вино': 'mixer',
    'red wine': 'mixer',
    'розе': 'mixer',
    'rosé': 'mixer',
    'портвейн': 'bitter',
    'port': 'bitter',
    'херес': 'bitter',
    'sherry': 'bitter',
    'марсала': 'bitter',
    'marsala': 'bitter',

    // ════════════════════════════════════════════════════════════════════════════
    //  🥚 EGGS — Яйца (для текстуры)
    // ════════════════════════════════════════════════════════════════════════════
    'яйцо': 'texture',
    'egg': 'texture',
    'яичный белок': 'texture',
    'egg white': 'texture',
    'аквафаба': 'texture',
    'aquafaba': 'texture',
  };

  /// Отдельный маппинг для спортивных ингредиентов
  /// (некоторые пересекаются с классическими, но здесь приоритет для спорта)
  static const Map<String, String> sportRoleMap = {
    // Белковые источники
    'творог': 'protein',
    'cottage cheese': 'protein',
    'cottage': 'protein',
    'йогурт': 'protein',
    'yogurt': 'protein',
    'греческий йогурт': 'protein',
    'кефир': 'protein',
    'kefir': 'protein',
    'протеин': 'protein',
    'whey protein': 'protein',
    'whey': 'protein',
    'казеин': 'protein',
    'casein': 'protein',
    'гейнер': 'protein',
    'gainer': 'protein',
    'BCAA': 'protein',
    
    // Фрукты
    'банан': 'fruit',
    'banana': 'fruit',
    'клубника': 'fruit',
    'strawberry': 'fruit',
    'малина': 'fruit',
    'raspberry': 'fruit',
    'черника': 'fruit',
    'blueberry': 'fruit',
    'яблоко': 'fruit',
    'apple': 'fruit',
    'ягоды': 'fruit',
    'mixed berries': 'fruit',
    'замороженные ягоды': 'fruit',
    'frozen berries': 'fruit',
    
    // Углеводы
    'овсянка': 'carb',
    'oats': 'carb',
    'хлопья': 'carb',
    'cereal': 'carb',
    'батат': 'carb',
    'sweet potato': 'carb',
    'рис': 'carb',
    'rice': 'carb',
    'мёд': 'carb',
    'honey': 'carb',
    
    // Жиросжигатели
    'зелёный чай': 'fatburner',
    'green tea': 'fatburner',
    'лимон': 'fatburner',
    'lemon': 'fatburner',
    'лайм': 'fatburner',
    'lime': 'fatburner',
    'чили': 'fatburner',
    'chili': 'fatburner',
    'острый перец': 'fatburner',
    'hot pepper': 'fatburner',
    
    // Добавки для вкуса/текстуры
    'арахисовая паста': 'additive',
    'peanut butter': 'additive',
    'миндальная паста': 'additive',
    'almond butter': 'additive',
    'семена чиа': 'additive',
    'chia seeds': 'additive',
    'лён': 'additive',
    'flax': 'additive',
    
    // Жиры
    'авокадо': 'fat',
    'avocado': 'fat',
    'кокосовое масло': 'fat',
    'coconut oil': 'fat',
    'оливковое масло': 'fat',
    'olive oil': 'fat',
  };

  /// Получить роль для спортивного ингредиента
  static String getSportRole(String ingredientName) {
    final normalizedName = ingredientName.toLowerCase().trim();
    return sportRoleMap[normalizedName] ?? 'other';
  }

  /// Проверить, является ли спортивный ингредиент белком
  static bool isProtein(String ingredientName) {
    return getSportRole(ingredientName) == 'protein';
  }

  /// Проверить, является ли спортивный ингредиент фруктом
  static bool isFruit(String ingredientName) {
    return getSportRole(ingredientName) == 'fruit';
  }

  /// Получить роль ингредиента по названию
  static String getRole(String ingredientName) {
    final normalizedName = ingredientName.toLowerCase().trim();
    return roleMap[normalizedName] ?? 'other';
  }

  /// Проверить, является ли ингредиент базовым алкоголем
  static bool isBase(String ingredientName) {
    return getRole(ingredientName) == 'base';
  }

  /// Проверить, является ли ингредиент кислым
  static bool isSour(String ingredientName) {
    return getRole(ingredientName) == 'sour';
  }

  /// Проверить, является ли ингредиент сладким
  static bool isSweet(String ingredientName) {
    return getRole(ingredientName) == 'sweet';
  }

  /// Проверить, является ли ингредиент миксером
  static bool isMixer(String ingredientName) {
    return getRole(ingredientName) == 'mixer';
  }

  /// Проверить, является ли ингредиент ароматическим
  static bool isAroma(String ingredientName) {
    return getRole(ingredientName) == 'aroma';
  }

  /// Проверить, является ли ингредиент горьким
  static bool isBitter(String ingredientName) {
    return getRole(ingredientName) == 'bitter';
  }

  /// Получить все ингредиенты определённой роли
  static List<String> getByRole(String role) {
    return roleMap.entries
        .where((entry) => entry.value == role)
        .map((entry) => entry.key)
        .toList();
  }

  /// Получить статистику по ролям для списка ингредиентов
  static Map<String, List<String>> categorizeIngredients(List<String> ingredients) {
    final result = <String, List<String>>{
      'base': [],
      'sour': [],
      'sweet': [],
      'mixer': [],
      'aroma': [],
      'bitter': [],
      'garnish': [],
      'texture': [],
      'other': [],
    };

    for (final ingredient in ingredients) {
      final role = getRole(ingredient);
      result[role]?.add(ingredient);
    }

    return result;
  }

  /// Проверить баланс ингредиентов
  static bool hasGoodBalance(List<String> ingredients) {
    final categorized = categorizeIngredients(ingredients);

    // Минимум 1 базовый алкоголь
    if (categorized['base']!.isEmpty) return false;

    // Хотя бы 1 кислый или сладкий
    if (categorized['sour']!.isEmpty && categorized['sweet']!.isEmpty) {
      return false;
    }

    return true;
  }

  /// Получить рекомендации по балансу
  static List<String> getBalanceRecommendations(List<String> ingredients) {
    final categorized = categorizeIngredients(ingredients);
    final recommendations = <String>[];

    if (categorized['base']!.isEmpty) {
      recommendations.add('Добавьте базовый алкоголь (водка, джин, виски)');
    }

    if (categorized['base']!.length > 2) {
      recommendations.add('Слишком много базовых алкоголей — выберите один');
    }

    if (categorized['sour']!.isEmpty && categorized['sweet']!.isEmpty) {
      recommendations.add('Добавьте баланс: кислый (лимон) или сладкий (сироп)');
    }

    if (categorized['sour']!.isNotEmpty && categorized['sweet']!.isEmpty) {
      recommendations.add('Добавьте сладость для баланса кислотности');
    }

    if (categorized['sweet']!.isNotEmpty && categorized['sour']!.isEmpty) {
      recommendations.add('Добавьте кислотность для баланса сладости');
    }

    if (categorized['bitter']!.length > 2) {
      recommendations.add('Слишком много горьких ингредиентов');
    }

    return recommendations;
  }
}
