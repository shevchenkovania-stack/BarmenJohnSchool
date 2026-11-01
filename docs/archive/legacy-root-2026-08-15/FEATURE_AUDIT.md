# 📋 Полный аудит функционала Cocktail Bar Manager

> **Дата:** Август 2026  
> **Цель:** Определить что оставить, что спрятать, что удалить для ребрендинга в "Школу бармена"  
> **Всего файлов:** 87 | **Экранных файлов:** 34 | **Общий объём:** ~35,000+ строк кода

---

## 🧭 НАВИГАЦИЯ (Bottom Navigation — 5 вкладок)

```
┌──────┬────────┬────────────┬──────────┬──────┐
│ Home │ Search │ Конструктор│Favorites │ Бар  │
└──────┴────────┴────────────┴──────────┴──────┘
```

**Файл:** `lib/shell/main_shell.dart` (95 строк)  
**Структура:** IndexedStack — все 5 экранов всегда в памяти

---

## 📱 ВКЛАДКА 1: HOME (Главная)

**Файл:** `lib/features/home/view/home_screen.dart` (1240 строк)  
**ViewModel:** `lib/features/home/home_viewmodel.dart` (133 строки)

### Что показывает:
1. **Hero Header** — логотип "COCKTAILS" + кнопка "Школа" (переход в School)
2. **AI Блок** — "Создай свой коктейль" → открывает CocktailBuilderScreen
3. **Random Cocktail Hero Card** — случайный коктейль с большой картинкой (360px), категорией, типом
   - Кнопка "Посмотреть рецепт" → CocktailDetailScreen
   - Кнопка "Обновить" (refresh) — новый случайный коктейль
4. **"Browse All" кнопка** — переход в CocktailListScreen

### Состояния:
- Нет кэша → placeholder с кнопкой "Скачать базу"
- Загрузка → skeleton (shimmer эффект)
- Ошибка → карточка с retry
- Есть коктейль → hero card

### Оценка для школы:
| Элемент | Релевантность | Комментарий |
|---------|--------------|-------------|
| AI Блок | 🟡 Средняя | Можно переименовать в "Практика" |
| Random Cocktail | 🟢 Высокая | "Коктейль дня" — учебный элемент |
| Школа кнопка | 🟢 Критичная | Должна быть ГЛАВНОЙ кнопкой |
| Hero Header | 🟡 Средняя | Переименовать в "Школа бармена" |

---

## 🔍 ВКЛАДКА 2: SEARCH (Поиск / Библиотека)

**Файл:** `lib/features/cocktail_list/view/cocktail_list_screen.dart` (301 строк)  
**ViewModel:** `lib/features/cocktail_list/cocktail_list_viewmodel.dart` (166 строк)

### Что показывает:
1. **Поисковая строка** — фильтрация по названию
2. **Filter Chips:**
   - 🍹 Безалкогольные (virgin mode — динамическое удаление алкоголя)
   - All / Easy (2-3) / Medium (4-5) / Hard (6+) — по сложности
3. **ListView** — все 426 коктейлей с картинками
4. **Offline баннер** — показывает когда нет интернета
5. **Fallback** — первая буква названия если нет картинки

### Дополнительно:
- Отсюда можно попасть на CocktailDetailScreen (тап на коктейль)
- Virgin mode: убирает алкоголь из любого коктейля, показывает только жизнеспособные версии

### Оценка для школы:
| Элемент | Релевантность | Комментарий |
|---------|--------------|-------------|
| Список коктейлей | 🟢 Высокая | "Библиотека рецептов" — учебник |
| Поиск | 🟢 Высокая | Быстрый доступ к рецепту |
| Virgin mode | 🟡 Средняя | Можно оставить как "безалкогольные версии" |
| Difficulty filter | 🟢 Высокая | Уровни сложности = уровни обучения |

---

## 🍸 ВКЛАДКА 3: КОНСТРУКТОР (Cocktail Builder)

**Файл:** `lib/features/cocktail_builder/view/cocktail_builder_screen.dart` (57 строк)  
**ViewModel:** `lib/features/cocktail_builder/viewmodel/cocktail_builder_viewmodel.dart` (607 строк)

### Экраны конструктора (3 экрана):

#### Экран 1: BuilderForm (526 строк)
- **Ингредиенты** — выбор из инвентаря + "добавить свой"
- **Стиль коктейля** — carousel с preset'ами (Classic, Sour, Fizz, Tropical, Strong, Creamy)
- **Помощник/Ручной режим** — toggle
- **Газированность** — toggle
- **Advanced settings** — method, glass, aroma, texture
- **AI Mode Toggle** — включает AI генерацию (проверяет интернет)
- **Balance/Intensity слайдеры** — только в AI режиме
- **CanMakeIndicator** — показывает сколько коктейлей можно сделать

