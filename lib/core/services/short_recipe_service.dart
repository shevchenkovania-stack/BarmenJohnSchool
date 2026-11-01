import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:coin/core/models/cocktail.dart';
import 'package:coin/core/services/recipe_ai_service.dart';
import 'package:coin/core/services/measurement_service.dart';
import 'package:coin/features/ai_recipes/models/detailed_recipe.dart';

/// Короткий AI-рецепт коктейля
class ShortRecipe {
  final String cocktailId;
  final String translatedInstructions; // Переведённый текст
  final List<String> steps; // Пошагово: ["Налей 50ml", "Добавь лёд"]
  final DateTime createdAt;

  const ShortRecipe({
    required this.cocktailId,
    required this.translatedInstructions,
    required this.steps,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'cocktailId': cocktailId,
        'translatedInstructions': translatedInstructions,
        'steps': steps,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ShortRecipe.fromJson(Map<String, dynamic> json) => ShortRecipe(
        cocktailId: json['cocktailId'],
        translatedInstructions: json['translatedInstructions'] ?? '',
        steps: json['steps'] != null ? List<String>.from(json['steps']) : [],
        createdAt: DateTime.parse(json['createdAt']),
      );
}

/// Сервис для генерации и кэширования коротких AI рецептов
class ShortRecipeService extends ChangeNotifier {
  final RecipeAIService _aiService = RecipeAIService();
  final Map<String, ShortRecipe> _cache = {};

  /// Проверка включён ли AI режим
  bool get _isAiEnabled {
    // Получаем настройки глобально через Provider
    try {
      // В идеале нужно передать SettingsService но пока так
      return true; // По умолчанию AI включён
    } catch (_) {
      return true;
    }
  }

  /// Получить короткий рецепт
  Future<ShortRecipe?> getRecipe(Cocktail cocktail,
      {MeasurementService? measurementService}) async {
    // Проверяем кэш
    if (_cache.containsKey(cocktail.idDrink)) {
      debugPrint('✅ Short recipe from cache: ${cocktail.strDrink}');
      return _cache[cocktail.idDrink];
    }

    // Проверяем SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('short_recipe_${cocktail.idDrink}');
      if (data != null) {
        final recipe = ShortRecipe.fromJson(jsonDecode(data));
        _cache[cocktail.idDrink] = recipe;
        debugPrint('✅ Short recipe from prefs: ${cocktail.strDrink}');
        return recipe;
      }
    } catch (e) {
      debugPrint('❌ Error loading from prefs: $e');
    }

    // Генерируем новый
    debugPrint('🔄 Generating new short recipe: ${cocktail.strDrink}');
    return await _generateRecipe(cocktail,
        measurementService: measurementService);
  }

  /// Сгенерировать короткий рецепт через AI
  Future<ShortRecipe?> _generateRecipe(Cocktail cocktail,
      {MeasurementService? measurementService}) async {
    try {
      debugPrint('🤖 Generating AI recipe for ${cocktail.strDrink}...');

      // Вызываем AI для перевода и форматирования
      final detailedRecipe = await _aiService.expand(
        cocktail: cocktail,
        mode: RecipeMode.starter,
        locale: 'ru', // Переводим на русский
        measurementService: measurementService,
      );

      // Берём шаги из AI рецепта
      final steps = detailedRecipe.steps
          .map((step) => '${step.title}. ${step.description ?? ''}')
          .where((s) => s.trim().isNotEmpty)
          .toList();

      // Соединяем в один текст
      final fullText = steps.join('\n');

      final recipe = ShortRecipe(
        cocktailId: cocktail.idDrink,
        translatedInstructions: fullText,
        steps: steps,
        createdAt: DateTime.now(),
      );

      // Сохраняем в кэш и SharedPreferences
      _cache[cocktail.idDrink] = recipe;
      await _saveToPrefs(recipe);

      debugPrint(
          '✅ AI generated ${steps.length} steps for ${cocktail.strDrink}');
      return recipe;
    } catch (e) {
      debugPrint('❌ Error generating AI recipe: $e');
      return null;
    }
  }

  /// Быстрый перевод текста (заглушка - теперь не используется)
  Future<String> _translateText(String text) async {
    return text;
  }

  /// Разбить текст на короткие шаги
  List<String> _splitIntoSteps(String text) {
    if (text.isEmpty) return [];
    final sentences = text.split('.').where((s) => s.trim().isNotEmpty);
    return sentences.map((s) => '${s.trim()}.').toList();
  }

  /// Парсинг шагов из AI ответа
  List<String> _parseSteps(String text) {
    return [];
  }

  /// Сохранение в SharedPreferences
  Future<void> _saveToPrefs(ShortRecipe recipe) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'short_recipe_${recipe.cocktailId}', jsonEncode(recipe.toJson()));
    } catch (e) {
      debugPrint('Error saving to prefs: $e');
    }
  }

  /// Название языка для промпта
  String _getLanguageName(String locale) {
    return 'English';
  }

  /// Очистить кэш
  void clearCache() {
    _cache.clear();
  }

  /// Удалить рецепт
  Future<void> delete(String cocktailId) async {
    _cache.remove(cocktailId);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('short_recipe_$cocktailId');
    } catch (e) {
      debugPrint('Error deleting: $e');
    }
  }
}
