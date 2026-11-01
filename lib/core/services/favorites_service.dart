import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:coin/core/models/cocktail.dart';
import 'package:coin/features/cocktail_builder/models/generated_cocktail.dart';

/// Сервис избранных коктейлей.
/// Реализует [ChangeNotifier] — UI подписывается и перерисовывается
/// автоматически при добавлении / удалении из избранного.
/// Данные хранятся локально через SharedPreferences (JSON-строки).
class FavoritesService extends ChangeNotifier {
  static const _storageKey = 'favorites'; // ключ в SharedPreferences

  final SharedPreferences _prefs;
  List<Cocktail> _favorites = [];
  List<GeneratedCocktail> _aiFavorites = []; // AI коктейли

  FavoritesService(this._prefs) {
    _loadFromStorage(); // при старте сразу читаем сохранённые
    _loadAiFromStorage(); // загружаем AI коктейли
  }

  // ─── Чтение ───────────────────────────────────────────────────────────────

  /// Неизменяемый список избранных коктейлей
  List<Cocktail> get favorites => List.unmodifiable(_favorites);

  /// Неизменяемый список избранных AI коктейлей
  List<GeneratedCocktail> get aiFavorites => List.unmodifiable(_aiFavorites);

  /// Проверить, находится ли коктейль в избранном
  bool isFavorite(String id) => _favorites.any((c) => c.idDrink == id);

  // ─── Изменение ────────────────────────────────────────────────────────────

  /// Переключить: если в избранном — убрать, иначе — добавить
  Future<void> toggle(Cocktail cocktail) async {
    if (isFavorite(cocktail.idDrink)) {
      _favorites.removeWhere((c) => c.idDrink == cocktail.idDrink);
    } else {
      _favorites.add(cocktail);
    }
    await _saveToStorage(); // сохраняем изменения
    notifyListeners(); // сообщаем UI об обновлении
  }

  /// Добавить AI коктейль в избранное
  Future<void> addAiCocktail(GeneratedCocktail cocktail) async {
    _aiFavorites.add(cocktail);
    await _saveAiToStorage();
    notifyListeners();
  }

  /// Удалить AI коктейль из избранного
  Future<void> removeAiCocktail(GeneratedCocktail cocktail) async {
    _aiFavorites.removeWhere((c) => c.name == cocktail.name);
    await _saveAiToStorage();
    notifyListeners();
  }

  /// Проверить, есть ли AI коктейль в избранном
  bool isAiFavorite(String name) => _aiFavorites.any((c) => c.name == name);

  // ─── Хранилище ────────────────────────────────────────────────────────────

  /// Загружаем список из SharedPreferences при старте приложения
  void _loadFromStorage() {
    final jsonList = _prefs.getStringList(_storageKey) ?? [];
    _favorites = jsonList
        .map((j) {
          try {
            return Cocktail.fromJson(jsonDecode(j) as Map<String, dynamic>);
          } catch (_) {
            return null; // игнорируем битые записи
          }
        })
        .whereType<Cocktail>()
        .toList();
  }

  /// Сохраняем весь список в SharedPreferences
  Future<void> _saveToStorage() async {
    final jsonList = _favorites.map((c) => jsonEncode(c.toJson())).toList();
    await _prefs.setStringList(_storageKey, jsonList);
  }

  // ─── AI Коктейли ────────────────────────────────────────────────────────────

  static const _aiStorageKey = 'ai_favorites';

  void _loadAiFromStorage() {
    final jsonList = _prefs.getStringList(_aiStorageKey) ?? [];
    _aiFavorites = jsonList
        .map((j) {
          try {
            return GeneratedCocktail.fromJson(
                jsonDecode(j) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<GeneratedCocktail>()
        .toList();
  }

  Future<void> _saveAiToStorage() async {
    final jsonList = _aiFavorites.map((c) => jsonEncode(c.toJson())).toList();
    await _prefs.setStringList(_aiStorageKey, jsonList);
  }
}
