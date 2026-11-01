import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coin/core/services/settings_service.dart';
import 'package:coin/core/theme/app_theme.dart';
import 'package:coin/l10n/app_localizations.dart';
import 'package:coin/shell/main_shell.dart';
import 'package:coin/router/router.dart' as app_router;

/// Корневой виджет приложения.
///
/// Consumer<SettingsService> нужен чтобы MaterialApp реагировал на смену языка:
/// когда пользователь выбирает язык в Settings → SettingsService.setLocale() →
/// notifyListeners() → Consumer перестраивается → MaterialApp.locale обновляется →
/// весь интерфейс переключается на выбранный язык.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsService>(
      builder: (_, settings, __) {
        return MaterialApp(
          title: 'Школа бармена Джона',
          theme: appTheme,
          debugShowCheckedModeBanner: false,

          // ── Text Scaling Control ─────────────────────────────────────────
          // Масштаб шрифта из настроек пользователя.
          // Пользователь может выбрать размер в Settings → раздел "Шрифт".
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(settings.fontScale),
              ),
              child: child!,
            );
          },
          // ──────────────────────────────────────────────────────────────────

          // ── Локализация ────────────────────────────────────────────────────
          // Текущий язык из настроек пользователя
          locale: settings.locale,

          // Делегаты: AppLocalizations (наши ARB) + стандартные Flutter
          localizationsDelegates: AppLocalizations.localizationsDelegates,

          // Список поддерживаемых локалей — Flutter выберет ближайшую
          supportedLocales: AppLocalizations.supportedLocales,
          // ──────────────────────────────────────────────────────────────────

          // Роутер
          onGenerateRoute: (settings) {
            final generator = app_router.routes[settings.name];
            if (generator != null) {
              return MaterialPageRoute(
                  builder: (context) => generator(context));
            }
            return null;
          },

          home: const MainShell(),
        );
      },
    );
  }
}
