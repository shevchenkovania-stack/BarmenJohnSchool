# 📋 План недоделок для релиза

> Дата сверки: 2026-08-15
> Статус: Level 1 готов к smoke-test, Level 2 требует доработки

---

## 🔴 P0 — Критично для релиза

> Полный проход по экранам и элементам — в [RELEASE_QA_CHECKLIST.md](RELEASE_QA_CHECKLIST.md).
> Критический аудит ревьюеров (дизайн, бармен, редактор, методист, продакт) —
> в [review/00_INDEX.md](review/00_INDEX.md).
> Ниже — то, что уже видно по коду и блокирует публикацию.

### 0.6 🔴 НЕ ИСПРАВЛЕНО: 17 слайдов мудрости рендерятся как обычная теория
**Файлы:** `data/content/lessons_wisdom.json` (`observation` ×7, `choice` ×6,
`silence` ×4) и `lib/features/bartender_school/domain/entities/lesson.dart`
(`SlideType.values.firstWhere(..., orElse: () => SlideType.theory)`).
**Проблема:** типов `observation`, `choice`, `silence` нет в `SlideType`, и они
молча схлопываются в `theory`. Интерактивная сцена «Три гостя» и «15 секунд
молчания» — просто текст.
**Что сделать:** либо реализовать типы с виджетами, либо переписать данные;
`orElse` должен писать в лог ошибку. Разбор — [review/04](review/04_LEARNING_LOGIC_AUDIT.md).

### 0.7 🔴 НЕ ИСПРАВЛЕНО: проходной балл квизов не определён в данных
**Файлы:** `data/content/quizzes_level1_part1.json` — у `lesson_A_01..A_04` и
`lesson_B_09` `passingScore` пустой, у `C_09..C_12` — пустой.
**Проблема:** проверка знаний зависит от неявной логики экрана, а не от данных.
**Что сделать:** заполнить `passingScore` (≈70 % от `questionsPerAttempt`) и
сверить с текстом экзамена (сейчас текст говорит «70 %», данные — 12/15).

### 0.8 🟠 НЕ ИСПРАВЛЕНО: ложные утверждения и антисанитария в контенте
**Файлы:** `quizzes_level1_part1.json`, `lessons_level1_part*.json`.
**Проблема:** «сок можно держать 3 дня», «соль делает слаще», «в 80 %/9 из 10
случаев», «90 % баров используют Boston shaker» — выдуманные числа и опасные
рекомендации; «долить 15 мл лимона» как исправление.
**Что сделать:** см. [review/02](02_HEAD_BARTENDER_REVIEW.md) — там по пунктам.

### 0.9 🔴 НЕ ИСПРАВЛЕНО: технические и редакционные тексты в уроках
**Файлы:** `data/content/lessons_level1_part2.json` (экзамен),
`certificates_screen.dart` (диплом).
**Проблема:** «В первой версии мастерская может быть rule-based»,
«Проходной порог берётся из конфигурации школы», «Будущий мастер-курс. В первом
релизе доступен…» — внутренние записки видны ученику.
**Что сделать:** см. [review/03](03_EDITORIAL_REVIEW.md).

### 0.10 🔴 НЕ ИСПРАВЛЕНО: `applicationId = com.example.coin`
**Файл:** `android/app/build.gradle`
**Проблема:** Google Play отклоняет пакеты в домене `com.example`. Сменить после первой
публикации невозможно.
**Что сделать:** задать постоянный id (например `md.shevchenco.barmenjohn`), проверить,
что он нигде не зашит в коде/настройках Hive/SharedPreferences.

### 0.2 🔒 НЕ ИСПРАВЛЕНО: release подписан debug-ключом
**Файл:** `android/app/build.gradle` — `buildTypes.release { signingConfig = signingConfigs.debug }`
**Что сделать:** создать keystore, `key.properties` (в `.gitignore`), подключить
`signingConfigs.release`, собрать `appbundle`, сохранить ключ в двух местах.

