import 'package:flutter/foundation.dart';
import 'package:coin/core/db/hive_service.dart';
import 'package:coin/core/models/menu_builder.dart';

/// Репозиторий для управления шаблонами меню.
///
/// Хранит созданные пользователем меню (название, список коктейлей, тему).
/// Расширяет ChangeNotifier — UI слушает изменения через Consumer/context.watch.
///
/// **Методы:**
/// - getAll() — все сохранённые меню
/// - getById(id) — конкретное меню по ID
/// - save(menu) — создать или обновить меню
/// - delete(menu) — удалить меню
class MenuBuilderRepository extends ChangeNotifier {
  // ─── Чтение ──────────────────────────────────────────────────────────────────

  /// Все сохранённые меню
  List<MenuBuilder> getAll() => HiveService.menuBuilder.values.toList();

  /// Получить меню по ID
  MenuBuilder? getById(String id) => HiveService.menuBuilder.get(id);

  // ─── Запись ──────────────────────────────────────────────────────────────────

  /// Сохраняет меню (создаёт новое или обновляет существующее по id).
  ///
  /// [menu] должен быть MenuBuilder с уже установленным id.
  Future<void> save(MenuBuilder menu) async {
    await HiveService.menuBuilder.put(menu.id, menu);
    notifyListeners(); // сообщаем UI об изменении
  }

  /// Удаляет меню из хранилища.
  Future<void> delete(MenuBuilder menu) async {
    await HiveService.menuBuilder.delete(menu.id);
    notifyListeners();
  }

  /// Очищает все меню (полная очистка ящика).
  Future<void> clearAll() async {
    await HiveService.menuBuilder.clear();
    notifyListeners();
  }
}