#### Экран 2: VariantSelection (402 строки)
- Показывает 3 варианта коктейля после генерации
- Каждый вариант: название, описание, ингредиенты, метрики

#### Экран 3: ResultScreen (405 строк)
- Детальный просмотр одного варианта
- Полный рецепт, инструкция, ингредиенты
- Кнопка "Сохранить" (в избранное)
- Кнопка "Начать заново"

### Сервисы конструктора:
- `cocktail_matcher_service.dart` (381 строк) — подбор ингредиентов
- `cocktail_safety_service.dart` (704 строки) — проверка безопасности сочетаний
- `mixologist_ai_service.dart` (354 строки) — AI генерация (OpenAI API)
- `ai_enhancer_service.dart` (277 строк) — улучшение рецепта через AI
- `cocktail_algorithm.dart` (814 строк) — алгоритм генерации
- `ingredient_roles.dart` (502 строки) — роли ингредиентов

### Оценка для школы:
| Элемент | Релевантность | Комментарий |
|---------|--------------|-------------|
| Конструктор | 🟢 Высокая | "Создай свой коктейль" — практическое задание |
| AI генерация | 🟡 Средняя | Зависит от интернета, ключа |
| Safety check | 🟢 Высокая | Обучение правильным сочетаниям |
| Style presets | 🟢 Высокая | Изучение стилей коктейлей |
| Sliders | 🟡 Средняя | Понимание баланса вкуса |

---

## ❤️ ВКЛАДКА 4: FAVORITES (Избранное)

**Файл:** `lib/features/favorites/view/favorites_screen.dart` (449 строк)

### Что показывает:
1. **Коктейли из API** — список избранных коктейлей (❤️ кнопка в деталях)
2. **🎨 Мои рецепты** — AI-сгенерированные коктейли из конструктора
3. **Empty state** — подсказка когда пусто

### Хранение:
- SharedPreferences (локально, offline)
- Два типа: обычные Cocktail + GeneratedCocktail (AI)

### Оценка для школы:
| Элемент | Релевантность | Комментарий |
|---------|--------------|-------------|
| Избранное | 🟢 Высокая | "Мои любимые рецепты" |
| AI рецепты | 🟢 Высокая | "Мои авторские коктейли" |

---

## 🏪 ВКЛАДКА 5: BAR MANAGER (Управление баром)

**Файл:** `lib/features/bar_manager/bar_manager_screen.dart` (165 строк)

### 5 карточек-кнопок:

#### 1. 📦 Инвентарь (InventoryScreen — 469 строк)
**Файл:** `lib/features/bar_manager/inventory/view/inventory_screen.dart`

- **2 вкладки:** Каталог (из API) + Свои (вручную)
- **Сетка ингредиентов** с картинками
- **Тап = добавить/убрать** из инвентаря (зелёный = есть)
- **Поиск** по названию
- **Фильтр "In Stock"** — показать только имеющиеся
- **Счётчик** "In Stock: N"
- Хранение: Hive (локально)

**Для школы:** 🟡 Можно адаптировать как "Мой бар" — что у меня есть из ингредиентов

---

#### 2. 🍹 Могу приготовить (CanMakeScreen — 340 строк)
**Файл:** `lib/features/bar_manager/can_make/view/can_make_screen.dart`

- **Поиск** по названию коктейля
- **Фильтрация:** показывает только коктейли которые можно сделать из текущего инвентаря
- **Учитывает стоп-лист** (исключает коктейли с отсутствующими ингредиентами)
- **Offline fallback:** если memory cache пуст → загружает из Hive
- **CocktailWithAvailability** — показывает какие ингредиенты есть/нет

**Для школы:** 🟢 "Что могу приготовить" — практика с тем что есть

---

#### 3. 📖 Мои рецепты (CustomRecipesScreen — 158 строк)
**Файл:** `lib/features/bar_manager/custom_recipes/view/custom_recipes_screen.dart`

- **Список авторских рецептов** (не из API)
- **FAB → Add/Edit** рецепт (524 строки)
- **Свайп/кнопка удаления**
- **Рецепт:** название, ингредиенты, инструкция, заметки
- Хранение: Hive (CustomRecipeRepository)

