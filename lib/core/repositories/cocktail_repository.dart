import 'dart:async';
import 'package:coin/core/api/cocktail_api.dart';
import 'package:coin/core/models/cocktail.dart';
import 'package:coin/core/models/database_load_progress.dart';
import 'package:coin/core/services/cocktail_cache_service.dart';

/// Репозиторий — прослойка между API и ViewModels.
///
/// **Отвечает за:**
/// - Загрузку коктейлей из API TheCocktailDB
/// - Кэширование в memory (быстрый доступ)
/// - Кэширование в Hive (offline доступ)
/// - Предоставление данных для matcher и UI
///
/// **Архитектура кэширования (3 уровня):**
/// 1. Memory cache (_letterCache) - мгновенный доступ пока приложение открыто
/// 2. Hive cache (CocktailCacheService) - persistent storage, работает offline
/// 3. API (CocktailApi) - источник данных, требует интернет
///
/// **Flow загрузки:**
/// ```
/// getAll() → Memory → Hive → API
///     ↓          ↓        ↓      ↓
///   есть?     вернуть  вернуть  загрузить
///             ✅        ✅      + сохранить в Hive
/// ```
class CocktailRepository {
  final _api = CocktailApi();
  final _cache = CocktailCacheService(); // Offline cache

  // Кэш: буква → список коктейлей.
  // Это позволяет не делать повторные API-запросы при повторном открытии списка.
  final Map<String, List<Cocktail>> _letterCache = {};

  /// Stream для отслеживания прогресса загрузки
  ///
  /// **Когда использовать:**
  /// - Показать progress bar при первом запуске
  /// - Обновить UI в реальном времени
  ///
  /// **Пример:**
  /// ```dart
  /// repository.loadProgress.listen((progress) {
  ///   print('${progress.progressPercent}% - ${progress.currentLetter}');
  /// });
  /// ```
  final _progressController =
      StreamController<DatabaseLoadProgress>.broadcast();
  Stream<DatabaseLoadProgress> get loadProgress => _progressController.stream;

  /// Отправить обновление прогресса
  void _emitProgress(DatabaseLoadProgress progress) {
    if (!_progressController.isClosed) {
      _progressController.add(progress);
    }
  }

  // ─── Публичные методы ─────────────────────────────────────────────────────

  /// Коктейли по первой букве (A, B, …, Z).
  /// Если буква уже загружалась — вернёт из кэша мгновенно.
  Future<List<Cocktail>> getCocktailsByLetter(String letter) async {
    // Возвращаем из кэша если уже есть
    if (_letterCache.containsKey(letter)) {
      return _letterCache[letter]!;
    }

    try {
      final response = await _api.listByFirstLetter(letter);
      final drinks = response.data['drinks'] as List?;

      // API возвращает null если коктейлей на эту букву нет (например X)
      final list = drinks == null
          ? <Cocktail>[]
          : drinks
              .map((d) => Cocktail.fromJson(d as Map<String, dynamic>))
              .toList();

      _letterCache[letter] = list; // сохраняем в кэш
      return list;
    } catch (_) {
      // При ошибке не ломаем приложение — просто пустой список
      return [];
    }
  }

