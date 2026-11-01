# Bartender School Project Documentation

Дата: 2026-08-08
Проект: `coin`
Целевой продукт: автономная мобильная школа бармена для Google Play.

## Product Positioning

Главный продукт приложения - Bartender School.

Остальные функции должны поддерживать обучение:

- библиотека коктейлей = "Библиотека знаний";
- конструктор коктейлей = "Мастерская бармена";
- избранное и Can Make Now = "Практика";
- AI recipes = будущий optional "AI-ментор", но не обязательная часть v1;
- Bar Manager, Cost Calculator, Menu Builder, QR Menu, Guest Mode - скрыть или убрать из первого школьного пути.

## V1 Principle

Первая версия должна быть полезной без бекенда и без обязательного AI.

Обязательные свойства:

- работает офлайн после установки;
- уроки, квизы, практика и экзамен лежат локально;
- сертификат выдается только за реальное прохождение;
- все подсказки и оценка практики deterministic/rule-based;
- AI не блокирует школу и не нужен для сдачи.

## Learning Model

Школа должна учить не только рецептам, а профессиональному мышлению:

- вкус и баланс;
- точность измерения;
- подготовка станции;
- техника shake/stir/build;
- лед и dilution;
- классические коктейли;
- разбор ошибок.

Каждый урок должен иметь:

- цель урока;
- короткое объяснение;
- термины;
- практику;
- проверку;
- связь с финальным экзаменом.

## Level 1 Scope

Level 1 - начальный уровень.

Цель: студент понимает базу вкуса и может собрать Mojito, Daiquiri, Negroni в учебной мастерской.

Минимальный честный результат Level 1:

- знает sweet/sour/bitter/salt/umami/body;
- понимает, зачем нужен лед;
- умеет отличить shake, stir и build;
- понимает, зачем нужен jigger;
- знает базовый mise en place;
- собирает три коктейля в правильной технике;
- проходит теоретический и практический экзамен.

## Current School Architecture

Content:

- `data/content/lessons_level1_part1.json`
- `data/content/lessons_level1_part2.json`
- `data/content/quizzes_level1_part1.json`
- `data/content/quizzes_level1_part2.json`
- `data/content/lessons_level2.json`
- `data/content/lessons_level3.json`
- `data/content/quizzes_level2.json`
- `data/content/quizzes_level3.json`

Core school services:

- `lib/features/bartender_school/data/lesson_repository.dart`
- `lib/features/bartender_school/data/quiz_repository.dart`
- `lib/features/bartender_school/data/progress_service.dart`
- `lib/features/bartender_school/data/school_config.dart`

Main screens:

- `lib/features/bartender_school/presentation/screens/school_home_screen.dart`
- `lib/features/bartender_school/presentation/screens/level1_screen.dart`
- `lib/features/bartender_school/presentation/screens/flip_card_screen.dart`
- `lib/features/bartender_school/presentation/screens/lesson_screen.dart`
- `lib/features/bartender_school/presentation/screens/quiz_screen.dart`
- `lib/features/bartender_school/presentation/screens/certificates_screen.dart`
- `lib/features/bartender_school/presentation/screens/achievements_screen.dart`

## Current Known Risks

See `LEVEL1_BARTENDER_SCHOOL_AUDIT.md` for the detailed Level 1 audit.
See `LEVEL1_CONTENT_7_TO_9_PLAN.md` for the content/mentor upgrade plan.

High priority risks:

- failed quizzes must not complete lessons;
- quiz loading must not dead-end;
- lesson unlock chain must not open locked content from empty progress;
- interactive questions must evaluate actual user action;
- final exam must include practice, not only theory;
- glossary and mentor text need one source of truth;
- UI must be checked on small mobile screens.

## Mentor Persona

The school should feel guided by a real bartender mentor.

Role:

- explains what matters behind the bar;
- gives short practical advice;
- connects mistakes to taste;
- keeps the tone human and professional;
- never replaces deterministic exam scoring.

Recommended data fields:

- `mentorIntro`
- `mentorTip`
- `commonMistake`
- `realBarReason`
- `practiceFeedback`

## Practice Engine

The "Cocktail Builder" should become "Bartender Workshop".

V1 engine should be rule-based:

- recipe JSON;
- allowed ingredient ranges;
- technique requirements;
- glassware requirements;
- ice/dilution rules;
- scoring rules;
- feedback templates.

No backend is required for this.

## Release Readiness Checklist

Before Google Play:

- remove hardcoded API keys and secrets;
- hide non-school features from the main path;
- verify all Level 1 lesson flows on Android;
- verify small-screen layout and text overflow;
- run `flutter analyze`;
- run Android debug build;
- test fresh install with empty progress;
- test failed quiz path;
- test passed quiz path;
- test certificate unlock;
- test offline mode.

## Work Log

2026-08-08:

- Added Level 1 audit requirements.
- Started P0 quiz/progress fixes for honest school flow.
- Fixed quiz loading retry so it does not dead-end while quiz content is still loading.
- Quiz pass/fail now uses `BartenderSchoolConfig.quizPassingScore`.
- Failed quiz attempts no longer complete lessons.
- Quiz completion now exits the result dead-end and returns the student to the learning flow.
- Lesson progress no longer grants repeated XP for already completed lessons.
- Missing prerequisites now keep dependent lessons locked.
- Slider quiz questions now score by their configured `correctMin`/`correctMax` ranges.
- Verified `flutter build apk --debug` successfully after the first P0 fixes and again after slider scoring.
- Added dedicated Level 1 unit-test folder: `test/bartender_school/level1`.
- Added tests for Level 1 content integrity, progress gating/XP, and quiz answer evaluation.
- Extracted pure `QuizAnswerEvaluator` so quiz scoring can be unit-tested outside the UI.
- `flutter test test/bartender_school/level1` and `dart run test test/bartender_school/level1` currently hang in this local tooling session without output; stale `dart.exe` test runner processes had to be stopped manually.
- Verified `flutter build apk --debug` successfully after adding the evaluator and tests.
- Added `LEVEL1_CONTENT_7_TO_9_PLAN.md` to define the mentor, practical exam, and content rewrite needed to raise Level 1 from 7/10 to 9/10.
- Started the 7/10 -> 9/10 content upgrade: added `LessonMentor`, `mentor` lesson data, and `mentorNote` slide data.
- Added mentor profiles for all 12 Level 1 lessons and 26 slide-level mentor notes.
- Added the in-lesson "Наставник" note block for regular lesson slides.
- Verified `flutter build apk --debug` successfully after the mentor model, JSON, and UI changes.
- Extended the mentor note UI to interactive/special lesson slides, so practical trainers are also guided by the bartender mentor.
- Reworked `lesson_C_12` from a theory-only exam into a Level 1 capstone: theory, mistake diagnosis, and practical mastery for Mojito, Daiquiri, and Negroni.
- Removed outdated Level 1 exam copy that promised 80% pass and 10 XP for failed attempts; the lesson copy now matches the configured 70% threshold and honest pass/fail flow.
