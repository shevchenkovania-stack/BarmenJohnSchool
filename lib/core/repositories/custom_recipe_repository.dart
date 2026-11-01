import 'package:flutter/foundation.dart';
import 'package:coin/core/db/hive_service.dart';
import 'package:coin/core/models/custom_recipe.dart';

/// Репозиторий авторских рецептов заведения.
///
/// Полный CRUD для рецептов которые бар добавил сам.
/// Идентификация по [CustomRecipe.id] — UUID строка.
class CustomRecipeRepository extends ChangeNotifier {
  // ─── Чтение ──────────────────────────────────────────────────────────────────

  /// Все рецепты, отсортированные по дате создания (новые сверху)
  List<CustomRecipe> getAll() => HiveService.customRecipes.values.toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  // ─── Запись ───────────────────────────────────────────────────────────────────

  /// Сохраняет рецепт: создаёт новый или обновляет существующий.
  ///
  /// Поиск по [recipe.id] — если нашли, обновляем поля на месте.
  /// Если не нашли — добавляем как новый.
  Future<void> save(CustomRecipe recipe) async {
    // Ищем существующий рецепт с таким же id
    final existing = HiveService.customRecipes.values
        .where((r) => r.id == recipe.id)
        .toList();

    if (existing.isNotEmpty) {
      // Обновляем поля HiveObject в памяти и сохраняем обратно в ящик
      final item = existing.first;
      item.name = recipe.name;
      item.ingredients = recipe.ingredients;
      item.measures = recipe.measures;
      item.instructions = recipe.instructions;
      item.glass = recipe.glass;
      await item.save(); // HiveObject.save() записывает изменения
    } else {
      await HiveService.customRecipes.add(recipe);
    }

    notifyListeners();
  }

  /// Удаляет рецепт по объекту
  Future<void> delete(CustomRecipe recipe) async {
    await recipe.delete();
    notifyListeners();
  }
}
