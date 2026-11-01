import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:coin/features/cocktail_builder/models/generated_cocktail.dart';

/// Сервис для генерации коктейлей через AI.
///
/// Использует OpenAI API (или совместимое) для создания
/// профессиональных рецептов на основе доступных ингредиентов
/// и предпочтений пользователя.
class MixologistAIService {
  final String apiKey;
  final String baseUrl;

  MixologistAIService({
    String? apiKey, // Будет передаваться извне
    this.baseUrl = 'https://api.openai.com/v1',
  }) : apiKey = apiKey ?? '';

  /// Сгенерировать коктейль.
  ///
  /// [ingredients] — список доступных ингредиентов
  /// [strength] — крепость (0-10)
  /// [sweetness] — сладость (0-10)
  /// [acidity] — кислотность (0-10)
  /// [bitterness] — горечь (0-10)
  /// [sparkling] — газированность
  /// [aroma] — аромат/настроение
  /// [texture] — текстура
  /// [goal] — цель (аперитив, дижестив и т.д.)
  Future<GeneratedCocktail> createCocktailFromPrompt(String prompt) async {
    debugPrint('🎨 Генерирую коктейль из промпта...');

    try {
      final response = await _callAPI(prompt);
      final json = jsonDecode(response) as Map<String, dynamic>;

      final cocktail = GeneratedCocktail.fromJson(json);

      debugPrint('✅ Коктейль создан: ${cocktail.name}');
      return cocktail;
    } catch (e) {
      debugPrint('❌ Ошибка генерации: $e');
      throw Exception('Не удалось создать коктейль: $e');
    }
  }

  /// Создать коктейль (старый метод для совместимости)
  /// @deprecated Используйте createCocktailFromPrompt()
  Future<GeneratedCocktail> createCocktail({
    required List<String> ingredients,
    required int strength,
    required int sweetness,
    required int acidity,
    required int bitterness,
    required bool sparkling,
    required String aroma,
    required String texture,
    required String goal,
  }) async {
    debugPrint('🎨 Генерирую коктейль...');
    debugPrint('Ингредиенты: ${ingredients.join(', ')}');
    debugPrint('Крепость: $strength, Сладость: $sweetness');

    final prompt = _buildPrompt(
      ingredients,
      strength,
      sweetness,
      acidity,
      bitterness,
      sparkling,
      aroma,
      texture,
      goal,
    );

    try {
      final response = await _callAPI(prompt);
      final json = jsonDecode(response) as Map<String, dynamic>;

      final cocktail = GeneratedCocktail.fromJson(json);

      debugPrint('✅ Коктейль создан: ${cocktail.name}');
      return cocktail;
    } catch (e) {
      debugPrint('❌ Ошибка генерации: $e');
      throw Exception('Не удалось создать коктейль: $e');
    }
  }