### 0.3 ⚠️ НЕ ПРОВЕРЕНО: шрифты Google Fonts грузятся из сети
**Проблема:** `google_fonts` по умолчанию скачивает шрифты при первом запуске. В
офлайне (а офлайн — обязательное требование продукта) фирменная типографика
подменяется системной.
**Что сделать:** либо зашить `.ttf` в `assets/fonts` и объявить их в `pubspec.yaml`
как статические families, либо проверить и принять деградацию (задокументировать).

### 0.4 ⚠️ НЕ ПРОВЕРЕНО: неполная локализация RU/RO
**Файлы:** `lib/l10n/app_en.arb` (168 ключей), `app_ru.arb` (140), `app_ro.arb` (143).
**Проблема:** на RU/RO часть срок может приходить из EN, часть — быть захардкожена
по-русски (`school_home`, `lesson_screen`, `quiz_screen` содержат русские строки в коде).
**Что сделать:** пройти `RELEASE_QA_CHECKLIST.md` в трёх локалях и либо добрать ключи,
либо объявить v1 только на русском (и скрыть остальные языки в настройках).

### 0.5 ⚠️ НЕ ПРОВЕРЕНО: AI-режим без user-ключа
**Проблема:** ключ OpenAI вводится пользователем в настройках и хранится в secure storage.
Нужно убедиться, что без ключа все связанные точки (AI-рецепты, перевод) деградируют
в rule-based и не показывают технические ошибки.
**Что сделать:** проход по `RELEASE_QA_CHECKLIST.md` → 1.10, а также решение, входит ли
AI в v1 вообще (если нет — скрыть вход, чтобы не собирать отзывы о недоделке).

### 0. 🔒 НЕ ИСПРАВЛЕНО: OpenAI-ключ остался в истории Git
**Файл:** `.env` (в `.gitignore`, из индекса выведен коммитом `3713172`)
**Проблема:** коммит `e38bc9a` содержит `.env` с реальным значением `OPENAI_API_KEY` и является предком `main` — то есть ключ виден любому, кто клонирует репозиторий с полной историей.
**Что сделать:**
1. Отозвать/перевыпустить ключ в панели OpenAI (он уже считается скомпрометированным, независимо от пуша).
2. Не пушить полную историю в публичные репозитории — только чистый снимок кода (одна история без старых коммитов) либо историю, вычищенную `git filter-repo --invert-paths --path .env`.
3. Убедиться, что в коде не осталось захардкоженных ключей: `git grep -nI "sk-"`.
**Команда проверки:**
```powershell
git log --all --oneline -- .env
git grep -nI "OPENAI_API_KEY" HEAD
```

### 1. ✅ ИСПРАВЛЕНО: Overflow на экране завершения квиза
**Файл:** `lib/features/bartender_school/presentation/screens/quiz_screen.dart`
**Проблема:** `_showCompletionDialog()` (строки 307-550+) использует `Column` без `SingleChildScrollView`. На маленьких экранах при системном увеличении шрифта — overflow.
**Решение:** Обернуть содержимое диалога в `SingleChildScrollView`. ✅ Выполнено.

### 2. ✅ ИСПРАВЛЕНО: Проверить все экраны на overflow
**Что проверено и исправлено:**
- ✅ `quiz_screen.dart` — `_showCompletionDialog()` обёрнут в `SingleChildScrollView`
- ✅ `practice_flow_screen.dart` — `_IntroStep` и `_ResultStep` обёрнуты в `SingleChildScrollView`
- ✅ `lesson_screen.dart` — уже использует `SingleChildScrollView` для слайдов
- ✅ `flip_card_screen.dart` — уже использует `SingleChildScrollView` для контента карточки
- ✅ `certificates_screen.dart` — уже использует `SingleChildScrollView`

