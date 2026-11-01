import 'package:hive_flutter/hive_flutter.dart';
import 'package:coin/core/constants/app_constants.dart';
import 'package:coin/core/models/inventory_item.dart';
import 'package:coin/core/models/stop_item.dart';
import 'package:coin/core/models/custom_recipe.dart';
import 'package:coin/core/models/menu_builder.dart';
import 'package:coin/core/models/ingredient_price.dart';

/// Инициализация и реестр Hive.
///
/// Один вызов [init()] в main() — всё остальное время используем
/// статические геттеры [inventory], [stopList], [customRecipes].
///
/// Почему статические геттеры, а не синглтон?
/// Hive.box() сам является синглтоном внутри — геттер просто делает код
/// читабельным и централизует имена ящиков.
class HiveService {
  HiveService._(); // только статика

  /// Инициализирует Hive, регистрирует адаптеры, открывает все ящики.
  /// Вызывать один раз в main() до runApp().
  static Future<void> init() async {
    // Инициализируем Hive с привязкой к Flutter (использует app directory)
    await Hive.initFlutter();

    // Регистрируем адаптеры — сгенерированы build_runner из аннотаций @HiveType
    Hive.registerAdapter(InventoryItemAdapter());
    Hive.registerAdapter(StopItemAdapter());
    Hive.registerAdapter(CustomRecipeAdapter());
    Hive.registerAdapter(MenuBuilderAdapter());
    Hive.registerAdapter(IngredientPriceAdapter());

    // Открываем ящики — после этого они синхронно доступны через box()
    await Hive.openBox<InventoryItem>(AppConstants.inventoryBox);
    await Hive.openBox<StopItem>(AppConstants.stopListBox);
    await Hive.openBox<CustomRecipe>(AppConstants.customRecipesBox);
    await Hive.openBox<MenuBuilder>(AppConstants.menuBuilderBox);
    await Hive.openBox<IngredientPrice>(AppConstants.priceBookBox);
    await Hive.openBox<String>(AppConstants.savedRecipesBox);

    // Cocktail cache box (для offline кэша коктейлей)
    // Используем dynamic type т.к. храним Map<String, dynamic>
    await Hive.openBox('cocktails_cache');
  }

  // ─── Геттеры ящиков ──────────────────────────────────────────────────────────
  // Используй эти геттеры везде — не пиши имена ящиков вручную.

  static Box<InventoryItem> get inventory =>
      Hive.box<InventoryItem>(AppConstants.inventoryBox);

  static Box<StopItem> get stopList =>
      Hive.box<StopItem>(AppConstants.stopListBox);

  static Box<CustomRecipe> get customRecipes =>
      Hive.box<CustomRecipe>(AppConstants.customRecipesBox);

  static Box<MenuBuilder> get menuBuilder =>
      Hive.box<MenuBuilder>(AppConstants.menuBuilderBox);

  static Box<IngredientPrice> get priceBook =>
      Hive.box<IngredientPrice>(AppConstants.priceBookBox);

  static Box<String> get savedRecipes =>
      Hive.box<String>(AppConstants.savedRecipesBox);
}
