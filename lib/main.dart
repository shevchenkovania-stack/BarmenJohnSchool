import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:coin/coffee_list_app.dart';
import 'package:coin/core/db/hive_service.dart';
import 'package:coin/core/repositories/cocktail_repository.dart';
import 'package:coin/core/repositories/inventory_repository.dart';
import 'package:coin/core/repositories/stop_list_repository.dart';
import 'package:coin/core/repositories/custom_recipe_repository.dart';
import 'package:coin/core/repositories/menu_builder_repository.dart';
import 'package:coin/core/repositories/price_repository.dart';
import 'package:coin/core/services/favorites_service.dart';
import 'package:coin/core/services/guest_menu_service.dart';
import 'package:coin/core/services/settings_service.dart';
import 'package:coin/core/services/saved_recipe_service.dart';
import 'package:coin/core/services/cost_calculator_service.dart';
import 'package:coin/core/services/short_recipe_service.dart';
import 'package:coin/core/services/measurement_service.dart';
import 'package:coin/core/services/api_key_service.dart';
import 'package:coin/core/services/cocktail_cache_service.dart';
import 'package:coin/core/services/thumbnail_preloader_service.dart';
import 'package:coin/features/cocktail_builder/services/cocktail_matcher_service.dart';
import 'package:coin/features/cocktail_builder/viewmodel/cocktail_builder_viewmodel.dart';
import 'package:coin/features/home/home_viewmodel.dart';
import 'package:coin/features/bartender_school/data/lesson_repository.dart';
import 'package:coin/features/bartender_school/data/quiz_repository.dart';
import 'package:coin/features/bartender_school/data/progress_service.dart';
import 'package:coin/features/bartender_school/data/daily_quest_service.dart';

/// Точка входа в приложение.
///
/// Порядок инициализации:
///   1. Flutter binding (обязательно до любых плагинов)
///   2. Hive (локальная БД — инвентарь, стоп-лист, рецепты)
///   3. SharedPreferences (избранное, настройки языка)
///   4. MultiProvider — внедряем все сервисы и репозитории в дерево виджетов
///
/// Дерево Provider-ов:
///   CocktailRepository       — API + кэш (один на всё приложение)
///   InventoryRepository      — Hive, ChangeNotifier
///   StopListRepository       — Hive, ChangeNotifier
///   CustomRecipeRepository   — Hive, ChangeNotifier
///   FavoritesService         — SharedPreferences, ChangeNotifier
///   SettingsService          — SharedPreferences (язык), ChangeNotifier
///   GuestMenuService         — SharedPreferences, kiosk config, ChangeNotifier
///   HomeViewModel            — случайный коктейль для главного экрана
void main() async {
  print('🚀 [MAIN] Starting app...');

  // Необходимо вызвать до использования Flutter-плагинов
  WidgetsFlutterBinding.ensureInitialized();
  print('✅ [MAIN] WidgetsFlutterBinding initialized');

  // Инициализируем Hive — открывает все ящики (inventory, stop_list, recipes)
  await HiveService.init();
  print('✅ [MAIN] HiveService initialized');

  // SharedPreferences нужен FavoritesService и SettingsService
  final prefs = await SharedPreferences.getInstance();
  print('✅ [MAIN] SharedPreferences initialized');

  // Создаём CocktailRepository заранее
  final cocktailRepo = CocktailRepository();
  final cacheService = CocktailCacheService();
  print('✅ [MAIN] Repository and CacheService created');

  // Проверяем есть ли offline кэш
  final hasOfflineCache = cacheService.isOfflineAvailable;
  print('📦 [MAIN] Offline cache available: $hasOfflineCache');

  // Проверяем интернет подключение
  try {
    final connectivityResult = await Connectivity().checkConnectivity();
    // checkConnectivity() возвращает List<ConnectivityResult>
    final hasInternet = connectivityResult.isNotEmpty &&
        !connectivityResult.contains(ConnectivityResult.none);
    if (hasInternet) {
      print('🌐 [MAIN] Internet: CONNECTED ✅ ($connectivityResult)');
    } else {
      print('🌐 [MAIN] Internet: OFFLINE ❌ ($connectivityResult)');
    }
  } catch (e) {
    print('🌐 [MAIN] Internet: UNKNOWN (error: $e)');
  }

  // 🔥 АВТОЗАГРУЗКА БАЗЫ ПРИ СТАРТЕ
  print('📦 [MAIN] Checking cache...');
  final cachedCocktails = cacheService.loadAll();

  if (cachedCocktails.isNotEmpty) {
    // Есть в Hive - загружаем в memory cache
    print('📦 [MAIN] Hive cache found: ${cachedCocktails.length} cocktails');
    print('📦 [MAIN] Loading into memory cache...');
    cocktailRepo.preloadFromHive();
    print('✅ [MAIN] Memory cache ready!');
  } else {
    // Нет в Hive - пробуем загрузить с API
    print('📦 [MAIN] No Hive cache, trying API...');
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final hasInternet = connectivityResult.isNotEmpty &&
          !connectivityResult.contains(ConnectivityResult.none);

      if (hasInternet) {
        print('📦 [MAIN] Downloading database from API...');
        final cocktails = await cocktailRepo.getAll();
        await cacheService.saveAll(cocktails);
        cocktailRepo.preloadFromHive(); // Загружаем в memory
        print('✅ [MAIN] Database downloaded: ${cocktails.length} cocktails');
        print('✅ [MAIN] Saved to Hive + Memory cache');
      } else {
        print('⚠️ [MAIN] No internet, no cache - user will need to download');
      }
    } catch (e) {
      print('❌ [MAIN] Failed to download database: $e');
    }
  }

  print('🚀 [MAIN] Calling runApp()...');
  runApp(
    CocktailAppWithLoading(
      cocktailRepo: cocktailRepo,
      cacheService: cacheService,
      prefs: prefs,
      hasOfflineCache: hasOfflineCache,
    ),
  );
}

