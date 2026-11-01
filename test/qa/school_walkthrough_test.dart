// TEMP QA HARNESS (снимать после окончания QA-прохода, если не решим оставить).
//
// Прогоняет РЕАЛЬНЫЕ экраны школы в телефонном viewport, собирает ошибки
// layout (RenderFlex overflow и прочее) и пишет PNG в test/qa/shots/.
//
// Запуск:
//   flutter test test/qa/school_walkthrough_test.dart --update-goldens
// Текст подложка — реальная TTF из Windows под family-имена Google Fonts,
// метрики остаются честными (настоящие шрифты приложения требуют сети).
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show StandardMessageCodec;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:coin/core/theme/app_theme.dart';
import 'package:coin/features/bartender_school/data/daily_quest_service.dart';
import 'package:coin/features/bartender_school/data/lesson_repository.dart';
import 'package:coin/features/bartender_school/data/practice_challenges.dart';
import 'package:coin/features/bartender_school/data/progress_service.dart';
import 'package:coin/features/bartender_school/data/quiz_repository.dart';
import 'package:coin/features/bartender_school/domain/entities/progress.dart';
import 'package:coin/features/bartender_school/presentation/screens/achievements_screen.dart';
import 'package:coin/features/bartender_school/presentation/screens/bartender_shelf_screen.dart';
import 'package:coin/features/bartender_school/presentation/screens/certificates_screen.dart';
import 'package:coin/features/bartender_school/presentation/screens/daily_quests_screen.dart';
import 'package:coin/features/bartender_school/presentation/screens/flip_card_screen.dart';
import 'package:coin/features/bartender_school/presentation/screens/glossary_screen.dart';
import 'package:coin/features/bartender_school/presentation/screens/lesson_screen.dart';
import 'package:coin/features/bartender_school/presentation/screens/level1_screen.dart';
import 'package:coin/features/bartender_school/presentation/screens/mission_briefing_screen.dart';
import 'package:coin/features/bartender_school/presentation/screens/practice_flow_screen.dart';
import 'package:coin/features/bartender_school/presentation/screens/quiz_screen.dart';
import 'package:coin/features/bartender_school/presentation/screens/wisdom_vault_screen.dart';
import 'package:coin/features/bartender_school/presentation/screens/workshop_screen.dart';
import 'package:coin/l10n/app_localizations.dart';

final List<String> findings = <String>[];

Size _surface = const Size(411, 891);

Future<void> _registerFonts() async {
  final path = File('C:/Windows/Fonts/georgia.ttf').existsSync()
      ? 'C:/Windows/Fonts/georgia.ttf'
      : 'C:/Windows/Fonts/arial.ttf';
  final bytes = Uint8List.fromList(File(path).readAsBytesSync());
  for (final family in [
    'Cinzel',
    'Cormorant Garamond',
    'EB Garamond',
    'Nunito',
    'Nunito Sans',
    'Noto Sans',
    'Roboto',
  ]) {
    await ui.loadFontFromList(bytes, fontFamily: family);
  }
}

/// GoogleFonts при allowRuntimeFetching=false сначала ищет шрифт среди
/// ассетов приложения (AssetManifest.bin + rootBundle.load), и если находит —
/// загружает его БЕЗ асинхронной ошибки. В тестовом изоляторе подменяем канал
/// 'flutter/assets': синтетический манифест со всеми нужными семействами,
/// вместо любого .ttf — реальные байты georgia, для остальных ключей —
/// чтение файла с диска (в `flutter test` пути ассетов = пути в репозитории).
bool _offlineFontsInstalled = false;

