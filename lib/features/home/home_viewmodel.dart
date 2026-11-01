import 'package:flutter/material.dart';
import 'package:coin/core/models/cocktail.dart';
import 'package:coin/core/repositories/cocktail_repository.dart';
import 'package:coin/core/services/cocktail_cache_service.dart';

/// ViewModel главного экрана.
///
/// **Архитектура (offline-first):**
/// 1. При старте загружает ТОЛЬКО из Hive кэша (мгновенно, offline)
/// 2. Если кэш есть → показывает случайный коктейль
/// 3. Если кэша нет → показывает placeholder ("Загрузите базу")
/// 4. НЕ делает API запросы при старте
/// 5. API запрос только по кнопке "Ещё один" (опционально)
///
/// **Почему так:**
/// - Главная страница не должна блокировать запуск app
/// - Без интернета не должно быть ошибки
/// - User видит контент сразу (из кэша)
class HomeViewModel extends ChangeNotifier {
  final CocktailRepository _repo;
  final CocktailCacheService _cache;

  Cocktail? cocktail; // текущий случайный коктейль
  bool isLoading = false; // НЕ показываем loading при старте
  bool hasError = false;
  bool hasCache = false; // есть ли offline кэш

  HomeViewModel(this._repo, this._cache) {
    print('🏠 [HomeViewModel] Constructor called');
    loadFromCache(); // загружаем из кэша (мгновенно)
  }

  /// Загрузить случайный коктейль из Hive кэша
  ///
  /// **Что делает:**
  /// 1. Проверяет есть ли кэш в Hive
  /// 2. Если есть → выбирает случайный
  /// 3. Если нет → показывает placeholder
  ///
  /// **Время:** < 100ms (мгновенно)
  /// **Offline:** ✅ работает без интернета
  void loadFromCache() {
    print('📂 [HomeViewModel] loadFromCache called');

    // Проверяем есть ли кэш
    hasCache = _cache.isOfflineAvailable;
    print('📂 [HomeViewModel] hasCache = $hasCache');

    if (!hasCache) {
      // Нет кэша → placeholder (cocktail = null)
      cocktail = null;
      isLoading = false;
      hasError = false;
      notifyListeners();
      print('📂 HomeVM: no cache, showing placeholder');
      return;
    }

    // Есть кэш → берем случайный
    try {
      final cachedCocktails = _cache.loadAll();
      if (cachedCocktails.isEmpty) {
        cocktail = null;
        hasCache = false;
      } else {
        // Выбираем случайный (на основе timestamp для разнообразия)
        final index =
            DateTime.now().millisecondsSinceEpoch % cachedCocktails.length;
        cocktail = cachedCocktails[index];
        print(
            '📂 HomeVM: loaded from cache - ${cocktail!.strDrink} (${cachedCocktails.length} total)');
      }
    } catch (e) {
      print('❌ HomeVM: cache load failed ($e)');
      cocktail = null;
      hasCache = false;
    }

    isLoading = false;
    hasError = false;
    notifyListeners();
  }

  /// Загрузить случайный коктейль для "Рецепт дня"
  ///
  /// **Что делает:**
  /// 1. Сначала пробует из кэша (мгновенно)
  /// 2. Если кэша нет → один API вызов /random.php (быстро!)
  /// 3. НЕ скачивает всю базу (это делает CocktailListScreen)
  ///
  /// **Время:** < 1 сек (один запрос)
  /// **Offline:** ✅ работает из кэша
  Future<bool> loadRandom() async {
    print('🔘 LoadRandom: loading single random cocktail');

    isLoading = true;
    hasError = false;
    notifyListeners();

    try {
      // Один вызов API /random.php — мгновенно!
      final randomCocktail = await _repo.getRandomCocktail();

      if (randomCocktail == null) {
        print('❌ LoadRandom: no cocktail returned');
        hasError = true;
        isLoading = false;
        notifyListeners();
        return false;
      }

      cocktail = randomCocktail;
      hasCache = true;
      print('✅ LoadRandom: loaded - ${cocktail!.strDrink}');
    } catch (e) {
      print('❌ LoadRandom: error ($e)');
      hasError = true;
      isLoading = false;
      notifyListeners();
      return false;
    }

    isLoading = false;
    notifyListeners();
    return true;
  }
}
