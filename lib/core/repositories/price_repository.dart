import 'package:flutter/foundation.dart';
import 'package:coin/core/db/hive_service.dart';
import 'package:coin/core/models/ingredient_price.dart';

/// Репозиторий прайс-листа ингредиентов.
///
/// Хранит цены бутылок/упаковок каждого ингредиента.
/// Используется для расчёта себестоимости коктейлей.
///
/// Ключ в Hive = название ингредиента в нижнем регистре
/// (чтобы "Vodka" и "vodka" ссылались на одну запись).
class PriceRepository extends ChangeNotifier {
  // ─── Чтение ──────────────────────────────────────────────────────────────────

  /// Все записи прайс-листа (отсортированы по названию)
  List<IngredientPrice> getAll() {
    final list = HiveService.priceBook.values.toList();
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  /// Найти цену по названию ингредиента (без учёта регистра).
  /// Возвращает null если ингредиент не добавлен в прайс-лист.
  IngredientPrice? findByName(String name) {
    return HiveService.priceBook.get(name.trim().toLowerCase());
  }

  // ─── Запись ──────────────────────────────────────────────────────────────────

  /// Сохраняет цену ингредиента.
  /// Ключ = название в нижнем регистре — гарантирует уникальность.
  Future<void> save(IngredientPrice price) async {
    final key = price.name.trim().toLowerCase();
    await HiveService.priceBook.put(key, price);
    notifyListeners();
  }

  /// Удаляет ингредиент из прайс-листа по названию.
  Future<void> deleteByName(String name) async {
    final key = name.trim().toLowerCase();
    await HiveService.priceBook.delete(key);
    notifyListeners();
  }

  /// Полная очистка прайс-листа.
  Future<void> clearAll() async {
    await HiveService.priceBook.clear();
    notifyListeners();
  }
}
