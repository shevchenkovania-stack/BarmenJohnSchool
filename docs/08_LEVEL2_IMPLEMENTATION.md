# Level 2 — реализация и проверка

Дата: 2026-08-15  
Статус: реализован в основном учебном потоке; debug APK собран и установлен на реальный Android, полный ручной проход ещё не выполнен.

## Программа

| № | ID | Тема |
|---:|---|---|
| 13 | `lesson_D_13` | Читай спецификацию как бармен |
| 14 | `lesson_D_14` | Замены без потери баланса |
| 15 | `lesson_D_15` | Текстура и процеживание |
| 16 | `lesson_D_16` | Температура, лёд и разбавление |
| 17 | `lesson_E_17` | Whiskey Sour: кислота и пена |
| 18 | `lesson_E_18` | Old Fashioned: точность минимума |
| 19 | `lesson_E_19` | Dry Martini: холод и прозрачность |
| 20 | `lesson_E_20` | Margarita: текила, лайм, соль |
| 21 | `lesson_F_21` | Prep, маркировка и безопасность |
| 22 | `lesson_F_22` | Бриф гостя и ответственная подача |
| 23 | `lesson_F_23` | Сервис в запару |
| 24 | `lesson_F_24` | Итоговый экзамен Level 2 |

Каждый урок содержит пять содержательных слайдов, профиль наставника, типичную ошибку, способ исправления, барную ситуацию, практику, историческую рамку и hook следующего урока.

## Квизы и экзамен

- 12 квизов и 104 вопроса.
- Уроки 13–23 имеют пул из 8 вопросов, попытка выбирает 6.
- Финал имеет 16 вопросов в одной попытке.
- Используются только честно проверяемые типы: `singleChoice`, `multipleChoice`, `trueFalse`.
- Не используются старые псевдо-slider и неподтверждённые matching/sequence.

Практический диплом требует:

- завершить 12 уроков D/E/F;
- получить не менее 2 звёзд за каждую из четырёх классик;
- набрать суммарно не менее 9 звёзд из 12.

Практики имеют отдельные ID Level 2, поэтому результат старого задания Level 1 не засчитывается автоматически:

- `level2_whiskey_sour`;
- `level2_old_fashioned`;
- `level2_dry_martini`;
- `level2_margarita`.

## Источники контента

Опорные спецификации проверены по первичному профессиональному источнику — International Bartenders Association:

- [Whiskey Sour — IBA](https://iba-world.com/iba-cocktail/whiskey-sour/)
- [Old Fashioned — IBA](https://iba-world.com/iba-cocktail/old-fashioned/)
- [Dry Martini — IBA](https://iba-world.com/iba-cocktail/dry-martini/)
- [Margarita — IBA](https://iba-world.com/iba-cocktail/margarita/)

Безопасность и ответственная подача проверены по официальным материалам:

- [FDA: What You Need to Know About Egg Safety](https://www.fda.gov/food/buy-store-serve-safe-food/what-you-need-know-about-egg-safety)
- [Food Standards Agency: allergen guidance for food businesses](https://www.food.gov.uk/business-guidance/allergen-guidance-for-food-businesses)
- [NIAAA: Alcohol Overdose](https://www.niaaa.nih.gov/alcohols-effects-health/alcohol-topics/health-topics-alcohol-overdose)

Юридические правила ответственной подачи различаются по стране и заведению. Урок намеренно требует следовать местному закону и внутренней процедуре, а не выдаёт универсальную юридическую инструкцию.

## Иллюстрации карточек

Изображения созданы встроенной генерацией изображений по локальному референсу `images/lesson_a_01_balance.jpg`.

Общий prompt-set:

> Square premium editorial bartender-school still life; near-black bar background, warm dark wood, dramatic cinematic rim light, brushed brass accents, clean centered photorealistic composition, strong silhouette at thumbnail size; no John, people, text, letters, numbers, brands, logos, watermark or UI.

Для каждого файла добавлялся отдельный предметный сюжет: карта спецификации, система замен, shaker и fine strainer, лёд и mixing glass, четыре классики, prep-станция, диалог с гостем, сервисная линия и экзаменационный медальон.

Файлы:

- `images/lesson_d_13_spec.jpg`
- `images/lesson_d_14_substitution.jpg`
- `images/lesson_d_15_texture.jpg`
- `images/lesson_d_16_temperature.jpg`
- `images/lesson_e_17_whiskey_sour.jpg`
- `images/lesson_e_18_old_fashioned.jpg`
- `images/lesson_e_19_dry_martini.jpg`
- `images/lesson_e_20_margarita.jpg`
- `images/lesson_f_21_prep_safety.jpg`
- `images/lesson_f_22_guest_brief.jpg`
- `images/lesson_f_23_service_rush.jpg`
- `images/lesson_f_24_exam.jpg`

## Техническое подключение

- `LessonRepository.loadCoreCurriculum()` последовательно загружает Level 1 и Level 2.
- Главный экран показывает отдельные карточки двух уровней.
- `Level2Screen` группирует уроки в D/E/F и открывает Мастерскую.
- `lesson_D_13` открывается только после честного диплома Level 1.
- Карточки показывают тематический artwork, прогресс практики и терминов.
- `ProgressService.recordPracticeAttempt()` сохраняет попытку вне `build()`, начисляет XP только за улучшение и закрывает практику урока при 2+ звёздах.

## Выполненная проверка

```text
flutter test test/bartender_school/level1 test/bartender_school/level2
29 tests passed

flutter analyze <14 изменённых Dart-файлов>
0 errors, 0 warnings; только существующие info lint

flutter analyze
681 накопленное замечание по всему legacy-проекту; новых compiler errors не обнаружено

flutter build apk --debug
success: build/app/outputs/flutter-apk/app-debug.apk

flutter run -d 2b4a6e3e0205 --debug --no-resident
success: APK установлен и процесс приложения запущен на Mi A2 Lite / Android 10

flutter run -d 3A191FDJG0021L --debug --no-resident
success: финальный APK установлен и запущен на Pixel 8 Pro
```

На Pixel 8 Pro вручную подтверждено:

- главный экран открывает Level 1 и Level 2;
- все 12 тематических изображений Level 2 отображаются в двухколоночной сетке с корректным кропом;
- сокращённые заголовки `Уровень 1` / `Уровень 2` не обрезаются рядом с XP и кнопкой Мастерской;
- путь Level 1 карточка → вступление Джона → урок → термины → основной квиз работает;
- sequence показывает перемешанный порядок, отклоняет неверный ответ и раскрывает правильный;
- matching требует заполнить все четыре карточки и принимает только точные пары;
- лишний неактивный footer до ответа удалён, чтобы не перекрывать интерактивные карточки.

Перед релизом ещё нужны:

- ручной проход Level 2 на Android;
- визуальная проверка кропа двенадцати карточек на маленьком экране;
- решение конфликта legacy Level 3, который всё ещё использует блок E, перед его будущим включением.

Первый проход на Mi A2 Lite 2026-08-15 остановился после установки: телефон переключился на системный экран Wi-Fi, затем ADB сообщил `device unauthorized`. Это не было падением приложения — PID оставался активным. Последующий визуальный smoke-test успешно выполнен на Pixel 8 Pro; отдельная проверка самого маленького поддерживаемого экрана всё ещё нужна.
