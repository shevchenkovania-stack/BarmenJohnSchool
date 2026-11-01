import 'dart:async';

import 'package:flutter/material.dart';
import 'package:coin/core/models/cocktail.dart';
import 'package:coin/core/repositories/cocktail_repository.dart';

/// ViewModel экрана поиска.
///
/// Использует debounce (задержку 500 мс) перед запросом к API.
/// Это значит: если пользователь быстро печатает "margarita" — мы
/// не делаем 9 запросов по одному на каждую букву, а один — после
/// паузы в наборе текста.
class SearchViewModel extends ChangeNotifier {
  final CocktailRepository _repo;

  List<Cocktail> results = []; // результаты поиска из API
  List<Cocktail> filteredResults = []; // после применения фильтров
  bool isSearching = false; // идёт запрос к API
  bool hasSearched = false; // пользователь уже что-то вводил
  String lastQuery = ''; // последний введённый запрос

  Timer? _debounce; // таймер задержки

  SearchViewModel(this._repo);

  // ─── Публичные методы ─────────────────────────────────────────────────────

  /// Вызывается при каждом изменении текста в поле поиска
  void search(String query) {
    lastQuery = query;
    print('🔍 SearchVM: query="$query"');

    // Отменяем предыдущий таймер если пользователь ещё печатает
    _debounce?.cancel();

    // Если поле пустое — сбрасываем результаты
    if (query.trim().isEmpty) {
      print('🔍 SearchVM: empty query, clearing results');
      results = [];
      filteredResults = [];
      hasSearched = false;
      notifyListeners();
      return;
    }

    // Ждём 500 мс после последнего нажатия — потом делаем запрос
    _debounce = Timer(const Duration(milliseconds: 500), () {
      print('🔍 SearchVM: debounce triggered, fetching...');
      _fetchResults(query.trim());
    });
  }

  /// Применить фильтры к результатам
  void setFilteredResults(List<Cocktail> filtered) {
    print('🔍 SearchVM: filtered to ${filtered.length} results');
    filteredResults = filtered;
    notifyListeners();
  }

  // ─── Приватные методы ─────────────────────────────────────────────────────

  Future<void> _fetchResults(String query) async {
    print('🔍 SearchVM: _fetchResults START for "$query"');
    isSearching = true;
    notifyListeners();

    results = await _repo.searchByName(query);
    print('🔍 SearchVM: _fetchResults GOT ${results.length} results');
    hasSearched = true;
    isSearching = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel(); // важно: отменяем таймер при уничтожении ViewModel
    super.dispose();
  }
}
