import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:coin/core/models/cocktail.dart';

/// Сервис для пре-загрузки миниатюр коктейлей в кэш
///
/// Загружает все миниатюры при скачивании базы, чтобы они были доступны offline.
/// Миниатюры маленькие (100x100px), 426 штук займут ~10-20MB.
class ThumbnailPreloaderService {
  static const int _maxConcurrent = 5; // Максимум одновременных загрузок
  static const int _batchSize = 50; // Размер батча для прогресса

  /// Пре-загрузить все миниатюры в кэш
  ///
  /// [cocktails] - список коктейлей для загрузки
  /// [onProgress] - callback для отображения прогресса (0.0 - 1.0)
  Future<void> preloadAll({
    required List<Cocktail> cocktails,
    void Function(double progress, int loaded, int total)? onProgress,
  }) async {
    if (cocktails.isEmpty) {
      debugPrint('⚠️ ThumbnailPreloader: no cocktails to preload');
      return;
    }

    // Фильтруем только те у которых есть картинка
    final withThumbnails =
        cocktails.where((c) => c.strDrinkThumb.isNotEmpty).toList();

    if (withThumbnails.isEmpty) {
      debugPrint('⚠️ ThumbnailPreloader: no thumbnails to preload');
      return;
    }

    debugPrint(
        '🖼️ ThumbnailPreloader: starting preload of ${withThumbnails.length} thumbnails...');

    int loaded = 0;
    int failed = 0;
    final cacheManager = DefaultCacheManager();

    // Загружаем батчами для контроля прогресса
    for (var i = 0; i < withThumbnails.length; i += _batchSize) {
      final batch = withThumbnails.sublist(
        i,
        (i + _batchSize).clamp(0, withThumbnails.length),
      );

      // Загружаем батч параллельно с ограничением
      await Future.wait(
        batch.map((cocktail) async {
          try {
            await _preloadThumbnail(cacheManager, cocktail.strDrinkThumb);
            loaded++;
          } catch (e) {
            failed++;
            debugPrint('❌ ThumbnailPreloader: failed ${cocktail.strDrink}: $e');
          }
        }),
      );

      // Сообщаем прогресс
      onProgress?.call(
        loaded / withThumbnails.length,
        loaded,
        withThumbnails.length,
      );

      debugPrint(
          '🖼️ ThumbnailPreloader: batch done (${loaded}/${withThumbnails.length})');
    }

    debugPrint(
        '✅ ThumbnailPreloader: complete! Loaded: $loaded, Failed: $failed');
  }

  /// Пре-загрузить одну миниатюру в кэш
  Future<void> _preloadThumbnail(
    CacheManager cacheManager,
    String url,
  ) async {
    // Проверяем есть ли уже в кэше
    final fileInfo = await cacheManager.getFileFromCache(url);
    if (fileInfo != null) {
      return; // Уже в кэше
    }

    // Загружаем с сервера
    try {
      await cacheManager.getSingleFile(url);
    } catch (e) {
      debugPrint('❌ ThumbnailPreloader: failed to download $url: $e');
      rethrow;
    }
  }
}
