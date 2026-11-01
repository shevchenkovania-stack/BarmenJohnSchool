import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:coin/features/cocktail_builder/models/generated_cocktail.dart';
import 'package:coin/features/cocktail_builder/models/flavor_profile.dart';
import 'package:coin/features/cocktail_builder/models/cocktail_types.dart';

/// Сервис улучшения коктейлей с помощью AI (OpenAI)
///
/// **Зачем нужен:**
/// - Добавляет pro tips, facts, secrets к рецептам из базы
/// - Рассчитывает реальный flavor profile на основе ингредиентов
/// - Делает конструктор более полезным и профессиональным
///
/// **Как работает:**
/// 1. Берет GeneratedCocktail от matcher (базовый рецепт)
/// 2. Отправляет в OpenAI для улучшения
/// 3. Возвращает enriched cocktail с дополнительными полями
///
/// **Offline fallback:**
/// - Если нет интернета → возвращает базовый рецепт без ошибки
/// - Если нет API ключа → возвращает базовый рецепт
/// - Если AI упал → возвращает базовый рецепт
///
/// **Архитектура:**
/// - AiEnhancerService отвечает ТОЛЬКО за AI улучшение
/// - Не ищет рецепты (это CocktailMatcherService)
/// - Не сохраняет (это FavoritesService)
///
/// **Пример использования:**
/// ```dart
/// final enhancer = AiEnhancerService('your-api-key');
///
/// final baseCocktail = matcher.generateSingle(ingredients);
/// final enhanced = await enhancer.enhance(baseCocktail);
///
/// // enhanced имеет:
/// // - proTip: "Используйте свежий лайм..."
/// // - fact: "Mojito появился в 1950-х..."
/// // - secret: "Охладите бокал заранее..."
/// // - flavorProfile: реальные значения
/// ```
///
/// **Стоимость:**
/// - ~500 токенов на коктейль
/// - ~$0.001 за улучшение (очень дешево)
/// - ~2-3 секунды время ответа
class AiEnhancerService {
  /// API ключ OpenAI
  final String apiKey;

  /// OpenAI API endpoint
  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';

  /// Модель для использования (gpt-3.5-turbo - оптимально по цене/качеству)
  static const String _model = 'gpt-3.5-turbo';

  AiEnhancerService(this.apiKey);

  /// Улучшить коктейль с помощью AI
  ///
  /// **Параметры:**
  /// - `base`: базовый коктейль от matcher
  ///
  /// **Возвращает:**
  /// - Улучшенный cocktail с pro tips, facts, secrets
  /// - ИЛИ базовый cocktail если AI недоступен (без ошибки!)
  ///
  /// **Graceful degradation:**
  /// - Нет интернета → base
  /// - Нет ключа → base
  /// - API error → base
  /// - Timeout → base
  Future<GeneratedCocktail> enhance(GeneratedCocktail base,
      {int? balance, int? intensity}) async {
    try {
      // Проверяем API ключ
      if (apiKey.isEmpty) {
        print('⚠️ AiEnhancer: no API key, skipping enhancement');
        return base;
      }

      print('🤖 AiEnhancer: enhancing "${base.name}"...');

      // Строим prompt
      final prompt = _buildPrompt(base, balance: balance, intensity: intensity);

      // Вызываем OpenAI
      final response = await _callOpenAI(prompt);

      // Парсим ответ
      final enhanced = _parseResponse(response, base);

      print('✅ AiEnhancer: enhancement complete');
      return enhanced;
    } catch (e) {
      // Любая ошибка → возвращаем базовый рецепт
      print('⚠️ AiEnhancer: failed ($e), returning base recipe');
      return base;
    }
  }

  /// Построить prompt для AI
  ///
  /// **Структура prompt:**
  /// 1. Контекст (роль AI)
  /// 2. Данные коктейля (name, ingredients)
  /// 3. Настройки вкуса (balance, intensity)
  /// 4. Что нужно добавить (tips, facts, profile)
  /// 5. Формат ответа (JSON)
  String _buildPrompt(GeneratedCocktail base, {int? balance, int? intensity}) {
    final ingredientsList = base.ingredients
        .map((i) => '- ${i.name} (${i.amountMl} мл)')
        .join('\n');

    // Добавляем настройки пользователя в промпт
    final userPreferences = _buildUserPreferences(balance, intensity);

    return '''
You are a professional bartender and mixologist with 20 years of experience.

Enhance this cocktail recipe with professional insights.

COCKTAIL: ${base.name}
DESCRIPTION: ${base.description}

INGREDIENTS:
$ingredientsList

METHOD: ${base.method.label}
GLASS: ${base.glass.label}

${userPreferences}

Please provide:
1. proTip: Professional advice tailored to user's preferences (1 sentence)
2. fact: Interesting historical fact about this cocktail (1 sentence)
3. secret: Bartender secret/trick for this cocktail (1 sentence)
4. garnish: Recommended garnish considering user's preferences (e.g., "Lime wheel", "Mint sprig", "Orange twist")
5. serving: Serving suggestion (e.g., "Serve immediately while cold", "Best enjoyed outdoors")
6. flavorProfile: Object with values 1-10 ADJUSTED to match user's preferences:
   - strength: Adjust based on intensity preference
   - sweetness: Adjust based on balance preference
   - acidity: Adjust based on balance preference
   - bitterness: Adjust based on balance preference

Return ONLY valid JSON in this format:
{
  "proTip": "...",
  "fact": "...",
  "secret": "...",
  "garnish": "...",
  "serving": "...",
  "flavorProfile": {
    "strength": 5,
    "sweetness": 6,
    "acidity": 7,
    "bitterness": 2
  }
}
''';
  }