**Команда для проверки:**
```powershell
flutter build apk --debug
# Установить на Mi A2 Lite (маленький экран) и проверить каждый экран
```

---

## 🟡 P1 — Нужно для Level 2

### 3. ✅ ИСПРАВЛЕНО: Practice challenges для блоков D и F
**Текущее состояние:**
- ✅ Блок A: 4 задания (balance, acid, sweet, bitter)
- ✅ Блок B: 4 задания (setup, jigger, shake, ice)
- ✅ Блок C: 6 заданий (Mojito, Daiquiri, Negroni, Boulevardier, Pisco Sour, Mai Tai)
- ✅ **Блок D: 4 задания (Manhattan, Amaretto Sour, Ramos Gin Fizz, Mint Julep)** — ДОБАВЛЕНО
- ✅ Блок E: 4 задания (Whiskey Sour, Old Fashioned, Dry Martini, Margarita)
- ✅ **Блок F: 4 задания (Espresso Martini, Aperol Spritz, Moscow Mule, Bloody Mary)** — ДОБАВЛЕНО

**Что сделано:**
1. Создан `challenges_block_d.dart` — 4 задания по темам D-блока (spec, substitution, texture, temperature)
2. Создан `challenges_block_f.dart` — 4 задания по темам F-блока (prep, guest brief, service rush, exam)
3. Добавлены в `practice_challenges.dart` → `allPracticeChallenges` (теперь 28 коктейлей)
4. Обновлён `workshop_screen.dart` → список блоков: `['A', 'B', 'C', 'D', 'E', 'F']`

**Примечание:** Level 2 полностью укомплектован практикой.

---

## 🟢 P2 — Визуальные улучшения

### 4. ✅ ИСПРАВЛЕНО: Icon sweep — замена Material icons на кастомные
**Текущее состояние:**
- ✅ Карточки уроков используют кастомные картинки (`lesson_*.png`)
- ✅ UI-иконки созданы: `ui_icon_*.png`
- ✅ Удалён дубликат `barista_john.png.png`
- ✅ Удалена папка `images/New folder` с неиспользуемыми файлами

**Результат:** Все картинки в `images/` используются, дубликатов нет.

### 5. ✅ ИСПРАВЛЕНО: Проверить использование картинок из `images/`
**Проверка завершена:**
- ✅ Все 24 урока имеют соответствующие картинки (`lesson_*.png`)
- ✅ Все картинки объявлены в `pubspec.yaml` через `images/`
- ✅ Дубликаты удалены
- ✅ Неиспользуемые файлы удалены

---

## 🔵 P3 — Технические задачи

### 6. ✅ ИСПРАВЛЕНО: Контентные исправления
**Что исправлено:**
- ✅ **Block A Old Fashioned**: Убран "Orange" как ингредиент с 1мл (это garnish, не ингредиент)
- ✅ **Block D**: Заменены дублирующиеся коктейли (Manhattan→Negroni, Amaretto Sour→Gimlet, Ramos Gin Fizz→Clover Club, Mint Julep→Hot Toddy)
- ✅ Проверена целостность всех квизов Level 1 и Level 2
- ✅ Проверена связь уроков с квизами

### 7. ✅ ИСПРАВЛЕНО (2026-10-25): Удалить `.env` из Git tracking
**Сделано:** `git rm --cached .env`, `.env` добавлен в `.gitignore`. Файл остался на диске.
**Всё ещё требует действия владельца:** ротация скомпрометированных ключей и очистка истории (`git filter-repo`) — история коммитов по-прежнему содержит `.env`.

### 7. Проверить legacy-код
**Что можно удалить после проверки зависимостей:**
- `lib/features/coffee_list/`
- `lib/features/coffee_single/`
- `lib/repozitories/` (с опечаткой)
- Старый `lib/router/router.dart`
- Пустые `cocktail_education` и `dashboard`
- Старые AI-сервисы