**Для школы:** 🟢 "Мои авторские рецепты" — студент создаёт свои

---

#### 4. ✨ Конструктор (CocktailBuilderScreen)
- Дублирует вкладку 3 (Конструктор) — тот же экран

**Для школы:** 🟡 Убрать дубликат, оставить только в основной навигации

---

#### 5. 📱 Цифровое меню / Киоск (KioskSetupScreen — 593 строки)
**Файл:** `lib/features/guest_mode/view/kiosk_setup_screen.dart`

- **Настройка:** название заведения, валюта
- **Выбор коктейлей** из избранного + установка цен
- **Запуск Kiosk** → GuestModeScreen (immersive fullscreen)
- **GuestModeScreen** (810 строк):
  - 2-column grid коктейлей с фото
  - Фильтры: All / Alcoholic / Non-Alcoholic
  - Тап → modal bottom sheet с деталями + цена
  - Immersive sticky mode (нет system bars)
  - Exit → confirmation dialog

**Для школы:** ❌ НЕ РЕЛЕВАНТНО — для баров, не для обучения

---

## 🎓 ШКОЛА БАРМЕНА (Bartender School)

**Файлов:** 17 | **Строк:** ~10,000+  
**Доступ:** кнопка на Home screen → SchoolHomeScreen

### Структура школы:

#### 🏠 School Home (school_home_screen.dart — 911 строк)
- **Header** с названием "Bartender School"
- **User Stats** — XP, уровень, streak, прогресс
- **Level Cards** — 3 уровня (Level 1, 2, 3)
- **Quick Access:**
  - 📖 Глоссарий
  - 🏆 Достижения
  - 🎓 Сертификаты
  - 🃏 Flip Cards
  - 📚 Библиотека коктейлей

---

#### 📚 Уровни обучения:

**Level 1** (level1_screen.dart — 214 строк)
- Список уроков для начинающих
- 12 уроков (A, B, C... L)

**Level 2** (level2_screen.dart — 199 строк)
- Продвинутые уроки
- 6 уроков

**Level 3** (level3_screen.dart — 199 строк)
- Мастерские уроки
- 6 уроков

---

#### 📖 Урок (lesson_screen.dart — 4355 строк!)
- **PageView** — слайды урока (swipe)
- **Термины** — глоссарий урока (modal bottom sheet)
- **Навигация:** вперёд/назад, прогресс бар
- **После последнего слайда** → автоматический переход к Quiz
- **Огромный контент** — 4355 строк с hardcoded уроками

---

#### 📝 Quiz (quiz_screen.dart — 1177 строк)
- **5 случайных вопросов** из пула урока
- **Типы вопросов:**
  - Single choice (один ответ)
  - Multiple choice (несколько ответов)
  - Slider questions (передвижной ползунок)
- **Счёт** — правильные/неправильные
- **Результат** — XP за правильный ответ
- **Прогресс** — сохраняется в ProgressService

---

#### 🏆 Достижения (achievements_screen.dart — 463 строки)
- **4 категории:**
  - 🥉 Уровни (завершить Level 1/2/3)
  - 🍸 Коктейли (просмотреть N коктейлей)
  - 🔥 Серии (N дней подряд)
  - ⭐ Особые (первый quiz, perfect score, etc.)
- **Прогресс** — прогресс бар для каждого
- **Unlocked/Locked** — визуальная индикация

---

#### 🎓 Сертификаты/Дипломы (certificates_screen.dart — 1175 строк!)
- **3 уровня дипломов:**
  - 🌱 Level I — APPRENTICE (бронза)
  - 🍸 Level II — PROFESSIONAL (серебро)
  - 🏆 Level III — MASTER (золото)
- **Красивые дипломы** с градиентами, рамками, Google Fonts
- **Детальный просмотр** — полноэкранный диплом
- **Условие получения** — завершить все уроки уровня

---

#### 📖 Глоссарий (glossary_screen.dart — 402 строки)
- **4 категории:**
  - Методы (Build, Shake, Stir, Dry Shake, Muddle, Double Strain)
  - Ингредиенты (ABV, Dash, Bitters, Syrup, Spirit, Liqueur, Garnish, Saline, Float)
  - Посуда (Jigger, Shaker, Strainer, Mixing Glass, Bar Spoon, etc.)
  - Техники
- **Поиск** по терминам
- **Фильтр** по категории

---

#### 🃏 Flip Cards (flip_card_screen.dart — 992 строки)
- **Карточки для запоминания** — flip анимация
- **Лицевая сторона** — термин/вопрос
- **Обратная сторона** — определение/ответ
- **Глоссарий урока** — показывает термины текущего урока
- **Навигация** — следующая/предыдущая карточка