void _installOfflineFonts(WidgetTester tester) {
  if (_offlineFontsInstalled) return;
  _offlineFontsInstalled = true;
  final fontPath = File('C:/Windows/Fonts/georgia.ttf').existsSync()
      ? 'C:/Windows/Fonts/georgia.ttf'
      : 'C:/Windows/Fonts/arial.ttf';
  final fontBytes =
      ByteData.sublistView(Uint8List.fromList(File(fontPath).readAsBytesSync()));
  const codec = StandardMessageCodec();
  const families = [
    'Cinzel', 'CormorantGaramond', 'EBGaramond',
    'Nunito', 'NunitoSans', 'NotoSans', 'Roboto',
  ];
  const variants = [
    'Regular', 'Italic', 'Light', 'LightItalic', 'Medium', 'MediumItalic',
    'SemiBold', 'SemiBoldItalic', 'Bold', 'BoldItalic', 'ExtraBold',
    'ExtraBoldItalic', 'Black', 'BlackItalic',
  ];
  final manifest = <Object?, Object?>{};
  for (final f in families) {
    for (final v in variants) {
      final key = 'qa_fonts/$f-$v.ttf';
      manifest[key] = [
        {'asset': key}
      ];
    }
  }
  tester.binding.defaultBinaryMessenger.setMockMessageHandler(
    'flutter/assets',
    (ByteData? message) async {
      if (message == null) return null;
      final key = utf8.decode(
        message.buffer.asUint8List(
            message.offsetInBytes, message.lengthInBytes),
        allowMalformed: true,
      );
      if (key == 'AssetManifest.bin' || key == 'AssetManifest.bin.json') {
        return codec.encodeMessage(manifest);
      }
      if (key.endsWith('.ttf') || key.endsWith('.otf')) {
        return fontBytes;
      }
      final file = File(key);
      if (file.existsSync()) {
        return ByteData.sublistView(
            Uint8List.fromList(file.readAsBytesSync()));
      }
      return null;
    },
  );
}

void _note(String text) {
  findings.add(text);
  // ignore: avoid_print
  print('QA> $text');
}

/// GoogleFonts в оффлайн-тестах всегда падает асинхронно (rethrow в
/// не-ожидаемом future). Переопределять FlutterError.onError нельзя —
/// binding тогда не может вернуть ошибки тесту; вместо этого просто
/// не пишем в отчёт заведомо шрифтовой шум при дренаже pending-ошибок.
bool _isFontNoise(String text) =>
    text.contains('allowRuntimeFetching') ||
    text.contains('google_fonts') ||
    text.contains('GoogleFonts');

void _drain(WidgetTester tester, String screen) {
  while (true) {
    final e = tester.takeException();
    if (e == null) break;
    final lines = e.toString().split('\n');
    if (_isFontNoise(lines.first)) continue;
    final where = lines
        .where((l) => l.contains('error-causing widget') || l.contains('.dart:'))
        .take(2)
        .join(' ');
    _note('[layout][$screen] ${lines.first.trim()} $where');
  }
}

Future<void> _shot(WidgetTester tester, String name) async {
  await tester.pump(const Duration(milliseconds: 350));
  // Перед золотым кадром вычищаем pending-ошибки (шрифт и layout), иначе
  // они прилетают «после завершения теста» и роняют его постфактум.
  _drain(tester, 'pre-shot:$name');
  try {
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('shots/$name.png'),
    );
  } catch (e) {
    _note('[shot:$name] $e');
  }
  // Пампы внутри golden-свертки пересоздают GoogleFonts-ошибки (пакет
  // снимает метку «загружено» при фейле). Финальный флеш не даёт им
  // дожить до конца теста.
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 120));
    _drain(tester, 'post-shot:$name');
  }
}

class Harness {
  Harness(this.lessons, this.quizzes, this.progress);
  final LessonRepository lessons;
  final QuizRepository quizzes;
  final ProgressService progress;
}

Future<Harness> _boot(WidgetTester tester, Widget screen,
    {Map<String, Object>? prefs}) async {
  _installOfflineFonts(tester);
  _flushFontTail(tester);
  SharedPreferences.setMockInitialValues(prefs ?? <String, Object>{});
  final sp = await SharedPreferences.getInstance();

  final lessonRepo = LessonRepository();
  final quizRepo = QuizRepository();
  await tester.runAsync(() async {
    await lessonRepo.loadCoreCurriculum();
    await lessonRepo.loadWisdom();
    await quizRepo.loadQuizzes();
  });
  final progress = ProgressService(sp, lessonRepo: lessonRepo);

  await tester.binding.setSurfaceSize(_surface);
  tester.view.physicalSize = _surface * 3;
  tester.view.devicePixelRatio = 3.0;
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<SharedPreferences>.value(value: sp),
        ChangeNotifierProvider<LessonRepository>.value(value: lessonRepo),
        ChangeNotifierProvider<QuizRepository>.value(value: quizRepo),
        ChangeNotifierProvider<ProgressService>.value(value: progress),
        ChangeNotifierProvider<DailyQuestService>(
          create: (_) => DailyQuestService(sp),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: appTheme,
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: screen,
      ),
    ),
  );
  await _settle(tester);
  return Harness(lessonRepo, quizRepo, progress);
}

