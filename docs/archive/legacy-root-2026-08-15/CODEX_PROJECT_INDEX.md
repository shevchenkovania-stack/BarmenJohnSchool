# Codex Project Index — Cocktail Bar Manager

Дата индексации: 2026-08-08  
Проект: `C:\WORK\FLUTTER\OWN_PROJECTS\coin`  
Текущая git-ветка при проверке: `simplify-cocktail-constructor`

## Кратко

Это Flutter-приложение `coin`, фактически не про крипту, а про коктейли и управление баром. Текущее продуктовое имя в документации: **Cocktail Bar Manager**.

Основная идея: offline-first каталог коктейлей на базе TheCocktailDB + барные инструменты:
- каталог рецептов и поиск;
- детали коктейля;
- избранное;
- инвентарь бара;
- стоп-лист;
- "Can Make Now" по имеющимся ингредиентам;
- калькулятор себестоимости и прайс-бук;
- конструктор меню и PDF;
- QR-меню через локальный HTTP-сервер;
- гостевой/kiosk mode;
- Cocktail Builder;
- Bartender School;
- AI/BYOK-надстройки для улучшения рецептов.

## Главная архитектура

Стек:
- Flutter / Dart SDK `^3.5.4`;
- Provider + ChangeNotifier;
- Hive / Hive Flutter для локальной базы;
- SharedPreferences для настроек и простых пользовательских данных;
- TheCocktailDB через Dio;
- cached_network_image + flutter_cache_manager;
- flutter_secure_storage для OpenAI/BYOK ключа;
- connectivity_plus;
- pdf / printing;
- qr_flutter + shelf для локального QR-меню;
- l10n через ARB: RU, EN, RO.

Слои:
- `lib/core/` — модели, репозитории, сервисы, тема, Hive;
- `lib/features/` — пользовательские модули;
- `lib/l10n/` — локализация;
- `lib/shell/main_shell.dart` — нижняя навигация;
- `lib/main.dart` — инициализация Hive, cache, SharedPreferences, Provider;
- `lib/coffee_list_app.dart` — `MaterialApp`, локализация, роутинг, тема.

## Точка входа

`lib/main.dart`:
- вызывает `WidgetsFlutterBinding.ensureInitialized()`;
- инициализирует `HiveService.init()`;
- получает `SharedPreferences`;
- создает `CocktailRepository` и `CocktailCacheService`;
- проверяет offline cache и connectivity;
- если кэш есть — грузит Hive в memory cache;
- если кэша нет и есть интернет — скачивает базу через API и сохраняет в Hive;
- запускает `CocktailAppWithLoading`;
- регистрирует основные Provider-ы.

`lib/coffee_list_app.dart`:
- создает `MaterialApp`;
- подключает `appTheme`;
- отключает системное масштабирование текста через `TextScaler.linear(1.0)`;
- подключает `AppLocalizations`;
- использует `MainShell` как home.

`lib/shell/main_shell.dart`:
- 5 табов: Home, Search, Constructor, Favorites, Bar;
- использует `IndexedStack`, чтобы сохранять состояние экранов.

## Основные модули

### Core

`lib/core/models/`
- `cocktail.dart` — основная модель коктейля;
- Hive-модели: inventory, stop list, custom recipes, menu builder, prices;
- `.g.dart` файлы сгенерированы Hive generator.

`lib/core/repositories/`
- `cocktail_repository.dart` — TheCocktailDB + memory cache + Hive fallback;
- `inventory_repository.dart` — инвентарь;
- `stop_list_repository.dart` — стоп-лист;
- `custom_recipe_repository.dart` — авторские рецепты;
- `menu_builder_repository.dart` — меню;
- `price_repository.dart` — цены.

`lib/core/services/`
- `cocktail_cache_service.dart` — Hive cache коктейлей;
- `favorites_service.dart` — избранное;
- `settings_service.dart` — язык/настройки;
- `api_key_service.dart` — OpenAI key в secure storage;
- `thumbnail_preloader_service.dart` — предзагрузка картинок;
- `virgin_cocktail_service.dart` и `virgin_analysis.dart` — безалкогольные версии;
- `cost_calculator_service.dart` — расчет себестоимости;
- `guest_menu_service.dart` — гостевое меню;
- `short_recipe_service.dart` — короткие рецепты;
- `recipe_ai_service.dart` — старый AI-сервис, еще используется в `ai_recipes` и `short_recipe_service`.

