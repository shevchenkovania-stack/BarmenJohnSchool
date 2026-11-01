import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Модель цены бутылки ингредиента
class BottlePrice {
  final String ingredientId; // Уникальный ID ингредиента
  final String ingredientName; // Название (для отображения)
  final double bottleVolume; // Объём бутылки в мл
  final double bottlePrice; // Цена бутылки в MDL
  final DateTime lastUpdated; // Когда обновлено

  const BottlePrice({
    required this.ingredientId,
    required this.ingredientName,
    required this.bottleVolume,
    required this.bottlePrice,
    required this.lastUpdated,
  });

  /// Стоимость 1 мл
  double get pricePerMl => bottlePrice / bottleVolume;

  /// Рассчитать стоимость порции
  double calculatePortionCost(double volumeMl) {
    return volumeMl * pricePerMl;
  }

  /// Сохранить в SharedPreferences
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'bottle_price_$ingredientId';
    final data = {
      'ingredientId': ingredientId,
      'ingredientName': ingredientName,
      'bottleVolume': bottleVolume,
      'bottlePrice': bottlePrice,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
    await prefs.setString(key, jsonEncode(data));
  }

  /// Загрузить из SharedPreferences
  static Future<BottlePrice?> load(String ingredientId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'bottle_price_$ingredientId';
    final dataStr = prefs.getString(key);
    if (dataStr == null) return null;

    final data = jsonDecode(dataStr) as Map<String, dynamic>;
    return BottlePrice(
      ingredientId: data['ingredientId'],
      ingredientName: data['ingredientName'],
      bottleVolume: data['bottleVolume'].toDouble(),
      bottlePrice: data['bottlePrice'].toDouble(),
      lastUpdated: DateTime.parse(data['lastUpdated']),
    );
  }

  /// Получить все сохранённые цены
  static Future<List<BottlePrice>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('bottle_price_'));

    final prices = <BottlePrice>[];
    for (final key in keys) {
      final dataStr = prefs.getString(key);
      if (dataStr != null) {
        final data = jsonDecode(dataStr) as Map<String, dynamic>;
        prices.add(BottlePrice(
          ingredientId: data['ingredientId'],
          ingredientName: data['ingredientName'],
          bottleVolume: data['bottleVolume'].toDouble(),
          bottlePrice: data['bottlePrice'].toDouble(),
          lastUpdated: DateTime.parse(data['lastUpdated']),
        ));
      }
    }
    return prices;
  }

  /// Удалить цену
  static Future<void> delete(String ingredientId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('bottle_price_$ingredientId');
  }
}
