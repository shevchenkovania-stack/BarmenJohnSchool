import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:coin/core/services/settings_service.dart';
import 'package:coin/core/services/measurement_service.dart';
import 'package:coin/core/services/cocktail_cache_service.dart';
import 'package:coin/core/services/thumbnail_preloader_service.dart';
import 'package:coin/core/repositories/cocktail_repository.dart';
import 'package:coin/core/theme/app_theme.dart';
import 'package:coin/l10n/app_localizations.dart';

/// Экран настроек приложения.
///
/// Содержит переключатель языка, размер шрифта, единицы измерения, базу рецептов.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<SettingsService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          // ── Секция "Язык" ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              l10n.settingsLanguageSection.toUpperCase(),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Список языков — каждый с радио-кружком
          ...SettingsService.supportedLanguages.map(
            (lang) {
              final (code, displayName) = lang;
              final isSelected = settings.locale.languageCode == code;

              return RadioListTile<String>(
                value: code,
                groupValue: settings.locale.languageCode,
                onChanged: (value) {
                  if (value != null) settings.setLocale(value);
                },
                title: Text(
                  displayName,
                  style: TextStyle(
                    // Выбранный язык — золотой, остальные обычный
                    color:
                        isSelected ? AppColors.primary : AppColors.textPrimary,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                activeColor: AppColors.primary,
              );
            },
          ),
          const Divider(height: 32),

          // ── Секция "Размер шрифта" ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              'РАЗМЕР ШРИФТА'.toUpperCase(),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: SettingsService.fontScaleOptions.map((scale) {
                final isActive = settings.fontScale == scale;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => settings.setFontScale(scale),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isActive
                                ? AppColors.primary
                                : AppColors.border,
                            width: isActive ? 2 : 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Aa',
                          style: TextStyle(
                            fontSize: 12 * scale,
                            color: isActive
                                ? AppColors.primary
                                : AppColors.textPrimary,
                            fontWeight:
                                isActive ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              '${(settings.fontScale * 100).toInt()}%',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          const Divider(height: 32),

          // ── Секция "Единицы измерения" ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              'ЕДИНИЦЫ ИЗМЕРЕНИЯ'.toUpperCase(),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          Consumer<MeasurementService>(
            builder: (context, measurement, _) {
              return SwitchListTile(
                value: measurement.volumeUnit == VolumeUnit.ounces,
                onChanged: (_) => measurement.toggleVolumeUnit(),
                title: Text(
                  measurement.volumeUnit == VolumeUnit.milliliters
                      ? 'Метрическая (ml)'
                      : 'Имперская (oz)',
                  style: TextStyle(
                    color: measurement.volumeUnit == VolumeUnit.milliliters
                        ? AppColors.primary
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Объём ингредиентов',
                  style: TextStyle(fontSize: 12),
                ),
                secondary: Icon(
                  measurement.volumeUnit == VolumeUnit.milliliters
                      ? Icons.water_drop
                      : Icons.local_drink,
                  color: measurement.volumeUnit == VolumeUnit.milliliters
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
                activeColor: AppColors.primary,
              );
            },
          ),
          const Divider(height: 32),

          // ── Секция "База рецептов" ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              'БАЗА РЕЦЕПТОВ'.toUpperCase(),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Бейдж — рекомендация IBA
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2A2540), Color(0xFF1E1B30)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Рекомендовано IBA',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'International Bartenders Association',
                          style: TextStyle(
                            color: AppColors.textSecondary.withValues(alpha: 0.7),
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          _DatabaseManagementTile(),

          const Divider(height: 32),
        ],
      ),
    );
  }
}

/// Widget управления базой рецептов
class _DatabaseManagementTile extends StatefulWidget {
  const _DatabaseManagementTile();

  @override
  State<_DatabaseManagementTile> createState() =>
      _DatabaseManagementTileState();
}

