# Architecture

## Технологии

Проект написан на Flutter / Dart.

Ключевые зависимости из `pubspec.yaml`:

- `provider` - состояние через `ChangeNotifier`.
- `shared_preferences` - прогресс школы, настройки, имя для диплома, отметки практики.
- `hive_flutter` - локальные данные приложения: инвентарь, stop list, рецепты, кэш коктейлей.
- `dio`, `http` - сетевые запросы.
- `cached_network_image` - изображения коктейлей.
- `google_fonts` - оформление диплома.
- `flutter_localizations`, `intl` - локализация.
- `pdf`, `printing`, `qr_flutter`, `shelf` - старые/второстепенные функции меню и PDF.
- `openai_dart`, `flutter_secure_storage`, `connectivity_plus` - AI/ключи/онлайн-режим, не основной фокус первой версии.

Assets:

- `images/`
- `data/content/`

## Вход приложения

Файл: `lib/main.dart`

Порядок запуска:

1. `WidgetsFlutterBinding.ensureInitialized()`
2. `HiveService.init()`
3. `SharedPreferences.getInstance()`
4. Создание `CocktailRepository` и `CocktailCacheService`
5. Проверка offline-кэша коктейлей
6. При наличии кэша - загрузка в память
7. При отсутствии кэша и наличии интернета - загрузка базы коктейлей из API
8. Запуск `CocktailAppWithLoading`

## Provider-слой

Основной state management - `Provider` / `ChangeNotifierProvider`.

В `main.dart` регистрируются:

- `SharedPreferences`
- `CocktailRepository`
- `CocktailCacheService`
- `ThumbnailPreloaderService`
- `InventoryRepository`
- `StopListRepository`
- `CustomRecipeRepository`
- `MenuBuilderRepository`
- `PriceRepository`
- `FavoritesService`
- `SettingsService`
- `GuestMenuService`
- `SavedRecipeService`
- `CostCalculatorService`
- `ShortRecipeService`
- `MeasurementService`
- `ApiKeyService`
- `CocktailMatcherService`
- `CocktailBuilderViewModel`
- `HomeViewModel`
- `LessonRepository`
- `QuizRepository`
- `ProgressService`

Для школы особенно важны:

- `LessonRepository`
- `QuizRepository`
- `ProgressService`

## Главная оболочка

Файл: `lib/shell/main_shell.dart`

Используется `IndexedStack`, чтобы вкладки не пересоздавались при переключении.

Текущие вкладки:

- `HomeScreen` - главный экран школы.
- `CocktailListScreen` - библиотека рецептов.
- `WorkshopScreen` - Мастерская/практика.

Скрытые импорты в коде показывают исторические фичи:

- `CocktailBuilderScreen`
- `SchoolHomeScreen`
- `FavoritesScreen`
- `BarManagerScreen`

Их не нужно возвращать в первый экран без отдельного продуктового решения.

## Основные директории

- `lib/core/` - общие модели, репозитории, сервисы, тема.
- `lib/features/bartender_school/` - школа, уроки, прогресс, квизы, практика, диплом.
- `lib/features/cocktail_list/` - библиотека коктейлей.
- `lib/features/cocktail_builder/` - конструктор коктейлей, сейчас второстепенный.
- `lib/features/home/` - главный экран, сейчас переориентирован под школу.
- `lib/shell/` - нижняя навигация приложения.
- `data/content/` - JSON-контент уроков и квизов.
- `images/` - аватары Джона, иконка приложения, тематические картинки уроков.
- `test/bartender_school/level1/` - тесты первого уровня.

## Локальность и автономность

Текущий курс и прогресс могут работать локально:

- уроки и квизы лежат в `data/content/`;
- прогресс хранится в `SharedPreferences`;
- практика хранится в `SharedPreferences`;
- изображения Джона и уроков лежат в `images/`.

Риск автономности:

- библиотека коктейлей может зависеть от первичной загрузки API, если кэш пуст;
- AI-функции не должны быть обязательными для прохождения первой версии школы.

## Где смотреть при поломке

Если не грузятся уроки:

- `pubspec.yaml` -> assets `data/content/`
- `lib/features/bartender_school/data/lesson_repository.dart`
- `data/content/lessons_*.json`

Если не грузятся квизы:

- `lib/features/bartender_school/data/quiz_repository.dart`
- `data/content/quizzes_*.json`

Если не сохраняется прогресс:

- `lib/features/bartender_school/data/progress_service.dart`
- ключ `bartender_school_progress` в `SharedPreferences`

Если сломалась навигация:

- `lib/shell/main_shell.dart`
- `lib/features/home/view/home_screen.dart`

Если сломался внешний вид школы:

- `lib/core/theme/app_theme.dart`
- `lib/features/bartender_school/presentation/widgets/lesson_card.dart`
- `lib/features/bartender_school/presentation/screens/flip_card_screen.dart`