### Cocktail List / Detail

`lib/features/cocktail_list/`
- список коктейлей, поиск и фильтры;
- ViewModel: `cocktail_list_viewmodel.dart`;
- UI: `view/cocktail_list_screen.dart`, `widgets/cocktail_tile.dart`.

`lib/features/cocktail_detail/`
- экран деталей;
- short recipe widget;
- строки ингредиентов;
- интеграция с favorites, cost, virgin versions.

### Bar Manager

`lib/features/bar_manager/`
- `bar_manager_screen.dart` — hub;
- `inventory/` — список ингредиентов пользователя;
- `stop_list/` — недоступные ингредиенты;
- `can_make/` — какие коктейли можно приготовить;
- `price_book/` — цены бутылок;
- `custom_recipes/` — свои рецепты.

### Cocktail Builder

Текущая цель по `SESSION_MEMORY.md`: заменить дорогой OpenAI-first генератор на rule-based движок, а AI оставить опциональным BYOK-улучшением.

Ключевые файлы:
- `lib/features/cocktail_builder/services/cocktail_matcher_service.dart` — rule-based подбор коктейлей из кэша TheCocktailDB;
- `lib/features/cocktail_builder/viewmodel/cocktail_builder_viewmodel.dart` — состояние конструктора, выбор ингредиентов, варианты, AI toggle;
- `lib/features/cocktail_builder/services/ai_enhancer_service.dart` — опциональное улучшение найденного рецепта;
- `lib/features/cocktail_builder/services/cocktail_safety_service.dart` — blacklist/greylist/аллергены/ABV/сахар;
- `lib/features/cocktail_builder/view/cocktail_algorithm.dart` — метод приготовления, бокал, профиль, промптовая/алгоритмическая логика;
- `lib/features/cocktail_builder/view/cocktail_builder_screen.dart` — главный экран конструктора;
- `lib/features/cocktail_builder/view/screens/variant_selection_screen.dart`;
- `lib/features/cocktail_builder/view/screens/result_screen.dart`;
- `lib/features/cocktail_builder/view/screens/builder_form_screen.dart`.

Фактический поток:
1. Пользователь выбирает ингредиенты.
2. `CocktailMatcherService.match()` ищет совпадения в `CocktailRepository.getAllCached()`.
3. ViewModel показывает варианты.
4. Если AI включен и есть пользовательский ключ, `AiEnhancerService` улучшает детали рецепта.

### AI Recipes

`lib/features/ai_recipes/`
- `ai_recipe_viewer.dart`;
- `saved_recipes_page.dart`;
- модель `detailed_recipe.dart`.

Важно: старые AI-сервисы все еще живые. В коде найдены файлы с `sk-`-подобными строками:
- `lib/features/settings/view/settings_screen.dart`;
- `lib/features/cocktail_builder/viewmodel/cocktail_builder_viewmodel.dart`;
- `lib/core/services/recipe_ai_service.dart`;
- `lib/features/cocktail_builder/services/mixologist_ai_service.dart`.

Содержимое ключей здесь не зафиксировано намеренно. Нужно проверить и удалить реальные секреты из истории/репозитория.

### Bartender School

`lib/features/bartender_school/`
- domain entities: lesson, quiz, progress;
- data repositories/services: lesson repository, quiz repository, progress service;
- presentation screens: school home, levels 1-3, lesson, quiz, glossary, certificates, achievements, flip cards;
- JSON-контент в `data/content/`.

По документу `BARTENDER_SCHOOL_IMPLEMENTATION.md`:
- Level 1 создан на 12 уроков;
- quiz полностью есть только для lessons 1-4;
- Level 2/3 файлы и контент присутствуют, но полноту надо проверять отдельно;
- прогресс хранится в SharedPreferences.

### Guest / QR / Menu

