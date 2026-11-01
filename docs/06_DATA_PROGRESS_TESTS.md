# Data, Progress, and Tests

## Контент

Учебный контент лежит в:

- `data/content/lessons_level1_part1.json`
- `data/content/lessons_level1_part2.json`
- `data/content/lessons_level2.json`
- `data/content/lessons_level3.json`
- `data/content/quizzes_level1_part1.json`
- `data/content/quizzes_level1_part2.json`
- `data/content/quizzes_level2.json`
- `data/content/quizzes_level3.json`

Эти файлы подключены как assets через `pubspec.yaml`:

- `data/content/`

Если уроки или квизы не грузятся, сначала проверить:

1. Есть ли файл в `data/content/`.
2. Подключена ли папка в `pubspec.yaml`.
3. Совпадает ли JSON со структурой `Lesson` или `Quiz`.
4. Нет ли ошибки парсинга в консоли.

## Модель урока

Файл:

- `lib/features/bartender_school/domain/entities/lesson.dart`

Обязательные поля JSON:

- `id`
- `blockId`
- `lessonNumber`
- `title`
- `emoji`
- `shortDescription`
- `keyPoints`
- `slides`

Важные дополнительные поля:

- `tools`
- `terms`
- `skills`
- `estimatedMinutes`
- `unlockCondition`
- `diplomaCocktailId`
- `mentor`
- `historicalStory`
- `nextLessonHook`

## Модель прогресса

Файлы:

- `lib/features/bartender_school/domain/entities/progress.dart`
- `lib/features/bartender_school/data/progress_service.dart`

Основной ключ:

- `bartender_school_progress`

Дополнительные ключи:

- `bartender_school_seen_level1_prologue`
- `bartender_block_intro_A/B/C`
- `bartender_school_first_name`
- `bartender_school_last_name`
- `workshop_mission_<id>_count`
- `workshop_practice_xp`
- `lesson_practice_<lessonId>`
- `practice_stars_<challengeId>`
- `workshop_time_bonus`
- `term_learned_<termName>`
- `term_learned_date_<termName>`
- `cocktail_made_<cocktailName>`
- `cocktail_rating_<cocktailName>`

## Состояния уроков

Enum:

- `LessonStatus.locked`
- `LessonStatus.available`
- `LessonStatus.inProgress`
- `LessonStatus.completed`

Важно:

- `completed` сейчас означает завершение теории/урока.
- Полное завершение должно проверять теорию + практику через `isLessonFullyComplete`.

## Тесты

Текущая папка тестов Level 1:

- `test/bartender_school/level1/level1_content_test.dart`
- `test/bartender_school/level1/progress_service_test.dart`
- `test/bartender_school/level1/quiz_answer_evaluator_test.dart`

Что должны защищать тесты:

- все уроки Level 1 загружаются;
- JSON имеет нужные поля;
- термины/слайды/квиз не пустые;
- прогресс сохраняет статусы;
- квиз корректно оценивает ответы;
- нет обрывов в unlockCondition;
- практика связана с существующими уроками.

## Команды проверки

Точечный анализ измененных файлов:

```bash
dart analyze lib/features/bartender_school/presentation/screens/flip_card_screen.dart
```

Форматирование:

```bash
dart format lib test
```

Flutter analyze:

```bash
flutter analyze
```

Тесты:

```bash
flutter test test/bartender_school/level1
```

Примечание: общий `flutter analyze` может работать долго на текущем проекте. Если он зависает, сначала проверять точечно измененные файлы и тесты школы.

## Что важно при изменении данных

После изменения JSON уроков или квизов:

1. Запустить тесты Level 1.
2. Проверить `LessonRepository`.
3. Проверить `QuizRepository`.
4. Открыть Level 1 в приложении.
5. Проверить, что карточка открывается.
6. Проверить, что `Начать урок` видно без скролла.
7. Проверить, что после квиза обновляется XP/статус.
8. Проверить, что Мастерская открывает практику после урока.
