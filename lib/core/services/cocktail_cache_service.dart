import 'package:hive/hive.dart';
import 'package:coin/core/models/cocktail.dart';

/// Сервис кэширования коктейлей в Hive (локальное хранилище)
///
/// **Зачем нужен:**
/// - Сохраняет коктейли из API в локальную базу
/// - Позволяет работать без интернета (offline-first)
/// - Размер базы ~600 коктейлей = ~1.5 MB на диске
///
/// **Как работает:**
/// 1. При первом запуске: загружает из API → сохраняет в Hive
/// 2. При повторном: загружает из Hive (мгновенно, offline)
/// 3. Через 7 дней: обновляет из API в фоне
///
/// **Архитектура:**
/// - CocktailCacheService отвечает ТОЛЬКО за сохранение/загрузку
/// - Не делает API запросы (это CocktailRepository)
/// - Не содержит бизнес-логики (это ViewModel)
///
/// **Пример использования:**
/// ```dart
/// final cache = CocktailCacheService();
///
/// // Сохранить после загрузки из API
/// await cache.saveAll(cocktails);
///
/// // Загрузить при запуске (offline)
/// final cocktails = cache.loadAll();
///
/// // Проверить когда обновляли
/// final isStale = cache.isStale(); // true если > 7 дней
/// ```
class CocktailCacheService {
  /// Имя Hive box для хранения коктейлей
  static const String _boxName = 'cocktails_cache';

  /// Ключ для хранения даты последнего обновления
  static const String _lastUpdatedKey = 'last_updated';

  /// Максимальный возраст кэша (7 дней)
  /// После этого кэш считается stale и требует обновления
  static const Duration _maxCacheAge = Duration(days: 7);

  /// Сохранить список коктейлей в Hive
  ///
  /// **Параметры:**
  /// - `cocktails`: список коктейлей для сохранения
  ///
  /// **Что делает:**
  /// 1. Очищает старый кэш
  /// 2. Сохраняет каждый коктейль по ID (idDrink)
  /// 3. Записывает дату обновления
  ///
  /// **Время выполнения:** ~1-2 секунды для 600 коктейлей
  /// **Размер на диске:** ~1.5 MB
  Future<void> saveAll(List<Cocktail> cocktails) async {
    print('💾 CocktailCache.saveAll: START - opening box...');
    final box = await Hive.openBox(_boxName);

    print('💾 CocktailCache.saveAll: clearing old cache...');
    // Очищаем старый кэш
    await box.clear();

    print('💾 CocktailCache.saveAll: saving ${cocktails.length} cocktails...');
    // Сохраняем каждый коктейль
    int saved = 0;
    for (final cocktail in cocktails) {
      await box.put(cocktail.idDrink, cocktail.toJson());
      saved++;
      if (saved % 100 == 0) {
        print('💾 CocktailCache.saveAll: saved $saved/${cocktails.length}...');
      }
    }

    // Сохраняем дату обновления
    await box.put(_lastUpdatedKey, DateTime.now().toIso8601String());

    print('💾 CocktailCache: saved ${cocktails.length} cocktails to Hive');
    print('💾 CocktailCache: box now has ${box.length} entries');
    print('💾 CocktailCache.saveAll: COMPLETE ✅');
  }

  /// Загрузить все коктейли из Hive
  ///
  /// **Возвращает:**
  /// - Список коктейлей если кэш есть
  /// - Пустой список если кэш пустой (первый запуск)
  ///
  /// **Время выполнения:** < 100 ms (мгновенно)
  /// **Работает:** offline (не требует интернета)
  List<Cocktail> loadAll() {
    // Box может быть не открыт (HiveService.init ещё не завершился или упал).
    // Поднимать исключение в UI незачем — считаем, что кэша нет.
    if (!Hive.isBoxOpen(_boxName)) return const [];

    final box = Hive.box(_boxName);
    final cocktails = <Cocktail>[];

    print('📂 CocktailCache.loadAll: box has ${box.length} entries');
    print('📂 CocktailCache.loadAll: keys = ${box.keys.toList()}');

    // Проходим по всем ключам в box
    for (final key in box.keys) {
      // Пропускаем служебные ключи
      if (key == _lastUpdatedKey) {
        final lastUpdated = box.get(key) as String?;
        print('📂 CocktailCache.loadAll: last_updated = $lastUpdated');
        continue;
      }

      final data = box.get(key);
      if (data is Map) {
        // Конвертируем Map<dynamic, dynamic> → Map<String, dynamic>
        final jsonMap = Map<String, dynamic>.from(data);
        cocktails.add(Cocktail.fromJson(jsonMap));
      }
    }

    print('📂 CocktailCache: loaded ${cocktails.length} cocktails from Hive');
    return cocktails;
  }

  /// Получить дату последнего обновления кэша
  ///
  /// **Возвращает:**
  /// - DateTime когда обновляли кэш
  /// - null если кэш никогда не обновляли
  DateTime? getLastUpdated() {
    // Проверяем открыт ли box
    if (!Hive.isBoxOpen(_boxName)) return null;

    final box = Hive.box(_boxName);
    final isoString = box.get(_lastUpdatedKey) as String?;

    if (isoString == null) return null;

    return DateTime.parse(isoString);
  }

  /// Проверить требует ли кэш обновления
  ///
  /// **Возвращает:**
  /// - `true` если кэш старше 7 дней или отсутствует
  /// - `false` если кэш свежий (< 7 дней)
  ///
  /// **Логика:**
  /// - Если кэша нет → true (надо загрузить)
  /// - Если кэш > 7 дней → true (надо обновить)
  /// - Если кэш < 7 дней → false (можно использовать)
  bool isStale() {
    final lastUpdated = getLastUpdated();

    // Нет кэша = stale
    if (lastUpdated == null) return true;

    // Проверяем возраст
    final age = DateTime.now().difference(lastUpdated);
    return age > _maxCacheAge;
  }

  /// Проверить доступен ли offline mode
  ///
  /// **Возвращает:**
  /// - `true` если в Hive есть коктейли (можно работать offline)
  /// - `false` если кэш пустой (нужен интернет для первой загрузки)
  bool get isOfflineAvailable {
    return loadAll().isNotEmpty;
  }

  /// Очистить кэш вручную
  ///
  /// **Когда использовать:**
  /// - User хочет обновить базу принудительно
  /// - Кэш corrupted
  /// - Debug/testing
  Future<void> clear() async {
    final box = await Hive.openBox(_boxName);
    await box.clear();
    print('🗑️ CocktailCache: cleared');
  }

  /// Получить размер кэша (количество коктейлей)
  ///
  /// **Возвращает:**
  /// - Количество сохраненных коктейлей
  int get size {
    if (!Hive.isBoxOpen(_boxName)) return 0;

    final box = Hive.box(_boxName);
    // Вычитаем 1 если есть lastUpdated ключ
    final hasLastUpdated = box.containsKey(_lastUpdatedKey);
    return box.length - (hasLastUpdated ? 1 : 0);
  }
}
