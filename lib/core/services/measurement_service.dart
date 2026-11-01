import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Единицы измерения объёма
enum VolumeUnit {
  milliliters, // ml (метрическая)
  ounces, // oz (имперская)
}

/// Единицы измерения веса
enum WeightUnit {
  grams, // g (метрическая)
  ounces, // oz (имперская)
}

/// Сервис управления единицами измерения.
///
/// Позволяет пользователю переключаться между:
/// - Миллилитры (ml) ↔ Унции (oz) для объёма
/// - Граммы (g) ↔ Унции (oz) для веса
///
/// Настройки сохраняются в SharedPreferences и применяются по всему приложению.
class MeasurementService extends ChangeNotifier {
  final SharedPreferences _prefs;

  static const String _volumeKey = 'measurement_volume_unit';
  static const String _weightKey = 'measurement_weight_unit';

  MeasurementService(this._prefs);

  // ─── Объём ────────────────────────────────────────────────────────────────

  /// Текущая единица измерения объёма
  VolumeUnit get volumeUnit {
    final value = _prefs.getString(_volumeKey) ?? 'ml';
    return value == 'oz' ? VolumeUnit.ounces : VolumeUnit.milliliters;
  }

  /// Установить единицу измерения объёма
  Future<void> setVolumeUnit(VolumeUnit unit) async {
    await _prefs.setString(
      _volumeKey,
      unit == VolumeUnit.ounces ? 'oz' : 'ml',
    );
    print(
        '📏 Volume unit changed to: ${unit == VolumeUnit.ounces ? 'oz' : 'ml'}');
    notifyListeners();
  }

  /// Переключить единицу измерения объёма
  Future<void> toggleVolumeUnit() async {
    final current = volumeUnit;
    await setVolumeUnit(
      current == VolumeUnit.milliliters
          ? VolumeUnit.ounces
          : VolumeUnit.milliliters,
    );
  }

  // ─── Вес ──────────────────────────────────────────────────────────────────

  /// Текущая единица измерения веса
  WeightUnit get weightUnit {
    final value = _prefs.getString(_weightKey) ?? 'g';
    return value == 'oz' ? WeightUnit.ounces : WeightUnit.grams;
  }

  /// Установить единицу измерения веса
  Future<void> setWeightUnit(WeightUnit unit) async {
    await _prefs.setString(
      _weightKey,
      unit == WeightUnit.ounces ? 'oz' : 'g',
    );
    print(
        '⚖️ Weight unit changed to: ${unit == WeightUnit.ounces ? 'oz' : 'g'}');
    notifyListeners();
  }

  /// Переключить единицу измерения веса
  Future<void> toggleWeightUnit() async {
    final current = weightUnit;
    await setWeightUnit(
      current == WeightUnit.grams ? WeightUnit.ounces : WeightUnit.grams,
    );
  }

  // ─── Конвертация ──────────────────────────────────────────────────────────

  /// Конвертировать объём в выбранную единицу
  ///
  /// [valueMl] - значение в миллилитрах из API
  /// Возвращает отформатированную строку (например "50 ml" или "1.7 oz")
  String formatVolume(double valueMl) {
    switch (volumeUnit) {
      case VolumeUnit.milliliters:
        return '${valueMl.round()} ml';
      case VolumeUnit.ounces:
        final oz = valueMl / 29.5735;
        return '${oz.toStringAsFixed(1)} oz';
    }
  }

  /// Конвертировать вес в выбранную единицу
  ///
  /// [valueG] - значение в граммах
  /// Возвращает отформатированную строку
  String formatWeight(double valueG) {
    switch (weightUnit) {
      case WeightUnit.grams:
        return '${valueG.round()} g';
      case WeightUnit.ounces:
        final oz = valueG / 28.3495;
        return '${oz.toStringAsFixed(1)} oz';
    }
  }

  /// Получить символ единицы измерения
  String get volumeSymbol => volumeUnit == VolumeUnit.milliliters ? 'ml' : 'oz';
  String get weightSymbol => weightUnit == WeightUnit.grams ? 'g' : 'oz';

  // ─── Системные настройки ──────────────────────────────────────────────────

  /// Сбросить к значениям по умолчанию (метрическая система)
  Future<void> resetToDefaults() async {
    await _prefs.setString(_volumeKey, 'ml');
    await _prefs.setString(_weightKey, 'g');
    notifyListeners();
  }
}