---

## 🤖 AI ФУНКЦИИ

### 1. AI Recipe Viewer (Мастер-класс)
**Файл:** `lib/features/ai_recipes/view/ai_recipe_viewer.dart` (1237 строк)

- **Доступ:** кнопка "🎓 Мастер-класс" на CocktailDetailScreen
- **Режимы:** Expert (единственный активный)
- **Кэширование:** загружает из SavedRecipeService если есть
- **Генерация:** OpenAI API (нужен интернет + ключ)
- **Печать:** экспорт в PDF через Printing package
- **Сохранение:** можно сохранить в библиотеку
- **Offline check:** показывает dialog если нет интернета

**AI Prompt включает:**
- История коктейля
- Профессиональные техники
- Сенсорные подсказки (видишь, слышишь, чувствуешь, нюхаешь)
- Тайминг и ритм
- Ошибки которые никто не говорит
- Скрытые трюки

### 2. Cocktail Builder AI Mode
**Файлы:** `mixologist_ai_service.dart`, `ai_enhancer_service.dart`

- **Toggle** в конструкторе (проверяет интернет)
- **Balance/Intensity** слайдеры влияют на генерацию
- **Fallback ключ** — захардкожен для тестов
- **3 варианта** генерации на выбор

### 3. Saved Recipes
**Файл:** `lib/features/ai_recipes/view/saved_recipes_page.dart` (205 строк)
- Библиотека сохранённых AI рецептов
- Навигация из AiRecipeViewer

---

## ⚙️ НАСТРОЙКИ (Settings)

**Файл:** `lib/features/settings/view/settings_screen.dart` (649 строк)

### Секции:

1. **Язык** — Radio buttons:
   - 🇷🇺 Русский
   - 🇬🇧 English
   - 🇷🇴 Română

2. **AI Функции:**
   - API Key — ввод ключа OpenAI
   - Сохранение в ApiKeyService

3. **Единицы измерения:**
   - Метрическая (ml) / Имперская (oz)
   - Toggle switch

4. **Калькулятор:**
   - "Цены на ингредиенты" → BottlePricesScreen

