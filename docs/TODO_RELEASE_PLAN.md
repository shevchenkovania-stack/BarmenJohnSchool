# 📋 План недоделок для релиза

> Дата сверки: 2026-08-15
> Статус: Level 1 готов к smoke-test, Level 2 требует доработки

---

## 🔴 P0 — Критично для релиза

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