Future<bool> _tapText(WidgetTester tester, String text,
    {bool contains = false}) async {
  final finder = contains ? find.textContaining(text) : find.text(text);
  if (finder.evaluate().isEmpty) return false;
  // ensureVisible скроллит ВСЕ наследственные Scrollable — включая PageView
  // практики, у которого тап «двигает» страницы на чужие пиксели. Поэтому
  // подтягиваем видимость только когда виджет реально за вьюпортом.
  final rect = tester.getRect(finder.first);
  final offScreen = rect.center.dx <= 0 ||
      rect.center.dy <= 0 ||
      rect.center.dx >= _surface.width ||
      rect.center.dy >= _surface.height;
  if (offScreen) {
    try {
      await tester.ensureVisible(finder.first);
    } catch (_) {
      // не в скроллабле — тапаем как есть
    }
  }
  await tester.tap(finder.first, warnIfMissed: false);
  await _settle(tester);
  return true;
}

/// Закрыть любое модальное окно Джона/брифинга, если оно перехватило экран.
Future<bool> _dismissDialog(WidgetTester tester) async {
  for (final label in ['Начать обучение', 'Понятно', 'Продолжить', 'Закрыть', 'Ок']) {
    if (await _tapText(tester, label)) return true;
  }
  return false;
}

Future<void> _scrollDown(WidgetTester tester, {int times = 6}) async {
  final scrollable = find.byType(Scrollable).first;
  for (var i = 0; i < times; i++) {
    await tester.drag(scrollable, const Offset(0, -400));
    await _settle(tester);
  }
}

int _n(Finder f) => f.evaluate().length;

/// pumpAndSettle с коротким таймаутом: экраны с вечными анимациями (пульс
/// сундука мудрости) иначе вешают весь харнес.
Future<void> _settle(WidgetTester tester) async {
  try {
    await tester.pumpAndSettle(
        const Duration(milliseconds: 200),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 2));
  } catch (_) {
    await tester.pump(const Duration(milliseconds: 400));
  }
}