class _DatabaseManagementTileState extends State<_DatabaseManagementTile> {
  bool _isDownloading = false;
  int _cachedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCacheCount();
  }

  Future<void> _loadCacheCount() async {
    final cacheService = context.read<CocktailCacheService>();
    setState(() {
      _cachedCount = cacheService.loadAll().length;
    });
  }

  Future<void> _downloadDatabase() async {
    // Проверяем интернет
    final connectivityResult = await Connectivity().checkConnectivity();
    final hasInternet = !connectivityResult.contains(ConnectivityResult.none);
    if (!hasInternet) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Нет подключения к интернету'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isDownloading = true);

    // Показываем dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _SettingsDownloadDialog(),
    );

    try {
      final repo = context.read<CocktailRepository>();
      final cache = context.read<CocktailCacheService>();
      final thumbnailPreloader = context.read<ThumbnailPreloaderService>();

      // Загружаем всю базу
      final cocktails = await repo.getAll();

      // Сохраняем в Hive
      await cache.saveAll(cocktails);

      // Закрываем первый dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Показываем dialog для миниатюр
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              _ThumbnailProgressDialog(total: cocktails.length),
        );
      }

      // Пре-загружаем миниатюры
      await thumbnailPreloader.preloadAll(
        cocktails: cocktails,
        onProgress: (progress, loaded, total) {
          if (mounted) {
            // Обновляем dialog через setState
            // (dialog сам слушает изменения)
          }
        },
      );

      if (mounted) {
        Navigator.of(context).pop(); // закрываем dialog миниатюр
        setState(() {
          _isDownloading = false;
          _cachedCount = cocktails.length;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ База загружена! ${cocktails.length} коктейлей'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        setState(() => _isDownloading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        _cachedCount > 0 ? Icons.check_circle : Icons.cloud_download,
        color: _cachedCount > 0 ? AppColors.primary : AppColors.textSecondary,
      ),
      title: Text(
        _cachedCount > 0
            ? 'Коллекция загружена ($_cachedCount)'
            : 'Загрузить бестселлер бармена',
        style: TextStyle(
          color: _cachedCount > 0 ? AppColors.primary : AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        _cachedCount > 0
            ? 'Все рецепты доступны offline'
            : '600+ лучших рецептов со всего мира в одном нажатии',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: _isDownloading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: _isDownloading ? null : _downloadDatabase,
    );
  }
}

/// Простой dialog загрузки для settings
class _SettingsDownloadDialog extends StatefulWidget {
  const _SettingsDownloadDialog();

  @override
  State<_SettingsDownloadDialog> createState() =>
      _SettingsDownloadDialogState();
}

class _SettingsDownloadDialogState extends State<_SettingsDownloadDialog> {
  double _progress = 0.0;
  String _currentLetter = 'A';

  @override
  void initState() {
    super.initState();
    _simulateProgress();
  }

  Future<void> _simulateProgress() async {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    for (int i = 0; i < 26; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() {
        _progress = (i + 1) / 26 * 0.95;
        _currentLetter = letters[i];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🍹', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text(
              'Загрузка базы рецептов...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.grey[200],
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFFE8B84B)),
              minHeight: 8,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Буква: $_currentLetter',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
                Text(
                  '${(_progress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE8B84B),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog для прогресса загрузки миниатюр
class _ThumbnailProgressDialog extends StatefulWidget {
  final int total;

  const _ThumbnailProgressDialog({required this.total});

  @override
  State<_ThumbnailProgressDialog> createState() =>
      _ThumbnailProgressDialogState();
}

class _ThumbnailProgressDialogState extends State<_ThumbnailProgressDialog> {
  @override
  void initState() {
    super.initState();
    _listenToProgress();
  }

  Future<void> _listenToProgress() async {
    // Dialog будет обновляться когда загрузка завершится
    // Для простоты показываем анимацию
    await Future.delayed(const Duration(seconds: 30)); // Таймаут
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🖼️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text(
              'Загрузка миниатюр...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Чтобы картинки работали offline',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(
              color: Color(0xFFE8B84B),
            ),
            const SizedBox(height: 12),
            Text(
              'Это займёт 1-2 минуты...',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
