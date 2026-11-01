import 'package:hive_flutter/hive_flutter.dart';
import 'package:coin/core/constants/app_constants.dart';

// build_runner генерирует этот файл командой:
// dart run build_runner build --delete-conflicting-outputs
part 'custom_recipe.g.dart';

/// Авторский рецепт заведения — хранится полностью локально.
///
/// Не использует TheCocktailDB API — это proprietary рецепт бара.
/// Хранится в Hive box [AppConstants.customRecipesBox].
@HiveType(typeId: AppConstants.customRecipeTypeId)
class CustomRecipe extends HiveObject {
  /// Уникальный ID (UUID-строка, генерируется при создании)
  @HiveField(0)
  late String id;

  /// Название коктейля
  @HiveField(1)
  late String name;

  /// Список ингредиентов (параллельный список с [measures])
  @HiveField(2)
  late List<String> ingredients;

  /// Список мер/количеств — один к одному с [ingredients]
  @HiveField(3)
  late List<String> measures;

  /// Текст инструкции по приготовлению
  @HiveField(4)
  late String instructions;

  /// Тип стакана (может быть пустым)
  @HiveField(5)
  late String glass;

  /// Дата создания — для сортировки (новые сверху)
  @HiveField(6)
  late DateTime createdAt;

  /// Цена продажи (за единицу) — используется для расчёта маржи
  /// 0 = не задана
  @HiveField(7)
  late double sellingPrice;

  CustomRecipe({
    required this.id,
    required this.name,
    required this.ingredients,
    required this.measures,
    required this.instructions,
    required this.glass,
    required this.createdAt,
    this.sellingPrice = 0,
  });
}
