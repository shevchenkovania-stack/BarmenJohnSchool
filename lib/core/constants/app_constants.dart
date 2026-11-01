/// Централизованное место для всех магических строк и чисел.
///
/// Hive box names здесь — чтобы одна опечатка не сломала хранилище
/// в половине кодовой базы. Меняем в одном месте.
class AppConstants {
  AppConstants._(); // нельзя создать экземпляр — только статика

  // ─── Hive box names ──────────────────────────────────────────────────────────

  /// Ящик для инвентаря бара (что есть на баре сейчас)
  static const String inventoryBox = 'inventory';

  /// Ящик для стоп-листа (что закончилось сегодня)
  static const String stopListBox = 'stop_list';

  /// Ящик для авторских рецептов заведения
  static const String customRecipesBox = 'custom_recipes';

  /// Ящик для шаблонов меню (печатное меню)
  static const String menuBuilderBox = 'menu_builder';

  /// Ящик для цен ингредиентов (прайс-лист)
  static const String priceBookBox = 'price_book';

  /// Ящик для сохранённых AI-рецептов (JSON строки)
  static const String savedRecipesBox = 'saved_recipes';

  // ─── SharedPreferences keys ──────────────────────────────────────────────────

  /// Код языка интерфейса: 'en' | 'ru' | 'ro'
  static const String localeKey = 'locale';

  /// Масштаб шрифта (0.8, 0.9, 1.0, 1.1, 1.2)
  static const String fontScaleKey = 'font_scale';

  // ─── Hive type IDs ───────────────────────────────────────────────────────────
  // Каждая Hive-модель получает уникальный integer ID.
  // Эти константы документируют назначение каждого ID — никогда не меняй
  // существующие значения иначе Hive не сможет читать старые данные.

  static const int inventoryItemTypeId = 0;
  static const int stopItemTypeId = 1;
  static const int customRecipeTypeId = 2;
  static const int menuBuilderTypeId = 3;
  static const int ingredientPriceTypeId = 4;
}