  /// ПАТЧ: Создать один коктейль
  Future<List<GeneratedCocktail>> createCocktailVariants(String prompt) async {
    debugPrint('🎨 Генерирую коктейль...');

    try {
      final response = await _callAPI(prompt);

      // Показываем сырой ответ для отладки
      debugPrint('📝 Сырой ответ от AI:\n$response');

      final dynamic decoded = jsonDecode(response);

      List<dynamic> jsonArray;

      // Обрабатываем разные варианты структуры ответа
      if (decoded is List) {
        // AI вернул массив - это правильно
        jsonArray = decoded;
        debugPrint('✅ AI вернул массив из ${jsonArray.length} коктейлей');
      } else if (decoded is Map) {
        // Проверяем есть ли обёртка variants (новый формат)
        if (decoded.containsKey('variants') && decoded['variants'] is List) {
          debugPrint('✅ AI вернул объект с обёрткой variants - достаём массив');
          jsonArray = decoded['variants'] as List;
          debugPrint('✅ В массиве variants: ${jsonArray.length} элементов');
        } else if (decoded.containsKey('cocktails') &&
            decoded['cocktails'] is List) {
          debugPrint(
              '✅ AI вернул объект с обёрткой cocktails - достаём массив');
          jsonArray = decoded['cocktails'] as List;
          debugPrint('✅ В массиве cocktails: ${jsonArray.length} элементов');
        } else {
          // AI вернул один объект - оборачиваем в массив
          debugPrint('⚠️ AI вернул один объект без обёртки variants/cocktails');
          jsonArray = [decoded];
        }
      } else {
        throw Exception('Неверный формат ответа от AI: ${decoded.runtimeType}');
      }

      // Показываем каждый объект перед парсингом
      for (var i = 0; i < jsonArray.length; i++) {
        // Конвертируем ингредиенты если они в неправильном формате
        final cocktail = jsonArray[i] as Map<String, dynamic>;
        debugPrint('\n🔍 === Коктейль #$i ДО конвертации ===');
        debugPrint('Name: ${cocktail['name']}');
        debugPrint(
            'Ingredients count: ${cocktail['ingredients']?.length ?? 0}');

        if (cocktail.containsKey('ingredients')) {
          final ingredients = cocktail['ingredients'] as List;
          for (var j = 0; j < ingredients.length; j++) {
            final ingredient = ingredients[j] as Map<String, dynamic>;
            debugPrint('  Ингредиент #$j ДО: $ingredient');

            // Если "ingredient" вместо "name"
            if (ingredient.containsKey('ingredient') &&
                !ingredient.containsKey('name')) {
              ingredient['name'] = ingredient['ingredient'];
              ingredient.remove('ingredient');
              debugPrint('  → Заменил ingredient на name');
            }

            // Если "amount" строка типа "120ml" вместо числа
            if (ingredient.containsKey('amount')) {
              final amount = ingredient['amount'];
              if (amount is String) {
                // Извлекаем число из "120ml"
                final number =
                    double.tryParse(amount.replaceAll(RegExp(r'[^\d.]'), ''));
                ingredient['amountMl'] = number?.round() ?? 0;
                ingredient.remove('amount');
                debugPrint(
                    '  → Конвертировал amount "$amount" в amountMl: ${ingredient['amountMl']}');
              } else if (amount is num) {
                ingredient['amountMl'] = amount.toInt();
                ingredient.remove('amount');
                debugPrint(
                    '  → Конвертировал amount в amountMl: ${ingredient['amountMl']}');
              }
            }

            debugPrint('  Ингредиент #$j ПОСЛЕ: $ingredient');
          }
        }

        debugPrint(
            '🔍 Коктейль #$i ПОСЛЕ конвертации: ${jsonEncode(cocktail)}');
      }

      final cocktails = jsonArray.map((json) {
        return GeneratedCocktail.fromJson(json as Map<String, dynamic>);
      }).toList();

      debugPrint('✅ Сгенерировано вариантов: ${cocktails.length}');
      debugPrint(
          '✅ Первый коктейль: ${cocktails.first.name}, ингредиентов: ${cocktails.first.ingredients.length}');
      return cocktails;
    } catch (e) {
      debugPrint('❌ Ошибка генерации вариантов: $e');
      throw Exception('Не удалось создать варианты коктейлей: $e');
    }
  }

