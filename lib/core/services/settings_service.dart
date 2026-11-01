import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:coin/core/constants/app_constants.dart';
import 'package:coin/features/ai_recipes/models/detailed_recipe.dart';

/// Сервис настроек приложения.
///
/// Хранит выбранный язык, режим рецептов (Starter/Expert) и AI режим.
/// При смене настроек вызывает notifyListeners() → UI обновляется.
class SettingsService extends ChangeNotifier {
  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  // ─── Язык ────────────────────────────────────────────────────────────────────

  /// Поддерживаемые языки: коды и отображаемые названия.
  /// Порядок = порядок в Settings экране.
  static const supportedLanguages = [
    ('en', 'English'),
    ('ru', 'Русский'),
    ('ro', 'Română'),
  ];

  /// Текущая локаль из настроек.
  /// По умолчанию — русский (если пользователь ещё не выбирал).
  Locale get locale {
    final code = _prefs.getString(AppConstants.localeKey) ?? 'ru';
    return Locale(code);
  }

  /// Изменить язык интерфейса. [languageCode] — 'en', 'ru' или 'ro'.
  Future<void> setLocale(String languageCode) async {
    await _prefs.setString(AppConstants.localeKey, languageCode);

    // Очищаем ВСЕ короткие рецепты чтобы перевелись на новый язык
    final keys =
        _prefs.getKeys().where((k) => k.startsWith('short_recipe_')).toList();
    for (final key in keys) {
      await _prefs.remove(key);
    }
    print(
        '🌐 Locale changed to $languageCode, cleared ${keys.length} cached recipes');

    notifyListeners();
  }

  // ─── AI Mode ────────────────────────────────────────────────────────────────

  /// Ключ для хранения AI режима
  static const String _aiModeKey = 'ai_mode_enabled';

  /// AI режим включён по умолчанию.
  bool get isAiModeEnabled {
    return _prefs.getBool(_aiModeKey) ?? true;
  }

  /// Установить AI режим
  Future<void> setAiMode(bool enabled) async {
    await _prefs.setBool(_aiModeKey, enabled);
    print('🤖 AI Mode ${enabled ? 'enabled' : 'disabled'}');
    notifyListeners();
  }

  // ─── Режим рецептов (Starter/Expert) ────────────────────────────────────────

  /// Ключ для хранения режима
  static const String _recipeModeKey = 'recipe_mode';

  /// Режим по умолчанию — Expert (Starter mode removed)
  RecipeMode get recipeMode {
    final modeName = _prefs.getString(_recipeModeKey) ?? 'expert';
    return RecipeMode.values.firstWhere(
      (mode) => mode.name == modeName,
      orElse: () => RecipeMode.expert,
    );
  }

  /// Установить режим рецептов
  Future<void> setRecipeMode(RecipeMode mode) async {
    await _prefs.setString(_recipeModeKey, mode.name);
    notifyListeners();
  }

  /// Переключить на противоположный режим
  Future<void> toggleRecipeMode() async {
    final current = recipeMode;
    final newMode =
        current == RecipeMode.starter ? RecipeMode.expert : RecipeMode.starter;
    await setRecipeMode(newMode);
  }

  // ─── Масштаб шрифта ─────────────────────────────────────────────────────────

  /// Доступные значения масштаба шрифта.
  static const List<double> fontScaleOptions = [0.8, 0.9, 1.0, 1.1, 1.2];

  /// Текущий масштаб шрифта (по умолчанию 1.0).
  double get fontScale {
    return _prefs.getDouble(AppConstants.fontScaleKey) ?? 1.0;
  }

  /// Установить масштаб шрифта.
  Future<void> setFontScale(double scale) async {
    await _prefs.setDouble(AppConstants.fontScaleKey, scale);
    notifyListeners();
  }
}