  /// Поиск по названию (вызывается при вводе текста в Search).
  Future<List<Cocktail>> searchByName(String query) async {
    final queryLower = query.toLowerCase();

    // Уровень 1: Ищем в memory cache (если загружали в этой сессии)
    if (_letterCache.isNotEmpty) {
      final allMemory = getAllCached();
      final memoryResults = allMemory
          .where((c) => c.strDrink.toLowerCase().contains(queryLower))
          .toList();

      if (memoryResults.isNotEmpty) {
        print('✅ Search: found ${memoryResults.length} in memory for "$query"');
        return memoryResults;
      }
    }

    // Уровень 2: Ищем в Hive кэше (offline)
    final cachedCocktails = _cache.loadAll();
    if (cachedCocktails.isNotEmpty) {
      final localResults = cachedCocktails
          .where((c) => c.strDrink.toLowerCase().contains(queryLower))
          .toList();

      if (localResults.isNotEmpty) {
        print('✅ Search: found ${localResults.length} in cache for "$query"');
        return localResults;
      }
    }

    // Уровень 3: API (требует интернет)
    try {
      final response = await _api.searchByName(query);
      final drinks = response.data['drinks'] as List?;
      if (drinks == null) return [];
      return drinks
          .map((d) => Cocktail.fromJson(d as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Получить все коктейли с offline fallback
  ///
  /// **Архитектура (3 уровня):**
  /// 1. Memory cache - если уже загружали в этой сессии
  /// 2. Hive cache - если загружали раньше (offline работает)
  /// 3. API - если кэша нет (требует интернет)
  ///
  /// **Возвращает:**
  /// - Список всех коктейлей из кэша или API
  ///
  /// **Бросает Exception:**
  /// - Если нет интернета И нет кэша (первый запуск offline)
  ///
  /// **Пример:**
  /// ```dart
  /// try {
  ///   final cocktails = await repo.getAll();
  ///   print('Загружено ${cocktails.length} коктейлей');
  /// } catch (e) {
  ///   print('Ошибка: $e');
  ///   // Показать UI "Подключите интернет"
  /// }
  /// ```
  Future<List<Cocktail>> getAll() async {
    // Уровень 1: Memory cache (мгновенно)
    if (_letterCache.isNotEmpty) {
      final all = getAllCached();
      print(
          '✅ CocktailRepository: loaded from memory cache (${all.length} cocktails)');
      return all;
    }

    // Уровень 2: Hive cache (offline, ~100ms)
    final cachedCocktails = _cache.loadAll();
    if (cachedCocktails.isNotEmpty) {
      // Восстанавливаем memory cache из Hive
      _rebuildLetterCache(cachedCocktails);

      print(
          '✅ CocktailRepository: loaded from Hive cache (${cachedCocktails.length} cocktails, offline)');

      // Если кэш старый - обновляем в фоне
      if (_cache.isStale()) {
        print(
            '🔄 CocktailRepository: cache is stale, refreshing in background...');
        _refreshInBackground();
      }

      return cachedCocktails;
    }

    // Уровень 3: API (требует интернет, ~10-30 секунд)
    try {
      print('🌐 CocktailRepository: no cache, loading from API...');
      await preloadAll();
      final all = getAllCached();

      // Сохраняем в Hive для offline доступа
      await _cache.saveAll(all);
      print(
          '✅ CocktailRepository: loaded from API and cached to Hive (${all.length} cocktails)');

      return all;
    } catch (e) {
      throw Exception(
        'Нет интернета и нет локальной базы коктейлей.\n'
        'Подключитесь к интернету при первом запуске, чтобы скачать базу.',
      );
    }
  }

  /// Загрузить все коктейли из API в фоне (не блокирует UI)
  ///
  /// **Когда вызывается:**
  /// - Кэш есть, но старше 7 дней
  /// - Обновляем данные не мешая пользователю
  Future<void> _refreshInBackground() async {
    try {
      print('🔄 CocktailRepository: starting background refresh...');

      await preloadAll();
      final all = getAllCached();

      // Обновляем Hive cache
      await _cache.saveAll(all);

      print(
          '✅ CocktailRepository: background refresh complete (${all.length} cocktails)');
    } catch (e) {
      print('⚠️ CocktailRepository: background refresh failed: $e');
      // Не критично - используем старый кэш
    }
  }

  /// Восстановить letter cache из списка коктейлей
  ///
  /// **Зачем:**
  /// - При загрузке из Hive получаем плоский список
  /// - Letter cache нужен для getCocktailsByLetter()
  /// - Группируем по первой букве названия
  void _rebuildLetterCache(List<Cocktail> cocktails) {
    _letterCache.clear();

    for (final cocktail in cocktails) {
      final firstLetter = cocktail.strDrink[0].toUpperCase();

      if (!_letterCache.containsKey(firstLetter)) {
        _letterCache[firstLetter] = [];
      }

      _letterCache[firstLetter]!.add(cocktail);
    }

    print(
        '📂 CocktailRepository: rebuilt letter cache (${_letterCache.length} letters)');
  }

  /// Проверить доступен ли offline mode
  ///
  /// **Возвращает:**
  /// - `true` если в Hive есть коктейли (можно работать без интернета)
  /// - `false` если кэш пустой (нужен интернет для первой загрузки)
  bool get isOfflineAvailable => _cache.isOfflineAvailable;

  /// Получить количество коктейлей в кэше
  ///
  /// **Возвращает:**
  /// - Количество сохраненных коктейлей (0 если нет кэша)
  int get cachedCount => _cache.size;

  /// Все коктейли которые уже загружены в кэш.
  ///
  /// Используется в CanMake экране — он фильтрует кэш по инвентарю.
  /// Если кэш ещё пустой — вернёт []. Используй [preloadAll] для прогрева.
  List<Cocktail> getAllCached() =>
      _letterCache.values.expand((list) => list).toList();

  /// 🔥 Загрузить коктейли из Hive в memory cache (для preload при старте)
  void preloadFromHive() {
    final cachedCocktails = _cache.loadAll();
    if (cachedCocktails.isEmpty) {
      print('⚠️ PreloadFromHive: cache is empty');
      return;
    }

    print(
        '📦 PreloadFromHive: loading ${cachedCocktails.length} into memory...');

    // Заполняем _letterCache по первой букве
    for (final cocktail in cachedCocktails) {
      final firstLetter = cocktail.strDrink.isNotEmpty
          ? cocktail.strDrink[0].toUpperCase()
          : '#';

      _letterCache.putIfAbsent(firstLetter, () => []).add(cocktail);
    }

    print(
        '✅ PreloadFromHive: memory cache ready with ${getAllCached().length} cocktails');
  }

  /// Уникальные названия всех ингредиентов из загруженных коктейлей.
  ///
  /// Используется в InventoryScreen для каталога ингредиентов с картинками.
  List<String> getAllIngredientNames() {
    final seen = <String>{}; // нижний регистр для проверки дублей
    final result = <String>[];
    for (final cocktail in getAllCached()) {
      for (final name in cocktail.ingredients) {
        final key = name.trim().toLowerCase();
        if (key.isNotEmpty && seen.add(key)) {
          result.add(
              name.trim()); // сохраняем оригинальный регистр первого вхождения
        }
      }
    }
    result.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return result;
  }

  /// Запускает фоновую загрузку всех букв A→Z для прогрева кэша.
  ///
  /// Вызывается при старте приложения чтобы CanMake работал сразу.
  /// Использует тот же кэш что и CocktailListViewModel — данные не дублируются.
  ///
  /// **Progress tracking:**
  /// - Эмитит DatabaseLoadProgress после каждой буквы
  /// - Можно подписаться через repository.loadProgress
  Future<void> preloadAll() async {
    final letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('');
    var totalLoaded = 0;

    for (int i = 0; i < letters.length; i++) {
      final letter = letters[i];

      // Эмитим прогресс НАЧАЛО буквы
      _emitProgress(DatabaseLoadProgress(
        currentLetter: letter,
        totalLetters: 26,
        loadedCocktails: totalLoaded,
        currentLetterIndex: i,
      ));

      await getCocktailsByLetter(letter);

      // Обновляем количество загруженных
      totalLoaded = getAllCached().length;

      // Эмитим прогресс КОНЕЦ буквы
      _emitProgress(DatabaseLoadProgress(
        currentLetter: letter,
        totalLetters: 26,
        loadedCocktails: totalLoaded,
        currentLetterIndex: i,
      ));
    }

    print('✅ preloadAll complete: $totalLoaded cocktails loaded');
  }

  /// Все ингредиенты из API TheCocktailDB
  List<String> get allIngredients {
    final seen = <String>{};
    final result = <String>[];
    for (final cocktail in getAllCached()) {
      for (final name in cocktail.ingredients) {
        final key = name.trim().toLowerCase();
        if (key.isNotEmpty && seen.add(key)) {
          result.add(name.trim());
        }
      }
    }
    result.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return result;
  }

  /// Случайный коктейль для главного экрана.
  ///
  /// **Архитектура (2 уровня):**
  /// 1. Hive cache - выбирает случайный из локальной базы (offline работает)
  /// 2. API - только если кэш пустой (требует интернет)
  ///
  /// **Возвращает:**
  /// - Случайный коктейль из кэша или API
  /// - null если ничего не доступно
  Future<Cocktail?> getRandomCocktail() async {
    try {
      // Уровень 1: Берем случайный из Hive кэша (offline)
      final cachedCocktails = _cache.loadAll();
      if (cachedCocktails.isNotEmpty) {
        final random = cachedCocktails[
            DateTime.now().millisecondsSinceEpoch % cachedCocktails.length];
        print(
            '✅ getRandom: from Hive cache (${cachedCocktails.length} cocktails) - ${random.strDrink}');
        return random;
      }

      // Уровень 2: API (требует интернет)
      print('🌐 getRandom: no cache, loading from API...');
      final response = await _api.getRandom();
      final drinks = response.data['drinks'] as List?;
      if (drinks == null || drinks.isEmpty) {
        print('❌ getRandom: no cocktails found');
        return null;
      }
      final cocktail = Cocktail.fromJson(drinks.first as Map<String, dynamic>);
      print('✅ getRandom: from API - ${cocktail.strDrink}');
      return cocktail;
    } catch (e) {
      print('❌ getRandom: failed ($e)');
      return null;
    }
  }
}
