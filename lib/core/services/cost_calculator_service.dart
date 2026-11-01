import 'package:flutter/foundation.dart';
import 'package:coin/core/models/bottle_price.dart';

/// Сервис управления ценами на ингредиенты
class CostCalculatorService extends ChangeNotifier {
  final Map<String, BottlePrice> _prices = {};

  /// Синонимы ингредиентов: "sambuca" → "black sambuca"
  final Map<String, String> _ingredientSynonyms = {
    'sambuca': 'black sambuca',
    'vodka': 'vodka',
    'rum': 'light rum',
    'gin': 'gin',
    'tequila': 'tequila',
    'whiskey': 'blended whiskey',
    'brandy': 'brandy',
  };

  /// Нормализовать название ингредиента
  String _normalizeIngredient(String ingredient) {
    final lower = ingredient.toLowerCase().trim();
    // Проверяем синонимы
    if (_ingredientSynonyms.containsKey(lower)) {
      return _ingredientSynonyms[lower]!;
    }
    // Ищем частичное совпадение
    for (final entry in _ingredientSynonyms.entries) {
      if (entry.value.contains(lower) || lower.contains(entry.key)) {
        return entry.value;
      }
    }
    return lower;
  }

  /// Получить цену ингредиента
  BottlePrice? getPrice(String ingredientId) {
    final normalized = _normalizeIngredient(ingredientId);
    return _prices[normalized];
  }

  /// Установить цену ингредиента
  Future<void> setPrice(BottlePrice price) async {
    await price.save();
    _prices[price.ingredientId] = price;
    notifyListeners();
  }

  /// Загрузить все цены
  Future<void> loadPrices() async {
    final prices = await BottlePrice.getAll();
    for (final price in prices) {
      _prices[price.ingredientId] = price;
    }
    notifyListeners();
  }

  /// Рассчитать стоимость коктейля
  double calculateCocktailCost(
      List<String> ingredients, List<String> measures) {
    double total = 0.0;

    for (int i = 0; i < ingredients.length; i++) {
      final ingredient = ingredients[i];
      final measure = measures[i];

      // Парсим объём из меры (например "50 ml" → 50)
      final volume = _parseVolume(measure);
      if (volume > 0) {
        final price = getPrice(ingredient.toLowerCase());
        if (price != null) {
          total += price.calculatePortionCost(volume);
        }
      }
    }

    return total;
  }

  /// Парсинг объёма из строки меры
  double _parseVolume(String measure) {
    if (measure.isEmpty) return 0.0;

    // Удаляем текст, оставляем цифры
    final numbers = measure.replaceAll(RegExp(r'[^0-9.]'), '');
    if (numbers.isEmpty) return 0.0;

    return double.tryParse(numbers) ?? 0.0;
  }

  /// Проверка: есть ли цена для всех ингредиентов
  bool hasAllPrices(List<String> ingredients) {
    for (final ingredient in ingredients) {
      final normalized = _normalizeIngredient(ingredient);
      if (_prices[normalized] == null) {
        return false;
      }
    }
    return true;
  }

  /// Получить недостающие ингредиенты
  List<String> getMissingIngredients(List<String> ingredients) {
    final missing = <String>[];
    for (final ingredient in ingredients) {
      final normalized = _normalizeIngredient(ingredient);
      if (_prices[normalized] == null) {
        missing.add(ingredient);
      }
    }
    return missing;
  }
}