`lib/features/guest_mode/`
- kiosk setup и guest mode.

`lib/features/qr_menu/`
- `qr_menu_screen.dart`;
- `qr_menu_server.dart`;
- `html_menu_builder.dart`.

`lib/features/menu_builder/`
- экран конструктора меню;
- PDF генерация через `menu_pdf_service.dart`.

### Legacy

Документация и код сходятся: есть старый учебный хвост:
- `lib/features/coffee_list/`;
- `lib/features/coffee_single/`;
- `lib/repozitories/` с опечаткой в имени;
- `lib/router/router.dart` все еще содержит routes для legacy coffee screen и bottle prices.

`APP_ANALYSIS.md` рекомендует удалить эти части, если цель — реальный Cocktail Bar Manager.

## Документация в корне

- `README.md` — маркетингово-техническое описание Cocktail Bar Manager.
- `SUMMARY.md` — сводка архитектуры, стек, модули, roadmap.
- `ROADMAP.md` — план v1.1/v2/v3+.
- `APP_ANALYSIS.md` — самый честный продуктовый анализ: что полезно, что мусор, что делать дальше.
- `COCKTAIL_BUILDER_SPEC.md` — техническое описание конструктора, модели, AI, safety, долги.
- `BARTENDER_SCHOOL_IMPLEMENTATION.md` — состояние модуля обучения.
- `SESSION_MEMORY.md` — актуальная память предыдущей сессии: переход на rule-based builder + BYOK enhancer.
- `CAREER_PLAN.md` — личный план роста дохода, не техническая документация проекта.
- `AGENTS.md` — инструкция для AI/разработчиков.

## Git-состояние при индексации

Рабочее дерево уже было грязным до создания этого файла.

Из `git status --short`:
- изменены: `README.md`, `lib/main.dart`, `lib/shell/main_shell.dart`, множество файлов в builder/list/detail/home/settings/bar_manager;
- удалены: `TESTING_GUIDE.md`, `test_openai.dart`, `test_output.txt`;
- новые: `AGENTS.md`, `APP_ANALYSIS.md`, `CAREER_PLAN.md`, `ROADMAP.md`, `SUMMARY.md`, `lib/constructor_engineering_analysis.md`, `thumbnail_preloader_service.dart`, `virgin_analysis.dart`, `virgin_cocktail_service.dart`;
- `.env` отслеживается git (`git ls-files .env` возвращает `.env`).

## Главные риски

1. `.env` находится под git tracking. Если там был реальный API key, нужно считать ключ скомпрометированным, удалить из истории и перевыпустить.
2. Старые AI-сервисы еще присутствуют и используются. Полный отказ от OpenAI не завершен.
3. В документации часть статуса оптимистична: `SUMMARY.md` говорит "готово к релизу", но `APP_ANALYSIS.md` указывает на крупный legacy/продуктовый шум.
4. `router.dart` все еще завязан на `coffee_*` legacy routes.
5. Нет явной тестовой базы: в `SUMMARY.md` указано `Тестов: TODO`; папка test в списке файлов не видна.
6. Локализация есть технически, но в UI еще много захардкоженного русского текста.
7. Много debug `print`/`debugPrint` в production-потоке.
8. `home_screen.dart` большой файл, часть UI стоит дробить.

## Рекомендуемое направление

Если цель — довести до полезного продукта/портфолио:
1. Зафиксировать стратегию: оставить "рецептурник + барные инструменты", не B2B SaaS прямо сейчас.
2. Срочно убрать секреты: `.env` из git, реальные ключи из кода и истории.
3. Завершить rule-based builder как основной бесплатный режим.
4. Оставить AI только как BYOK optional enhancer.
5. Удалить legacy `coffee_*`, `repozitories`, старый router.
6. Прогнать `flutter analyze`, затем закрыть реальные ошибки.
7. Добавить минимальные unit tests для matcher, cache/repository и safety.
8. Сделать polish pass по главному user flow: Home → Search → Detail → Favorites → Can Make → Builder.

## Команды

```powershell
flutter pub get
flutter analyze
flutter test
dart format lib
flutter build apk --release
```