### 8. Production logging
**Проблема:** ~256 `print/debugPrint` в `lib/`
**Решение:** Упорядочить логирование, использовать `kDebugMode` для debug-only логов.

---

## ✅ Что уже сделано хорошо

- ✅ Level 1: 12 уроков, квизы, практика, диплом
- ✅ Level 2: 12 уроков, квизы, практика для блока E
- ✅ Мастерская: 5-шаговый flow, 3-звёздочная оценка
- ✅ Прогресс: XP, streak, достижения
- ✅ Offline-first: школа автономна без интернета
- ✅ Кастомные картинки для всех уроков (A-F)
- ✅ Кастомные UI-иконки для учебных экранов
- ✅ Бармен Джон как наставник (канонический голос)
- ✅ Пререквизиты уроков, пролог, briefing блоков
- ✅ Термины, glossary, mentor notes

---

## 📊 Статистика

| Категория | Количество |
|-----------|------------|
| Уроков Level 1 | 12 |
| Уроков Level 2 | 12 |
| Practice challenges (всего) | **28** |
| — Блок A | 7 (Margarita, Whiskey Sour, Tom Collins, Cosmopolitan, Old Fashioned, Last Word, Penicillin) |
| — Блок B | 4 |
| — Блок C | 6 |
| — Блок D | **4 (Negroni, Gimlet, Clover Club, Hot Toddy)** |
| — Блок E | 4 |
| — Блок F | 4 |
| Кастомных картинок | 36 (после удаления дубликатов) |
| UI-иконок | 8 |
| Квизов Level 1 | 12 |
| Квизов Level 2 | 12 |

---

## 🎯 Приоритетный план действий

### Шаг 0 — Закрыть найденное аудитом (P0, до любых полировок)

Пункты ниже идут раньше всего остального: это либо неправда в обучении,
либо пустой экран, либо блокер магазина. Разбор по пунктам —
[review/00_INDEX.md](review/00_INDEX.md).

1. `applicationId` и release-подпись (п. 0.10, 0.2).
2. Мудрость: реализовать `observation/choice/silence` или переписать данные (п. 0.6).
3. Проходные баллы квизов в данных (п. 0.7).
4. Вычистить из контента выдуманные числа и антисанитарию (п. 0.8).
5. Убрать технические/редакционные тексты из уроков и диплома (п. 0.9).
6. Скрыть AI-раздел и ключ OpenAI из v1 ([review/06](review/06_AI_SCOPE_DECISION.md)).
7. Решить судьбу каталога коктейлей ([review/05](review/05_COCKTAIL_CATALOG_DECISION.md)).

### Шаг 1 — Исправить overflow (P0)
1. Обернуть `_showCompletionDialog()` в `SingleChildScrollView`
2. Проверить другие экраны на overflow
3. Собрать debug APK и протестировать на маленьком экране

### Шаг 2 — Доделать Level 2 (P1)
1. Создать practice challenges для блоков D и F
2. Обновить `workshop_screen.dart`
3. Проверить целостность Level 2

### Шаг 3 — Визуальная проверка (P2)
1. Проверить все экраны на использование кастомных иконок
2. Удалить дубликаты картинок (`barista_john.png.png`)
3. Провести icon sweep

### Шаг 4 — Технические задачи (P3)
1. Удалить `.env` из Git
2. Проверить legacy-код
3. Упорядочить логирование

### Шаг 5 — Релизный smoke-test
```powershell
dart format lib test
flutter analyze
flutter test test/bartender_school/level1
flutter build apk --debug
# Ручной проход Level 1 на Mi A2 Lite
```

---

## 📝 Заметки

- Level 2 не должен быть "первым релизом" — сначала довести Level 1 до стабильного состояния
- Блоки D и F в Level 2 — опциональны для v1, но если уже в коде, нужно довести
- `.env` — критично для безопасности, исправить до релиза
- Legacy-код можно удалить после проверки зависимостей
