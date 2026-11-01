import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:coin/core/models/cocktail.dart';
import 'package:coin/features/ai_recipes/models/detailed_recipe.dart';
import 'package:coin/core/services/measurement_service.dart';

/// Service for AI-powered cocktail recipe expansion.
///
/// Generates detailed step-by-step instructions with:
/// - Starter mode: beginner-friendly with timers and tips
/// - Expert mode: professional techniques, history, economics
class RecipeAIService {
  static const _baseUrl = 'https://api.openai.com/v1/chat/completions';
  final String _apiKey = '';

  /// Сгенерировать подробный рецепт с пошаговыми инструкциями.
  ///
  /// [cocktail] - коктейль из API
  /// [mode] - режим (starter/expert)
  /// [locale] - язык ('ru', 'ro', 'en')
  /// [measurementService] - сервис единиц измерения (ml/oz)
  Future<DetailedRecipe> expand({
    required Cocktail cocktail,
    required RecipeMode mode,
    required String locale,
    MeasurementService? measurementService,
  }) async {
    final prompt = _buildPrompt(cocktail, mode, locale, measurementService);

    // API is disabled in the first offline-first release unless a key is injected later.
    try {
      if (_apiKey.isEmpty) {
        throw StateError('AI recipe API key is not configured');
      }
      print('🤖 Calling OpenAI API...');
      final response = await _callOpenAI(prompt);
      print('✅ OpenAI response received!');
      return _parseResponse(response, cocktail, mode);
    } catch (e) {
      print('❌ OpenAI API failed: $e');
      // Fallback to sample recipe if API fails
      return _getSampleRecipe(cocktail, mode);
    }
  }

  /// Sample recipes for demo/testing (no API needed)
  DetailedRecipe _getSampleRecipe(Cocktail cocktail, RecipeMode mode) {
    print('⚠️ Using SAMPLE recipe (AI not available)');
    if (mode == RecipeMode.starter) {
      return DetailedRecipe(
        mode: 'starter',
        baseCocktail: cocktail,
        prepTimeSeconds: 30,
        totalTimeSeconds: 90,
        toolsNeeded: ['Shaker', 'Strainer', 'Jigger', 'Bar spoon'],
        steps: [
          RecipeStep(
            stepNumber: 1,
            title: 'Подготовьте рабочее место',
            description:
                'Очистите стол и подготовьте все инструменты. Убедитесь, что у вас есть лёд.',
            durationSeconds: 10,
            tip: 'Прочитайте весь рецепт перед началом',
          ),
          RecipeStep(
            stepNumber: 2,
            title: 'Отмерьте ингредиенты',
            description:
                'Используйте джиггер для точного измерения каждого ингредиента.',
            durationSeconds: 15,
            tip: 'Точность - ключ к успеху!',
          ),
          RecipeStep(
            stepNumber: 3,
            title: 'Добавьте в шейкер',
            description: 'Налейте все ингредиенты в шейкер.',
            durationSeconds: 10,
          ),
          RecipeStep(
            stepNumber: 4,
            title: 'Встряхните',
            description:
                'Заполните шейкер льдом, закройте плотно и энергично встряхивайте 15 секунд.',
            durationSeconds: 20,
            tip: 'Встряхивайте от плеча, а не только запястьем',
          ),
          RecipeStep(
            stepNumber: 5,
            title: 'Процедите и подавайте',
            description: 'Процедите в бокал и украсьте.',
            durationSeconds: 15,
            tip: 'Используйте мелкое сито для гладких коктейлей',
          ),
        ],
        commonMistakes: [
          'Слишком много льда',
          'Недостаточно долго трясти',
          'Забывают охладить бокал',
        ],
        proTips: [
          'Всегда используйте свежий сок',
          'Охлаждайте бокал заранее',
          'Качественный лёд имеет значение',
        ],
      );
    } else {
      // Expert mode sample
      return DetailedRecipe(
        mode: 'expert',
        baseCocktail: cocktail,
        prepTimeSeconds: 120,
        totalTimeSeconds: 180,
        difficulty: 'intermediate',
        history:
            'Классический ${cocktail.strDrink} - проверенный временем рецепт, созданный десятилетия назад.',
        techniques: ['Dry shake', 'Double strain', 'Oleo saccharum'],
        premiumIngredients: [
          PremiumIngredient(
            name: 'Базовый спирт',
            recommendation: 'Используйте премиальное качество',
            reason: 'Спирты высшего качества имеют более гладкий вкус',
          ),
        ],
        proSecrets: [
          'Добавьте 2 даша биттера для сложности',
          'Выдавите цедру над напитком для аромата',
          'Используйте мутный лёд для медленного разбавления',
        ],
        variations: [
          '${cocktail.strDrink} Royale: Добавьте шампанское вместо содовой',
          'Замороженный ${cocktail.strDrink}: Взбейте в блендере со льдом',
          '${cocktail.strDrink} Sour: Добавьте яичный белок для текстуры',
        ],
        foodPairing: ['Закуски', 'Морепродукты', 'Лёгкие десерты'],
        estimatedCostMdl: 18,
        suggestedPriceMdl: 45,
      );
    }
  }