/// Wrapper приложение с loading dialog
///
/// Показывает прогресс загрузки базы при первом запуске
class CocktailAppWithLoading extends StatefulWidget {
  final CocktailRepository cocktailRepo;
  final CocktailCacheService cacheService;
  final SharedPreferences prefs;
  final bool hasOfflineCache;

  const CocktailAppWithLoading({
    super.key,
    required this.cocktailRepo,
    required this.cacheService,
    required this.prefs,
    required this.hasOfflineCache,
  });

  @override
  State<CocktailAppWithLoading> createState() => _CocktailAppWithLoadingState();
}

class _CocktailAppWithLoadingState extends State<CocktailAppWithLoading> {
  @override
  void initState() {
    super.initState();
    print('🎨 [CocktailAppWithLoading] initState called');
  }

  @override
  Widget build(BuildContext context) {
    print('🎨 [CocktailAppWithLoading] build called');
    return MultiProvider(
      providers: [
        // SharedPreferences - нужен для ProgressService
        Provider<SharedPreferences>.value(value: widget.prefs),

        // Репозиторий API: обычный Provider (без ChangeNotifier, состояния нет)
        Provider<CocktailRepository>.value(value: widget.cocktailRepo),

        // CocktailCacheService: offline кэш (синглтон)
        Provider<CocktailCacheService>.value(value: widget.cacheService),

        // ThumbnailPreloaderService: пре-загрузка миниатюр
        Provider<ThumbnailPreloaderService>.value(
            value: ThumbnailPreloaderService()),

        // Репозитории Hive: ChangeNotifier — UI слушает изменения
        ChangeNotifierProvider<InventoryRepository>(
          create: (_) => InventoryRepository(),
        ),
        ChangeNotifierProvider<StopListRepository>(
          create: (_) => StopListRepository(),
        ),
        ChangeNotifierProvider<CustomRecipeRepository>(
          create: (_) => CustomRecipeRepository(),
        ),
        ChangeNotifierProvider<MenuBuilderRepository>(
          create: (_) => MenuBuilderRepository(),
        ),
        ChangeNotifierProvider<PriceRepository>(
          create: (_) => PriceRepository(),
        ),

        // Сервисы: используют SharedPreferences
        ChangeNotifierProvider<FavoritesService>(
          create: (_) => FavoritesService(widget.prefs),
        ),
        ChangeNotifierProvider<SettingsService>(
          create: (_) => SettingsService(widget.prefs),
        ),
        ChangeNotifierProvider<GuestMenuService>(
          create: (_) => GuestMenuService(widget.prefs),
        ),

        // AI recipe cache service
        ChangeNotifierProvider<SavedRecipeService>(
          create: (_) => SavedRecipeService(),
        ),

        // Cost Calculator Service
        ChangeNotifierProvider<CostCalculatorService>(
          create: (_) => CostCalculatorService()..loadPrices(),
        ),

        // Short Recipe Service - кэш коротких рецептов
        ChangeNotifierProvider<ShortRecipeService>(
          create: (_) => ShortRecipeService(),
        ),

        // Measurement Service - единицы измерения (ml/oz, g/oz)
        ChangeNotifierProvider<MeasurementService>(
          create: (_) => MeasurementService(widget.prefs),
        ),

        // API Key Service - безопасное хранение ключа OpenAI
        ChangeNotifierProvider<ApiKeyService>(
          create: (_) => ApiKeyService()..load(),
        ),

        // Cocktail Matcher Service - Rule-based подбор коктейлей
        Provider<CocktailMatcherService>(
          create: (ctx) => CocktailMatcherService(
            ctx.read<CocktailRepository>(),
          ),
        ),

        // Bartender School providers (must be before CocktailBuilderViewModel)
        ChangeNotifierProvider<LessonRepository>(
          create: (_) => LessonRepository()..loadCoreCurriculum()..loadWisdom(),
        ),
        ChangeNotifierProvider<QuizRepository>(
          create: (_) => QuizRepository()..loadQuizzes(),
        ),
        ChangeNotifierProvider<ProgressService>(
          create: (ctx) => ProgressService(
            ctx.read<SharedPreferences>(),
            lessonRepo: ctx.read<LessonRepository>(),
          ),
        ),
        ChangeNotifierProvider<DailyQuestService>(
          create: (ctx) => DailyQuestService(ctx.read<SharedPreferences>()),
        ),

        // Cocktail Builder ViewModel - конструктор коктейлей
        ChangeNotifierProvider<CocktailBuilderViewModel>(
          create: (ctx) => CocktailBuilderViewModel(
            matcher: ctx.read<CocktailMatcherService>(),
            inventory: ctx.read<InventoryRepository>(),
            apiKeyService: ctx.read<ApiKeyService>(),
            progressService: ctx.read<ProgressService>(),
          ),
        ),

        // HomeViewModel: загружает случайный коктейль из кэша (offline-first)
        ChangeNotifierProvider<HomeViewModel>(
          create: (ctx) => HomeViewModel(
            ctx.read<CocktailRepository>(),
            ctx.read<CocktailCacheService>(),
          ),
        ),
      ],
      child: const MyApp(),
    );
  }
}