  /// Построить текст с предпочтениями пользователя
  String _buildUserPreferences(int? balance, int? intensity) {
    if (balance == null && intensity == null) {
      return '';
    }

    final prefs = <String>[];

    if (balance != null) {
      if (balance <= 3) {
        prefs.add('User prefers DRY/SOUR cocktails (less sweet, more acidic)');
      } else if (balance >= 7) {
        prefs.add('User prefers SWEET cocktails (less acidic, more sweet)');
      } else {
        prefs.add('User prefers BALANCED cocktails');
      }
    }

    if (intensity != null) {
      if (intensity <= 3) {
        prefs.add('User prefers LIGHT cocktails (low alcohol, refreshing)');
      } else if (intensity >= 8) {
        prefs.add('User prefers STRONG cocktails (high alcohol, intense)');
      } else {
        prefs.add('User prefers MODERATE strength cocktails');
      }
    }

    return 'USER PREFERENCES:\n${prefs.join('\n')}\n';
  }

  /// Вызвать OpenAI API
  ///
  /// **Таймаут:** 10 секунд
  /// **Температура:** 0.7 (креативно но стабильно)
  /// **Max tokens:** 500 (достаточно для ответа)
  Future<Map<String, dynamic>> _callOpenAI(String prompt) async {
    final response = await http
        .post(
          Uri.parse(_apiUrl),
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode({
            'model': _model,
            'messages': [
              {'role': 'user', 'content': prompt},
            ],
            'temperature': 0.7,
            'max_tokens': 500,
            'response_format': {'type': 'json_object'},
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('OpenAI API error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final content = data['choices'][0]['message']['content'] as String;

    return jsonDecode(content) as Map<String, dynamic>;
  }

  /// Парсить ответ AI и применить к cocktail
  GeneratedCocktail _parseResponse(
    Map<String, dynamic> response,
    GeneratedCocktail base,
  ) {
    // Парсим flavor profile
    final flavorProfileData =
        response['flavorProfile'] as Map<String, dynamic>?;
    FlavorProfile? flavorProfile;

    if (flavorProfileData != null) {
      flavorProfile = FlavorProfile(
        strength: (flavorProfileData['strength'] as num?)?.toInt() ?? 5,
        sweetness: (flavorProfileData['sweetness'] as num?)?.toInt() ?? 5,
        acidity: (flavorProfileData['acidity'] as num?)?.toInt() ?? 5,
        bitterness: (flavorProfileData['bitterness'] as num?)?.toInt() ?? 2,
        sparkling: false,
      );
    }

    // Возвращаем улучшенный cocktail
    return GeneratedCocktail(
      name: base.name,
      description: base.description,
      ingredients: base.ingredients,
      steps: base.steps,
      method: base.method,
      glass: base.glass,
      usedIngredients: base.usedIngredients,
      skippedIngredients: base.skippedIngredients,
      skippedReasons: base.skippedReasons,
      matchScore: base.matchScore,
      cocktailType: base.cocktailType,
      imageUrl: base.imageUrl,
      sourceCocktailId: base.sourceCocktailId,
      missingForClassic: base.missingForClassic,
      suggestedReplacements: base.suggestedReplacements,
      abv: base.abv,
      sugarGrams: base.sugarGrams,
      calories: base.calories,
      allergens: base.allergens,
      wowEffect: base.wowEffect,
      whyItWorks: base.whyItWorks,
      garnish: response['garnish'] as String? ?? base.garnish,
      serving: response['serving'] as String? ?? base.serving,
      flavorProfile: flavorProfile ?? base.flavorProfile,
      explanation: base.explanation,
      proTip: response['proTip'] as String? ?? base.proTip,
      fact: response['fact'] as String? ?? base.fact,
      secret: response['secret'] as String? ?? base.secret,
    );
  }
}