/// GoogleFonts при allowRuntimeFetching=false кидает исключение в
/// НЕ-ожидаемом future (реальный event loop: проверка asset manifest и
/// файловой системы). Доставка такой ошибки происходит только когда
/// тест реально отдаёт управление completer'у — внутри runAsync. Флешим
/// хвост в addTearDown: ошибки долетают, пока binding ещё считает тест
/// идущим, и дренажится через takeException без рассинхрона onError.
void _flushFontTail(WidgetTester tester) {
  addTearDown(() async {
    try {
      await tester.runAsync(() async {
        for (var i = 0; i < 6; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 30));
          await tester.pump(const Duration(milliseconds: 50));
        }
      });
    } catch (_) {
      // binding мог закрыть тест — хвост тогда и так не помеха
    }
    _drain(tester, 'tail');
  });
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
    await _registerFonts();
  });

  tearDownAll(() {
    File('test/qa/FINDINGS.txt').writeAsStringSync(
      findings.isEmpty
          ? 'нет пойманных проблем\n'
          : 'всего проблем: ${findings.length}\n${findings.map((f) => '- $f').join('\n')}\n',
    );
  });

  group('обычный телефон 411x891', () {
    testWidgets('Level 1: пролог Джона и сетка карточек', (tester) async {
      await _boot(tester, const Level1Screen());
      _drain(tester, 'Level1Screen:prolog');
      await _shot(tester, '01_level1_prologue_dialog');
      final dismissed = await _dismissDialog(tester);
      if (!dismissed) _note('[Level1Screen] пролог не закрывается кнопкой');
      await _dismissDialog(tester); // блок-брифинг может идти следом
      _drain(tester, 'Level1Screen:after-dialog');
      await _shot(tester, '02_level1_top');
      await _scrollDown(tester, times: 10);
      _drain(tester, 'Level1Screen:scroll');
      await _shot(tester, '03_level1_bottom');
    });

    testWidgets('Карточка урока A_01', (tester) async {
      final h = await _boot(tester, const SizedBox.shrink());
      final lesson = h.lessons.getLesson('lesson_A_01')!;
      await _boot(tester, FlipCardScreen(lesson: lesson));
      _drain(tester, 'FlipCard A_01');
      await _shot(tester, '04_flipcard_A_01');
      await _scrollDown(tester, times: 4);
      _drain(tester, 'FlipCard A_01:scroll');
      await _shot(tester, '05_flipcard_A_01_back');
    });

    testWidgets('Урок A_01: все слайды по очереди', (tester) async {
      final h = await _boot(tester, const SizedBox.shrink());
      final lesson = h.lessons.getLesson('lesson_A_01')!;
      await _boot(tester, LessonScreen(lesson: lesson));
      _drain(tester, 'Lesson A_01');
      await _shot(tester, '06_lesson_slide1');

      for (var i = 2; i <= lesson.slides.length; i++) {
        final before = _n(find.text('Слайд ${i - 1} из ${lesson.slides.length}'));
        final ok = await _tapText(tester, 'Далее');
        if (!ok) {
          _note('[Lesson A_01] слайд $i: кнопки «Далее» нет — путь закрыт');
          break;
        }
        final after =
            _n(find.text('Слайд $i из ${lesson.slides.length}'));
        if (after == 0 && before > 0) {
          _note('[Lesson A_01] слайд $i: «Далее» нажата, но слайд не переключился');
        }
        _drain(tester, 'Lesson A_01 slide $i');
        await _shot(tester, '06_lesson_slide$i');
      }
      await _tapText(tester, 'Далее');
      _drain(tester, 'Lesson A_01 finish');
      await _shot(tester, '07_lesson_finish');
      _note('[Lesson A_01] после последнего слайда: кнопка «К тесту»=${_n(find.text('К тесту')) > 0}');
    });

    testWidgets('Квиз A_01: все вопросы (правильные ответы)', (tester) async {
      final h = await _boot(tester, const SizedBox.shrink());
      final lesson = h.lessons.getLesson('lesson_A_01')!;
      await _boot(tester, QuizScreen(lessonId: lesson.id));
      _drain(tester, 'Quiz A_01');
      await _shot(tester, '08_quiz_q1');

      for (var q = 1; q <= 12; q++) {
        final dropdowns = find.byType(DropdownButton<String>);
        final sliders = _n(find.byType(Slider));
        final reorder = _n(find.byType(ReorderableListView));
        final options = find.byType(InkWell);
        if (_n(dropdowns) == 0 && sliders == 0 && reorder == 0 &&
            _n(options) == 0) {
          _note('[Quiz A_01] вопрос $q: ни вариантов, ни слайдеров, ни последовательности');
          break;
        }
        if (sliders > 0) _note('[Quiz A_01] вопрос $q: слайдер (${sliders} шт)');
        if (reorder > 0) _note('[Quiz A_01] вопрос $q: sequence/ReorderableListView');
        if (_n(dropdowns) > 0) {
          // matching: заполняем все дропдауны первым попавшимся значением
          _note('[Quiz A_01] вопрос $q: matching (${_n(dropdowns)} пар)');
          for (var d = 0; d < _n(find.byType(DropdownButton<String>)); d++) {
            await tester.tap(
                find.byType(DropdownButton<String>).at(d), warnIfMissed: false);
            await _settle(tester);
            // .last: открытый оверлей с пунктами меню идёт в дереве ПОСЛЕ
            // самой кнопки (кнопка содержит копию выбранного пункта, тап по
            // нему ничего не меняет).
            final items = find.byType(DropdownMenuItem<String>);
            if (_n(items) > 0) {
              await tester.tap(items.last, warnIfMissed: false);
              await _settle(tester);
            }
          }
        } else if (_n(options) > 0 && sliders == 0 && reorder == 0) {
          await tester.tap(options.first, warnIfMissed: false);
          await _settle(tester);
        }
        await _shot(tester, '08_quiz_q${q}_answered');
        // Сначала сабмит интерактивного ответа, потом переход. Disabled-тап
        // безопасен (no-op), цикл ограничен тремя попытками.
        var advanced = false;
        for (var attempt = 0; attempt < 3 && !advanced; attempt++) {
          advanced = await _tapText(tester, 'Далее') ||
              await _tapText(tester, 'Завершить');
          if (advanced) break;
          final submitted = await _tapText(tester, 'Проверить порядок') ||
              await _tapText(tester, 'Проверить пары') ||
              await _tapText(tester, 'Проверить') ||
              await _tapText(tester, 'Готово') ||
              await _tapText(tester, 'Ответить') ||
              await _tapText(tester, 'Отправить');
          if (!submitted) break;
          await _settle(tester);
        }
        _drain(tester, 'Quiz A_01 q$q');
        if (!advanced) {
          _note('[Quiz A_01] вопрос $q: нет активной кнопки перехода');
          break;
        }
        if (_n(find.textContaining('%')) > 0 &&
            _n(find.byType(InkWell)) == 0) {
          break; // похоже на экран результата
        }
      }
      _drain(tester, 'Quiz A_01 result');
      await _shot(tester, '09_quiz_result');
      _note('[Quiz A_01] статус урока после квиза: ${h.progress.getLessonStatus(lesson.id)}');
    });

    testWidgets('Квиз A_01: провал не завершает урок', (tester) async {
      final h = await _boot(tester, const SizedBox.shrink());
      final lesson = h.lessons.getLesson('lesson_A_01')!;
      await _boot(tester, QuizScreen(lessonId: lesson.id));
      for (var q = 1; q <= 10; q++) {
        final options = find.byType(InkWell);
        if (_n(options) == 0) break;
        // заведомо последний вариант — скорее всего неправильный
        await tester.tap(options.last, warnIfMissed: false);
        await _settle(tester);
        final advanced = await _tapText(tester, 'Далее') ||
            await _tapText(tester, 'Ответить') ||
            await _tapText(tester, 'Проверить') ||
            await _tapText(tester, 'Завершить');
        if (!advanced) break;
      }
      await _shot(tester, '10_quiz_fail');
      final status = h.progress.getLessonStatus(lesson.id);
      _note('[Quiz fail] статус урока после провала: $status '
          '(должен быть НЕ completed)');
      if (status == LessonStatus.completed) {
        _note('[Quiz fail] P0: проваленный квиз завершил урок');
      }
    });

    testWidgets('Мастерская: список заданий', (tester) async {
      await _boot(tester, const WorkshopScreen());
      _drain(tester, 'WorkshopScreen');
      await _shot(tester, '11_workshop_top');
      await _scrollDown(tester, times: 12);
      _drain(tester, 'WorkshopScreen:scroll');
      await _shot(tester, '12_workshop_bottom');
      final blocks = allPracticeChallenges.map((c) => c.blockId).toSet();
      _note('[Workshop] блоков практики в списке: ${blocks.join(', ')} '
          '(всего заданий: ${allPracticeChallenges.length})');
    });

    testWidgets('Практика Mojito: 5 шагов', (tester) async {
      final challenge =
          allPracticeChallenges.firstWhere((c) => c.id == 'practice_mojito');
      await _boot(tester, PracticeFlowScreen(challenge: challenge));
      _drain(tester, 'Practice intro');
      await _shot(tester, '13_practice_step0');
      final started = await _tapText(tester, 'Начать') ||
          await _tapText(tester, 'Далее');
      if (!started) _note('[Practice Mojito] шаг 0: нет кнопки входа в задание');

      _drain(tester, 'Practice step1');
      await _shot(tester, '14_practice_step1_ingredients');
      _note('[Practice Mojito] вариантов ингредиентов на экране: ${_n(find.byType(InkWell))}');
      for (final ing in challenge.correctIngredients) {
        if (!await _tapText(tester, ing)) {
          _note('[Practice Mojito] ингредиент «$ing» не найден в вариантах');
        }
      }
      await _tapText(tester, 'Дальше', contains: true);
      _drain(tester, 'Practice step2');
      await _shot(tester, '15_practice_step2_method');
      final label = methodDescriptions[challenge.correctMethod]?.label;
      if (label == null || !await _tapText(tester, label)) {
        _note('[Practice Mojito] метод «${challenge.correctMethod}» (${label}) недоступен тапом');
      }
      await _tapText(tester, 'Дальше', contains: true);
      _drain(tester, 'Practice step3');
      await _shot(tester, '16_practice_step3_proportions');
      _note('[Practice Mojito] контролы пропорций: Slider=${_n(find.byType(Slider))} '
          'InkWell=${_n(find.byType(InkWell))} GestureDetector=${_n(find.byType(GestureDetector))}');
      await _tapText(tester, 'Проверить');
      _drain(tester, 'Practice result');
      await _shot(tester, '17_practice_result');
    });

    testWidgets('Сопутствующие экраны', (tester) async {
      await _boot(tester, const MissionBriefingScreen(blockId: 'A'));
      _drain(tester, 'Briefing A');
      await _shot(tester, '18_briefing_A');
    });

    testWidgets('Словарь', (tester) async {
      await _boot(tester, const GlossaryScreen());
      _drain(tester, 'Glossary');
      await _shot(tester, '19_glossary');
    });

    testWidgets('Дипломы (заблокированы у нового пользователя)', (tester) async {
      await _boot(tester, const CertificatesScreen());
      _drain(tester, 'Certificates');
      await _shot(tester, '20_certificates');
    });

    testWidgets('Достижения', (tester) async {
      await _boot(tester, const AchievementsScreen());
      _drain(tester, 'Achievements');
      await _shot(tester, '21_achievements');
    });

    testWidgets('Полка бармена', (tester) async {
      await _boot(tester, const BartenderShelfScreen());
      _drain(tester, 'Shelf');
      await _shot(tester, '22_shelf');
    });

    testWidgets('Задания дня', (tester) async {
      await _boot(tester, const DailyQuestsScreen());
      _drain(tester, 'DailyQuests');
      await _shot(tester, '23_daily_quests');
    });

    testWidgets('Сундук мудрости', (tester) async {
      await _boot(tester, const WisdomVaultScreen());
      _drain(tester, 'WisdomVault');
      await _shot(tester, '24_wisdom_vault');
    });
  });

  group('узкий экран 360x640', () {
    setUp(() => _surface = const Size(360, 640));
    tearDown(() => _surface = const Size(411, 891));

    testWidgets('Level 1 на узком экране', (tester) async {
      await _boot(tester, const Level1Screen());
      await _dismissDialog(tester);
      await _dismissDialog(tester);
      _drain(tester, 'narrow Level1');
      await _shot(tester, '30_narrow_level1');
    });

    testWidgets('Урок на узком экране', (tester) async {
      final h = await _boot(tester, const SizedBox.shrink());
      final lesson = h.lessons.getLesson('lesson_A_01')!;
      await _boot(tester, LessonScreen(lesson: lesson));
      _drain(tester, 'narrow Lesson');
      await _shot(tester, '31_narrow_lesson');
      await _tapText(tester, 'Далее');
      _drain(tester, 'narrow Lesson slide2');
      await _shot(tester, '32_narrow_lesson_slide2');
    });

    testWidgets('Практика на узком экране', (tester) async {
      final challenge =
          allPracticeChallenges.firstWhere((c) => c.id == 'practice_mojito');
      await _boot(tester, PracticeFlowScreen(challenge: challenge));
      final s0 = await _tapText(tester, 'Начать') ||
          await _tapText(tester, 'Далее');
      if (!s0) _note('[narrow Practice] шаг 0 не проходит на 360x640');
      _drain(tester, 'narrow Practice');
      await _shot(tester, '33_narrow_practice');
    });
  });
}