  /// Построить промпт для AI
  String _buildPrompt(
    List<String> ingredients,
    int strength,
    int sweetness,
    int acidity,
    int bitterness,
    bool sparkling,
    String aroma,
    String texture,
    String goal,
  ) {
    return '''
Ты — шеф-миксолог премиум-бара с 10-летним опытом. Твоя философия: коктейль — это не просто смесь, это история в бокале.

Ты не угадываешь рецепт — ты создаёшь его осознанно, перераспределяя роли ингредиентов:
- Базовый алкоголь = ядро характера
- Миксеры = баланс и тело
- Газ = лёгкость и игра
- Кислота = свежесть и фокус
- Сладость = мягкость и послевкусие

КРИТИЧЕСКАЯ ПРОВЕРКА:
Прежде чем создавать рецепт, проверь сочетания:
❌ Если видишь конфликтующие вкусы (например, молоко + кислый сок) — НЕ используй их вместе
❌ Если слишком много разнородных ингредиентов — выбери только лучшие (3-4)
❌ Если ингредиенты не сочетаются — скажи об этом прямо и предложи альтернативу
✅ Твоя задача — спасти клиента от плохого коктейля, а не просто выполнить запрос

ВХОДНЫЕ ДАННЫЕ:

Ингредиенты: ${ingredients.join(', ')}

Профиль вкуса:
• Крепость: $strength/10
• Сладость: $sweetness/10  
• Кислотность: $acidity/10
• Горечь: $bitterness/10
• Газ: ${sparkling ? 'Да' : 'Нет'}

Аромат: $aroma
Текстура: $texture
Цель: $goal

ТВОЯ ЗАДАЧА:

Создай ОДИН уникальный коктейль который:
1. Звучит как произведение искусства
2. Имеет идеальный баланс вкусов
3. Раскрывает каждый ингредиент
4. Вызывает эмоции с первого глотка
5. НЕ содержит конфликтующих сочетаний

ПРИОРИТЕТЫ:
🥇 Лучше использовать 3 идеальных ингредиента чем 5 посредственных
🥈 Лучше отказаться от несочетаемого чем испортить коктейль
🥉 Если видишь проблему — предупреди и предложи решение

ТРЕБОВАНИЯ К РЕЦЕПТУ:

✅ Пропорции в мл (реалистичные, 20-80мл)
✅ Название с характером (не "Коктейль 1")
✅ Описание что человек почувствует
✅ Пошаговая техника приготовления — ПИШИ КАК БАРМАН, не как рецепт!

❌ НЕ выдумывай ингредиенты которых нет в списке
❌ НЕ считай лёд, соль, сахар за отдельные ингредиенты — они по умолчанию есть в любом баре
❌ НЕ используй банальные названия типа "Сладкий коктейль"
❌ НЕ пиши сухие инструкции типа "налей", "добавь"
❌ НЕ включай все ингредиенты если они не сочетаются
❌ НЕ создавай коктейль если сочетание заведомо плохое — лучше предупреди

БАРМЕНСКИЙ СТИЛЬ INSTRUCTIONS:
Представь что ты стоишь за барной стойкой и объясняешь гостю как сделать этот коктейль. 
- Используй глаголы: встряхни, помешай, влей, выдави, укрась, подай
- Добавь ощущения: "почувствуй как...", "ты услышишь...", "запахнет..."
- Дай совет прямо как бармен: "самое важное здесь — это...", "запомни —...", "фишка в том, что..."
- Описывай текстуру и звук: "когда встряхиваешь в шейкере — услышишь как лёд поёт"
- Скажи когда остановиться: "мешай пока не станет прохладным", "встряхни 10-12 раз"
- Добавь барный жаргон где уместно: "долей до борта", "отфильтруй через стрейнер", "отжатая цедра"

ФОРМАТ ОТВЕТА СТРОГО JSON:

{
  "name": "Поэтичное название с душой",
  "description": "2-3 предложения о том что человек почувствует",
  "ingredients": [
    {"name": "ингредиент", "amount": 50}
  ],
  "method": "shake|stir|build|muddle|blend|layered",
  "glass": "rocks|highball|martini|flute|coupe|shot",
  "steps": [
    "Налей 50мл базового алкоголя в охлаждённый бокал со льдом",
    "Аккуратно влей 30мл сока — он создаст красивый градиент",
    "Долей игристое до края и слегка размешай барной ложкой"
  ],
  "garnish": "цедра апельсина или null",
  "serving": "Как подавать: бокал, температура, украшение",
  "flavor_profile": {
    "strength": 5,
    "sweetness": 3,
    "acidity": 4,
    "bitterness": 1,
    "sparkling": true
  },
  "explanation": {
    "base": "почему этот алкоголь выбран и какую роль играет",
    "balance": "как достигается гармония между сладким и кислым",
    "aroma": "какие ноты раскроются в аромате",
    "overall": "почему этот коктейль запомнится"
  },
  "pro_tip": "Совет профи: одно предложение с мудростью миксолога",
  "fact": "Факт: интересное знание о вкусовых сочетаниях",
  "secret": "Секрет: техника или хак для лучшего результата"
}

ВАЖНО: Пиши так чтобы человек почувствовал себя настоящим ценителем!''';
  }

  /// Вызвать API
  Future<String> _callAPI(String prompt) async {
    if (apiKey.isEmpty) {
      throw Exception('API ключ не указан');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4o',
        'messages': [
          {
            'role': 'system',
            'content': 'Ты профессиональный миксолог. Отвечай ТОЛЬКО JSON.',
          },
          {
            'role': 'user',
            'content': prompt,
          },
        ],
        'temperature': 0.7,
        'response_format': {'type': 'json_object'},
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('API вернул ошибку: ${response.statusCode}');
    }

    final json = jsonDecode(response.body);
    return json['choices'][0]['message']['content'];
  }
}
