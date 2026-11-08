# Bartender School

## Роль школы

Школа - главный продукт приложения.

Она должна давать не просто "прочитал карточку - получил галочку", а путь ученика:

1. Вводный экран/пролог.
2. Главы/блоки.
3. Урок.
4. Квиз.
5. Практика в Мастерской.
6. Прогресс, XP, термины, бейджи.
7. Диплом.

## Текущие уровни

Данные уровней лежат в `data/content/`:

- `lessons_level1_part1.json`
- `lessons_level1_part2.json`
- `lessons_level2.json`
- `lessons_wisdom.json`
- `quizzes_level1_part1.json`
- `quizzes_level1_part2.json`
- `quizzes_level2.json`

Архив Level 3 (в рантайме не загружается, `loadLevel3()` нигде не вызывается):

- `legacy_lessons_level3.json`
- `legacy_lessons_level3_part1.json`
- `legacy_quizzes_level3.json`
- `legacy_quizzes_level3_part1.json`

Код загрузки:

- `lib/features/bartender_school/data/lesson_repository.dart`
- `lib/features/bartender_school/data/quiz_repository.dart`

Важно: Level 2 уже подключён к экрану, а старый Level 3 — нет: его файлы лежат как `legacy_*` и не читаются. Первый релиз должен быть сфокусирован на качественном Level 1.

## Level 1

Экран: `lib/features/bartender_school/presentation/screens/level1_screen.dart`

Level 1 сейчас главный учебный курс.

Структура Level 1:

- Блок A - вкус и баланс.
- Блок B - руки, инструменты, техника.
- Блок C - первые классические коктейли и финальная проверка.

В коде Level 1:

- показывает пролог Джона при первом входе;
- показывает briefing для блоков A/B/C;
- группирует уроки по блокам;
- показывает карточки уроков через `LessonCard`;
- открывает `FlipCardScreen`;
- передает прогресс практики и терминов в карточки.

## Модель урока

Файл: `lib/features/bartender_school/domain/entities/lesson.dart`

`Lesson` содержит:

- `id`
- `blockId`
- `lessonNumber`
- `title`
- `emoji`
- `shortDescription`
- `keyPoints`
- `slides`
- `tools`
- `terms`
- `skills`
- `estimatedMinutes`
- `unlockCondition`
- `diplomaCocktailId`
- `mentor`
- `historicalStory`
- `nextLessonHook`

Новые уроки должны добавляться через JSON и соответствовать этой модели.

## Слайды урока

`LessonSlide` содержит:

- `type`
- `title`
- `content`
- `imageUrl`
- `bulletPoints`
- `mentorNote`

Типы слайдов:

- `theory`
- `toolVisual`
- `termAnimation`
- `practice`
- `barTip`
- `balanceTrainer`
- `checklist`
- `interactive`

Если добавляется новый тип слайда, нужно обновить:

- модель `SlideType`;
- рендеринг в `lesson_screen.dart`;
- тесты контента.

## Квиз

Квизы загружаются через `QuizRepository`.

Файл:

- `lib/features/bartender_school/data/quiz_repository.dart`

Логика:

- для урока берется пул вопросов;
- на попытку выбирается `questionsPerAttempt`;
- использованные вопросы временно исключаются;
- если вопросов не хватает, пул сбрасывается.

Оценка ответов:

- `lib/features/bartender_school/domain/services/quiz_answer_evaluator.dart`

Тесты:

- `test/bartender_school/level1/quiz_answer_evaluator_test.dart`

## Прогресс школы

Файл:

- `lib/features/bartender_school/data/progress_service.dart`

Основной прогресс хранится в `SharedPreferences` под ключом:

- `bartender_school_progress`

Что хранится:

- XP;
- streak;
- статусы уроков;
- использованные вопросы;
- открытые коктейли;
- достижения;
- дата последнего занятия.

Статусы уроков:

- `locked`
- `available`
- `inProgress`
- `completed`

## Практика как часть завершения

Теория и практика разделены.

В `ProgressService` есть:

- `completeLessonPractice(lessonId)`
- `isLessonPracticeComplete(lessonId)`
- `isLessonFullyComplete(lessonId)`
- `isLevelFullyComplete(lessonIds)`

Правило продукта:

- Урок может быть теоретически завершен через квиз.
- Но настоящий учебный цикл должен вести дальше в Мастерскую.
- Для ощущения реальной школы практика должна быть обязательной частью финального прогресса.

## Диплом

Экран:

- `lib/features/bartender_school/presentation/screens/certificates_screen.dart`

Имя студента:

- `studentFirstName`
- `studentLastName`
- `studentFullName`
- `setStudentName(...)`

Ключи:

- `bartender_school_first_name`
- `bartender_school_last_name`

Диплом должен быть виден заранее, потому что он мотивирует. Но он должен быть заблокирован до выполнения условий.

Текущая проверка:

- `ProgressService.isSchoolCompleted(...)`

Сейчас она проверяет:

- все уроки блоков A/B/C completed;
- есть хотя бы одна попытка практического задания.

Желаемое направление:

- сделать практику более строгой: не "хотя бы одна", а достаточный набор обязательных практических заданий/классики.
