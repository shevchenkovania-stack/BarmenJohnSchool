import 'package:flutter/foundation.dart';
import 'package:coin/core/db/hive_service.dart';
import 'package:coin/core/models/inventory_item.dart';

/// Репозиторий инвентаря бара.
///
/// Хранит список ингредиентов которые ЕСТЬ на баре прямо сейчас.
/// Расширяет ChangeNotifier — UI слушает изменения через Consumer/context.watch.
///
/// Hive Box открыт один раз в HiveService.init() — здесь только чтение/запись.
class InventoryRepository extends ChangeNotifier {
  // ─── Чтение ──────────────────────────────────────────────────────────────────

  /// Все позиции инвентаря (копия для UI — не модифицируй напрямую)
  List<InventoryItem> getAll() => HiveService.inventory.values.toList();

  /// Проверяет есть ли ингредиент (регистр не важен)
  bool has(String name) => HiveService.inventory.values
      .any((item) => item.name.toLowerCase() == name.toLowerCase());

  // ─── Запись ───────────────────────────────────────────────────────────────────

  /// Добавляет ингредиент если его ещё нет.
  /// Trim + проверка пустоты — чтобы не добавить мусор.
  Future<void> add(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || has(trimmed)) return;

    await HiveService.inventory.add(InventoryItem(name: trimmed));
    notifyListeners(); // сообщаем UI об изменении
  }

  /// Удаляет позицию. [item] должен быть HiveObject из этого ящика.
  Future<void> remove(InventoryItem item) async {
    await item.delete(); // HiveObject.delete() удаляет себя из ящика
    notifyListeners();
  }

  /// Удаляет ингредиент по названию (u0440егистр не важен).
  Future<void> removeByName(String name) async {
    final lower = name.toLowerCase();
    final box = HiveService.inventory;
    final key = box.keys.firstWhere(
      (k) => (box.get(k)?.name.toLowerCase() ?? '') == lower,
      orElse: () => null,
    );
    if (key != null) {
      await box.delete(key);
      notifyListeners();
    }
  }

  /// Очищает весь инвентарь.
  Future<void> clearAll() async {
    await HiveService.inventory.clear();
    notifyListeners();
  }
}
