import 'package:flutter/foundation.dart';
import 'package:coin/core/db/hive_service.dart';
import 'package:coin/core/models/stop_item.dart';

/// Репозиторий стоп-листа бара.
///
/// Хранит ингредиенты которых НЕТ сегодня — закончились, не привезли, etc.
/// Принцип работы идентичен [InventoryRepository] но смысл противоположный.
///
/// Стоп-лист обычно сбрасывается вручную каждое утро или в начале смены.
class StopListRepository extends ChangeNotifier {
  // ─── Чтение ──────────────────────────────────────────────────────────────────

  List<StopItem> getAll() => HiveService.stopList.values.toList();

  /// Проверяет остановлен ли ингредиент (регистр не важен)
  bool isStopped(String name) => HiveService.stopList.values
      .any((item) => item.name.toLowerCase() == name.toLowerCase());

  // ─── Запись ───────────────────────────────────────────────────────────────────

  Future<void> add(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || isStopped(trimmed)) return;

    await HiveService.stopList.add(StopItem(name: trimmed));
    notifyListeners();
  }

  Future<void> remove(StopItem item) async {
    await item.delete();
    notifyListeners();
  }

  /// Очищает весь стоп-лист (вызывается в начале новой смены)
  Future<void> clearAll() async {
    await HiveService.stopList.clear();
    notifyListeners();
  }
}