5. **База рецептов:**
   - "Загрузить базу" — скачивает 426 коктейлей с API
   - Сохраняет в Hive + пре-загружает миниатюры
   - Показывает прогресс (2 dialog'а)

---

## 💰 КАЛЬКУЛЯТОР СЕБЕСТОИМОСТИ

### 1. Цены на бутылки (bottle_prices_screen.dart — 493 строки)
**Файл:** `lib/features/cost_calculator/view/bottle_prices_screen.dart`

- Загрузка ингредиентов из API
- Добавление: ингредиент + цена бутылки + объём
- Расчёт цены за 1 ml
- Хранение: CostCalculatorService

### 2. Калькулятор коктейля (cocktail_cost_calculator.dart — 489 строк)
**Файл:** `lib/features/cost_calculator/widgets/cocktail_cost_calculator.dart`

- Встраивается в CocktailDetailScreen
- Считает себестоимость порции
- Множитель порций (1, 2, 3...)
- Рекомендуемая цена (наценка 200%)
- Показывает недостающие цены

### 3. Прайс-лист (price_book_screen.dart — 603 строки)
**Файл:** `lib/features/bar_manager/price_book/view/price_book_screen.dart`

- CRUD для цен ингредиентов
- Moldova Catalog shortcut (🇲🇩) — предзаполненные цены
- Цена за 1 ml автоматически

---

## 📋 МЕНЮ И QR

### 1. Menu Builder (menu_builder_screen.dart — 482 строки)
**Файл:** `lib/features/menu_builder/view/menu_builder_screen.dart`

- Ввод названия заведения
- Выбор коктейлей из избранного
- Установка цен
- Выбор темы PDF (Classic / Modern / Minimal)
- Предпросмотр PDF
- Печать / сохранение PDF

### 2. QR Menu (qr_menu_screen.dart — 353 строки)
**Файл:** `lib/features/qr_menu/view/qr_menu_screen.dart`

- Локальный HTTP сервер
- Генерация QR кода
- Гости сканируют → видят HTML меню в браузере
- Статусы: starting / running / noNetwork

### 3. PDF Service (menu_pdf_service.dart — 476 строк)
**Файл:** `lib/features/menu_builder/service/menu_pdf_service.dart`

- Генерация PDF меню
- 3 темы оформления
- Картинки коктейлей

### 4. HTML Menu Builder (html_menu_builder.dart — 144 строки)
**Файл:** `lib/features/qr_menu/service/html_menu_builder.dart`

- HTML для QR меню
- Адаптивный дизайн

---

## ☕ COFFEE (Мусор?)

### 1. Coffee List (coffee_list_screen.dart — 207 строк)
**Файл:** `lib/features/coffee_list/view/coffee_list_screen.dart`

- **Старый код** — использует `repozitories` (не `repositories`)
- Список кофе с поиском
- Скролл к выбранному

### 2. Coffee Single (coffee_single_screen.dart — 108 строк)
**Файл:** `lib/features/coffee_single/view/coffee_single_screen.dart`

- Детальный просмотр кофе

---

## 🌐 ЛОКАЛИЗАЦИЯ

**Файлы:** `lib/l10n/app_en.arb`, `app_ro.arb`, `app_ru.arb`  
**Языки:** English, Romanian, Russian

### Что локализовано:
- Все tab labels
- Все экраны bar manager
- Search, Favorites, Settings
- Home screen
- Cocktail list
- Kiosk/Guest mode

### Что НЕ локализовано (hardcoded русский):
- Bartender School (все экраны)
- Cocktail Builder (все экраны)
- AI Recipe Viewer
- Glossary
- Certificates
- Achievements
- Cost Calculator
- Menu Builder

---

## 📊 СВОДНАЯ ТАБЛИЦА

| # | Фича | Файлов | Строк | Для школы | Решение |
|---|------|--------|-------|-----------|---------|
| 1 | **Bartender School** | 17 | ~10,000 | 🟢 ОСНОВНОЕ | ✅ ОСТАВИТЬ — ядро |
| 2 | **База коктейлей** | 5 | ~1,500 | 🟢 Учебник | ✅ ОСТАВИТЬ — "Библиотека" |
| 3 | **Поиск/фильтры** | 3 | ~550 | 🟢 Навигация | ✅ ОСТАВИТЬ |
| 4 | **Конструктор** | 15 | ~5,500 | 🟢 Практика | ✅ ОСТАВИТЬ — "Лаборатория" |
| 5 | **AI (Мастер-класс)** | 4 | ~2,000 | 🟡 AI-ментор | ✅ ОСТАВИТЬ — offline-first |
| 6 | **Избранное** | 2 | ~650 | 🟢 Прогресс | ✅ ОСТАВИТЬ |
| 7 | **Инвентарь** | 3 | ~700 | 🟡 "Мой бар" | 🟡 АДАПТИРОВАТЬ |
| 8 | **Can Make Now** | 3 | ~550 | 🟢 Практика | ✅ ОСТАВИТЬ |
| 9 | **Мои рецепты** | 2 | ~700 | 🟢 Творчество | ✅ ОСТАВИТЬ |
| 10 | **Стоп-лист** | 1 | 114 | 🟡 Для бара | 🔴 СПРЯТАТЬ |
| 11 | **Калькулятор** | 3 | ~1,500 | 🟡 Для бара | 🔴 СПРЯТАТЬ |
| 12 | **Прайс-лист** | 2 | ~950 | ❌ Для бара | 🔴 УБРАТЬ |
| 13 | **Menu Builder** | 2 | ~620 | ❌ Для бара | 🔴 УБРАТЬ |
| 14 | **QR Menu** | 3 | ~580 | ❌ Для бара | 🔴 УБРАТЬ |
| 15 | **Guest/Kiosk Mode** | 2 | ~1,400 | ❌ Для бара | 🔴 УБРАТЬ |
| 16 | **Coffee** | 3 | ~350 | ❌ Мусор | 🔴 УБРАТЬ |
| 17 | **Настройки** | 1 | 649 | 🟢 Базовые | ✅ ОСТАВИТЬ (упростить) |

---

## 🎯 РЕКОМЕНДАЦИИ

### ✅ ОСТАВИТЬ (ядро школы):
1. Bartender School (уроки, quiz, дипломы, достижения, глоссарий, flip cards)
2. База коктейлей → переименовать в "Библиотека"
3. Поиск + фильтры
4. Конструктор → переименовать в "Лаборатория"
5. AI Мастер-класс → "AI-Ментор" (offline-first)
6. Избранное → "Мои рецепты"
7. Can Make Now → "Практика"
8. Инвентарь → "Мой бар" (упростить)

### 🔴 УБРАТЬ (не для школы):
1. Coffee List / Coffee Single — мусор, старый код
2. QR Menu — для баров
3. HTML Menu Builder — для баров
4. PDF Menu Builder — для баров
5. Guest/Kiosk Mode — для баров
6. Price Book — для бухгалтерии
7. Stop List — для барменов

### 🟡 СПРЯТАТЬ (не удалять, но не показывать):
1. Cost Calculator — опционально для продвинутых
2. Bottle Prices — опционально

### 🔧 ПЕРЕИМЕНОВАТЬ:
| Было | Стало |
|------|-------|
| "База коктейлей" | "Библиотека рецептов" |
| "Конструктор" | "Лаборатория" |
| "AI Recipe Guide" | "AI-Ментор" |
| "Избранное" | "Мои рецепты" |
| "Bar Manager" | "Мой бар" |
| "Can Make Now" | "Что могу приготовить" |
| "Инвентарь" | "Мои ингредиенты" |

---

## 📁 СТРУКТУРА ФАЙЛОВ ПО МОДУЛЯМ

```
lib/
├── core/                          # Общие сервисы, модели, репозитории
│   ├── models/                    # Cocktail, CustomRecipe, etc.
│   ├── repositories/              # Hive + Memory cache
│   └── services/                  # AI, Cache, Settings, etc.
│
├── features/
│   ├── bartender_school/          # 🟢 ЯДРО ШКОЛЫ (17 файлов)
│   │   ├── data/                  # lesson_repository, progress_service, quiz_repository
│   │   ├── domain/entities/       # Lesson, Quiz, Progress
│   │   └── presentation/screens/  # 10 экранов школы
│   │
│   ├── cocktail_list/             # 🟢 БИБЛИОТЕКА (3 файла)
│   ├── cocktail_detail/           # 🟢 ДЕТАЛИ (3 файла)
│   ├── search/                    # 🟢 ПОИСК (2 файла)
│   ├── cocktail_builder/          # 🟢 ЛАБОРАТОРИЯ (15 файлов)
│   ├── ai_recipes/                # 🟢 AI-МЕНТОР (4 файла)
│   ├── favorites/                 # 🟢 ИЗБРАННОЕ (2 файла)
│   ├── home/                      # 🟢 ГЛАВНАЯ (2 файла)
│   │
│   ├── bar_manager/               # 🔴/🟡 БАР МЕНЕДЖЕР (10 файлов)
│   │   ├── inventory/             # 🟡 Адаптировать
│   │   ├── can_make/              # 🟢 Оставить
│   │   ├── custom_recipes/        # 🟢 Оставить
│   │   ├── stop_list/             # 🔴 Убрать
│   │   └── price_book/            # 🔴 Убрать
│   │
│   ├── cost_calculator/           # 🔴 Спрятать (2 файла)
│   ├── guest_mode/                # 🔴 Убрать (2 файла)
│   ├── menu_builder/              # 🔴 Убрать (2 файла)
│   ├── qr_menu/                   # 🔴 Убрать (3 файла)
│   ├── coffee_list/               # 🔴 Убрать (3 файла)
│   ├── coffee_single/             # 🔴 Убрать (2 файла)
│   └── settings/                  # 🟢 Оставить (1 файл)
│
├── shell/                         # Навигация (1 файл)
├── l10n/                          # Локализация (3 файла)
└── main.dart                      # Точка входа
```

---

## 🔥 PRIORITIES (для ребрендинга)

### P0 — Критично (сразу):
- [ ] Переименовать app → "Школа бармена"
- [ ] Сделать School Home ГЛАВНЫМ экраном (вместо текущего Home)
- [ ] Убрать Coffee, QR, Kiosk, Menu Builder из навигации
- [ ] Локализовать Bartender School (en, ro, ru)

### P1 — Важно (неделя 1-2):
- [ ] Рефактор Home screen — убрать лишнее, оставить школу
- [ ] Переименовать все табы и экраны
- [ ] AI-Ментор offline-first (rule-based fallback)
- [ ] Убрать/спрятать Bar Manager фичи

### P2 — Улучшения (неделя 3-4):
- [ ] Добавить больше уроков (сейчас ~24)
- [ ] Улучшить Flip Cards
- [ ] Добавить видео-демонстрации в уроки
- [ ] Progress sync между устройствами

### P3 — Будущее (месяц 2+):
- [ ] Community — студенты делятся рецептами
- [ ] Premium курсы (монетизация)
- [ ] Push notifications (daily lessons)
- [ ] Leaderboard (соревнование)
