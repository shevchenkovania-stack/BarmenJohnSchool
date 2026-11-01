# Workshop and Practice

## Роль Мастерской

Мастерская - не отдельная игрушка и не старый конструктор ради конструктора.

Ее продуктовая роль:

- превращать уроки в действие;
- закреплять технику;
- готовить к экзамену;
- давать ученику причину вернуться после теории;
- связывать школу, рецепты и прогресс.

Файл главного экрана:

- `lib/features/bartender_school/presentation/screens/workshop_screen.dart`

## Навигация

Мастерская находится в нижней навигации:

- `lib/shell/main_shell.dart`
- вкладка `Мастерская`
- экран `WorkshopScreen`

## Данные практики

Файлы:

- `lib/features/bartender_school/data/practice_challenges.dart`
- `lib/features/bartender_school/data/challenges/challenges_block_a.dart`
- `lib/features/bartender_school/data/challenges/challenges_block_b.dart`
- `lib/features/bartender_school/data/challenges/challenges_block_c.dart`

Практика группируется по блокам:

- A - основы вкуса;
- B - инструменты и техника;
- C - первые классики.

## Доступность заданий

В `WorkshopScreen` задание заблокировано, пока теория урока не завершена.

Проверка:

- `progress.getLessonStatus(challenge.lessonId) == LessonStatus.completed`

То есть ученик сначала проходит урок/квиз, потом идет тренироваться.

## Запуск практики

При нажатии на доступное задание открывается:

- `PracticeFlowScreen`

Файл:

- `lib/features/bartender_school/presentation/screens/practice_flow_screen.dart`

## Прогресс практики

Файл:

- `lib/features/bartender_school/data/progress_service.dart`

Ключевые методы:

- `getWorkshopMissionCount(missionId)`
- `incrementWorkshopMission(missionId)`
- `isWorkshopMissionComplete(missionId, targetCount: 3)`
- `addWorkshopXp(amount)`
- `workshopPracticeXp`
- `workshopPracticeLevel`
- `workshopNextLevelXp`
- `completeLessonPractice(lessonId)`
- `isLessonPracticeComplete(lessonId)`
- `savePracticeResult(challengeId, stars)`
- `getPracticeStars(challengeId)`
- `checkAndAwardBadges()`

## Уровни практики

Текущие уровни по XP:

- 0-49 XP -> Новичок
- 50-149 XP -> Стажер
- 150-299 XP -> Бармен
- 300+ XP -> Миксолог

## Бейджи

Файл:

- `lib/features/bartender_school/data/workshop_badges.dart`

Бейджи должны быть связаны с практическим поведением:

- звезды за задания;
- streak;
- time bonus.

## Как Мастерская должна быть связана со школой

Правильный цикл:

1. Урок объясняет навык.
2. Квиз проверяет понимание.
3. Мастерская открывает практическое задание.
4. Задание закрепляет навык на коктейле или технике.
5. Результат возвращается в прогресс урока.
6. Диплом учитывает не только прочтение, но и практику.

## Какой должна быть практика

Практика должна быть конкретной:

- выбрать ингредиенты;
- выставить пропорции;
- понять баланс;
- собрать классику;
- увидеть ошибку;
- получить обратную связь.

Не должно быть ощущения, что пользователь просто двигает ползунки без связи с курсом.

## Куда двигать Мастерскую

Для первого релиза:

- оставить Мастерскую как обязательное закрепление Level 1;
- усилить связь каждого задания с уроком;
- сделать финальную практическую проверку по классике;
- выбрать набор классики, который реально обязан знать начинающий бармен.

Желательное финальное задание:

- ученик должен собрать ограниченный набор классических коктейлей;
- приложение проверяет пропорции/баланс;
- диплом открывается только после теории и практики.