  String _buildPrompt(Cocktail cocktail, RecipeMode mode, String locale,
      MeasurementService? measurementService) {
    // Language mapping
    final langMap = {
      'ru': 'Russian',
      'ro': 'Romanian',
      'en': 'English',
    };
    final langName = langMap[locale] ?? 'English';

    print('🌍 Requesting response in: $langName (locale: $locale)');

    // Determine measurement units
    final volumeUnit = measurementService?.volumeSymbol ?? 'ml';
    final useOz = volumeUnit == 'oz';

    final ingredients = cocktail.ingredients
        .asMap()
        .entries
        .map((e) =>
            '- ${cocktail.measures[e.key].isNotEmpty ? '${cocktail.measures[e.key]} ' : ''}${e.value}')
        .join('\n');

    if (mode == RecipeMode.starter) {
      return '''
You are a professional bartender giving PRACTICAL cocktail instructions.

ABSOLUTE RULES:
1. LANGUAGE: ALL text values MUST be in PROFESSIONAL $langName. JSON keys stay in English. No English words in values.
2. FORMAT: RAW JSON ONLY. No markdown. No triple backticks. Escape inner quotes with backslash.
3. CONTENT: Only physical actions, no theory or preparation advice.
4. MEASUREMENT UNITS: Use $volumeUnit for all measurements${useOz ? ' (imperial system)' : ' (metric system)'}.

Cocktail: ${cocktail.strDrink}
Category: ${cocktail.strCategory}
Glass: ${cocktail.strGlass}
Type: ${cocktail.strAlcoholic}

Ingredients:
$ingredients

Instructions (basic): ${cocktail.strInstructions}

Create SHORT, PRACTICAL cooking steps ONLY.

STRICT Requirements:
- ONLY physical actions: "Pour 50${useOz ? 'ml' : 'ml'} vodka", "Add ice", "Shake 15 seconds"
- NEVER write: "prepare workspace", "clean table", "gather tools", "measure ingredients"  
- Each step MUST include SPECIFIC amounts from ingredients list
- Convert all measurements to $volumeUnit${useOz ? ' (1 oz = 30ml)' : ''}
- Use imperative verbs: "Pour", "Add", "Shake", "Strain", "Garnish"
- Maximum 5-7 steps total
- Keep it like a recipe card - just what to DO
- Add helpful TIP for each step (professional trick, timing cue, or warning)

REQUIRED JSON STRUCTURE:
{
  "mode": "starter",
  "prep_time_seconds": 30,
  "total_time_seconds": 90,
  "tools_needed": [],
  "steps": [
    {
      "step_number": 1,
      "title": "Налей водку",
      "description": "50${volumeUnit} водки в шейкер",
      "duration_seconds": 5,
      "tip": "Используй джиггер для точности"
    }
  ],
  "common_mistakes": [],
  "pro_tips": []
}

REMINDER: This is a PREMIUM feature. Every field must have real, specific content in $langName language. Use $volumeUnit for ALL measurements.

Return ONLY valid JSON. Start with { and end with }.
''';
    } else {
      // Expert mode — professional recipe
      return '''
You are a MASTER MIXOLOGIST with 20+ years experience in world-class cocktail bars. You're writing a professional recipe guide that reveals SECRETS bartenders learn only through years of practice.

COCKTAIL: ${cocktail.strDrink}
Category: ${cocktail.strCategory}
Glass: ${cocktail.strGlass}

BASE RECIPE FROM API:
${cocktail.strInstructions}

INGREDIENTS:
$ingredients

YOUR TASK: Write a MASTERCLASS recipe guide with PROFESSIONAL SECRETS that you won't find in any book. Include the small details that separate GREAT bartenders from average ones.

WHAT MAKES THIS SPECIAL:
- HOW a pro actually makes this (not the textbook version)
- TIMING and RHYTHM of movements
- VISUAL and SOUND cues ("when it sounds like...", "when you see...")
- TOUCH cues ("when the glass feels...")
- Common mistakes that NOBODY talks about
- Pro tricks learned only through experience

STRICT RULES:
1. LANGUAGE: Professional Russian (bartender terminology). JSON keys in English.
2. NO GENERIC CONTENT: Every field must be SPECIFIC to THIS cocktail. If you write something that applies to ANY cocktail — rewrite it.
3. REAL FACTS ONLY: For history — use verified dates, places, people. If unknown, write "Точная история не документирована".
4. PRACTICAL FOCUS: Write what a bartender NEEDS to know, not what sounds impressive.
5. FORMAT: RAW JSON ONLY. No markdown, no backticks.
6. CURRENCY: MDL (Moldovan lei). Real prices for Moldova market 2024.
7. INCLUDE SENSORY DETAILS: What you SEE, HEAR, FEEL, SMELL at each step.

REQUIRED JSON STRUCTURE:
{
  "mode": "expert",
  "history": "2-3 sentences MAX. Specific facts: who created it, when, where, why. Example: 'Создан в 1943 году Фернандо Кастильо в отеле Reforma, Мехико, для американских солдат.' NOT 'Этот коктейль имеет богатую историю.'",
  "prep_time_seconds": 60,
  "total_time_seconds": 120,
  "difficulty": "beginner|intermediate|advanced",
  "sensory_profile": {
    "aroma": "1 sentence. What you smell BEFORE tasting. Specific notes: 'Доминирует можжевельник с нотами цитрусовой цедры и свежей мяты.'",
    "taste": "1 sentence. Flavor balance: 'Кислота лимона преобладает, смягчается сладостью сиропа, финиш — горечь биттера.'",
    "texture": "1 sentence. Mouthfeel: 'Плотное тело, шелковистая текстура от яичного белка, легкая газация.'",
    "finish": "1 sentence. Aftertaste duration and character: 'Длинное (15+ сек), теплое от имбиря, с горьковатым послевкусием.'"
  },
  "techniques": ["2-4 SPECIFIC techniques with PRO DETAILS: 'Dry shake БЕЗ льда 15 сек (создает эмульсию), затем со льдом 10 сек (охлаждает). Угол наклона шейкера 45° для аэрации'."],
  "premium_ingredients": [
    {
      "name": "Which ingredient to upgrade",
      "recommendation": "Specific brand names available in Moldova/Romania: 'Hendrick's, Plantation 3 Stars, Fentimans'",
      "reason": "TECHNICAL reason how it changes THIS cocktail: 'Ботанические ноты усиливают травянистость, меньшая горечь дает чистый финиш'"
    }
  ],
  "service_presentation": [
    "GLASS PREP: EXACT temperature and timing: 'Охлаждать highball 10 мин в морозилке при -18°C. Проверить по конденсату — должен появиться за 3 сек после выдоха.'",
    "ICE SELECTION: EXACT type, size, preparation: 'Куб 5x5см из фильтрованной кипяченой воды. Прозрачный = медленное таяние (1мл/мин). Мутный = быстрый.'",
    "GARNISH TECHNIQUE: EXACT how-to: 'Цедра 2x4см, держать КОЖУРОЙ вниз на расстоянии 2см от поверхности. Сжать — масла распылятся. Протереть rim СНАРУЖИ.'",
    "SERVING RITUAL: How to present, what to say, when: 'Подавать в первые 30 сек — лед еще не начал таять. Поставить ПЕРЕД гостем, не протягивать. Say: 'Ваш Mojito, свежеприготовленный'.'",
    "FIRST SIP GUIDE: What guest notices in order: '1. Аромат мяты (0-3 сек). 2. Кислота лайма (3-8 сек). 3. Сладость сахара (8-15 сек). 4. Finish мяты и лайма (15+ сек).'"
  ],
  "steps": [
    {
      "step_number": 1,
      "title": "Короткий глагол: 'Подготовить бокал', 'Налить джин', 'Встряхнуть'",
      "description": "EXACT action with MEASUREMENTS and SENSORY cues: 'Налить 50мл Beefeater в шейкер. Добавить 25мл Campari, 25мл Carpano Antica. Лед ДОБАВИТЬ ПОСЛЕДНИМ — он должен быть на 2см выше жидкости.' NOT 'Добавить ингредиенты'.",
      "duration_seconds": 10,
      "tip": "PRO SECRET or WARNING: 'Держать бутылку на 45° — контролируешь поток. На 90° — льется слишком быстро. Слышишь правильный звук когда лед правильно лежит.' NOT 'Будьте аккуратны'."
    }
  ],
  "pro_secrets": [
    "3-5 SECRETS that pros know but don't tell. Examples:
    - 'Добавить 2 даша солевого раствора (10%) — усилит сладость без сахара, откроет ботанику джина. Секрет японских барменов.'
    - 'Shake с ЗАКРЫТЫМИ глазами — слышишь когда лед правильно бился. Звонкий звук = готово. Глухой = перешейк.'
    - 'Glass температура -5°C идеальна. Проверь: приложи к губе — должен чувствовать холод но не мороз.'
    - 'Citrus oils распылять НАД льдом, не в воздух. Масла осядут на поверхность — первый глоток с ароматом.'"
  ],
  "variations": ["2-3 REAL variations with EXACT changes: 'Boulevardier: заменить джин на Bourbon 50мл, остальное без изменений.'"],
  "food_pairing": ["2-3 SPECIFIC dishes with WHY: 'Выдержанный пармезан — соль усиливает сладость вермута, кристаллы тирозина создают контраст с горечью Campari.'"]
}

CRITICAL — WHAT TO INCLUDE:

1. TIMING & RHYTHM:
   - How LONG each step REALLY takes
   - When to move FAST vs SLOW
   - The rhythm of professional bartending

2. SENSORY CUES:
   - What you HEAR (ice cracking, shaking sounds)
   - What you SEE (color changes, condensation)
   - What you FEEL (glass temperature, weight)
   - What you SMELL (when to stop expressing citrus)

3. PRO MOVEMENTS:
   - How to hold bottles for control
   - Angle of pour (45° vs 90°)
   - How to shake properly (from shoulder, not wrist)
   - When to use fine strain vs regular

4. MISTAKES NOBODY TELLS:
   - Over-shaking (dilutes too much)
   - Wrong ice temperature
   - Garnish mistakes (expressing too far)
   - Serving too late (ice melted)

5. HIDDEN TRICKS:
   - Salt solution trick
   - Glass temperature check
   - Ice quality test
   - Citrus oil technique

This is a PREMIUM MASTERCLASS for bartenders who want to be EXCEPTIONAL. Every secret, every detail, everything you learned through years of practice.

Return ONLY valid JSON. Start with { and end with }.
''';
    }
  }

  Future<Map<String, dynamic>> _callOpenAI(String prompt) async {
    print('📤 Sending request to OpenAI...');
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': [
          {
            'role': 'system',
            'content': 'You are a professional bartender and mixologist.'
          },
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.7,
        'max_tokens': 1500,
        'response_format': {'type': 'json_object'},
      }),
    );

    print('📥 Response status: ${response.statusCode}');

    if (response.statusCode != 200) {
      throw Exception(
          'OpenAI API error: ${response.statusCode} - ${response.body}');
    }

    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final content = data['choices'][0]['message']['content'] as String;
      print('📝 AI content length: ${content.length}');

      final recipeData = jsonDecode(content) as Map<String, dynamic>;
      print('✅ Parsed JSON successfully');
      return recipeData;
    } catch (e) {
      print('❌ JSON parse error: $e');
      print('📄 Response body: ${response.body.substring(0, 200)}...');
      rethrow;
    }
  }

  DetailedRecipe _parseResponse(
    Map<String, dynamic> response,
    Cocktail cocktail,
    RecipeMode mode,
  ) {
    return DetailedRecipe.fromJson(response)..baseCocktail = cocktail;
  }
}
