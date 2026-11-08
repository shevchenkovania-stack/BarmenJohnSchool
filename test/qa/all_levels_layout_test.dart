// Аудит вёрстки всех уровней: каждый урок (все слайды), квиз, практика и
// экраны школы — на трёх размерах экрана. Ловит RenderFlex overflow и другие
// layout-ошибки, пишет отчёт в test/qa/LAYOUT_ALL.txt.
//
// Это отчёт, а не эталон композиции: тест падает, только если нашёл overflow.
//
// Запуск:
//   flutter test test/qa/all_levels_layout_test.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show StandardMessageCodec;
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:coin/core/theme/app_theme.dart';
import 'package:coin/features/bartender_school/data/daily_quest_service.dart';
import 'package:coin/features/bartender_school/data/lesson_repository.dart';
import 'package:coin/features/bartender_school/data/practice_challenges.dart';
import 'package:coin/features/bartender_school/data/progress_service.dart';
import 'package:coin/features/bartender_school/data/quiz_repository.dart';
import 'package:coin/features/bartender_school/domain/entities/lesson.dart';
import 'package:coin/features/bartender_school/presentation/screens/certificates_screen.dart';
import 'package:coin/features/bartender_school/presentation/screens/flip_card_screen.dart';
import 'package:coin/features/bartender_school/presentation/screens/glossary_screen.dart';
import 'package:coin/features/bartender_school/presentation/screens/lesson_screen.dart';
import 'package:coin/features/bartender_school/presentation/screens/level1_screen.dart';
import 'package:coin/features/bartender_school/presentation/screens/practice_flow_screen.dart';
import 'package:coin/features/bartender_school/presentation/screens/quiz_screen.dart';
import 'package:coin/features/bartender_school/presentation/screens/workshop_screen.dart';
import 'package:coin/l10n/app_localizations.dart';

/// Размеры экранов: обычный телефон, компактный, очень узкий.
const _surfaces = <String, Size>{
  '411x891': Size(411, 891),
  '360x640': Size(360, 640),
  '320x568': Size(320, 568),
};

final List<String> _findings = <String>[];
Size _surface = _surfaces['411x891']!;
String _surfaceName = '411x891';

bool _offlineFontsInstalled = false;

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
        message.buffer
            .asUint8List(message.offsetInBytes, message.lengthInBytes),
        allowMalformed: true,
      );
      if (key == 'AssetManifest.bin' || key == 'AssetManifest.bin.json') {
        return codec.encodeMessage(manifest);
      }
      if (key.endsWith('.ttf') || key.endsWith('.otf')) return fontBytes;
      final file = File(key);
      if (file.existsSync()) {
        return ByteData.sublistView(
            Uint8List.fromList(file.readAsBytesSync()));
      }
      return null;
    },
  );
}

bool _isFontNoise(String text) =>
    text.contains('allowRuntimeFetching') ||
    text.contains('google_fonts') ||
    text.contains('GoogleFonts');

void _drain(WidgetTester tester, String where) {
  while (true) {
    final e = tester.takeException();
    if (e == null) break;
    final text = e.toString();
    final first = text.split('\n').first.trim();
    if (_isFontNoise(text)) continue;
    // Ищем строку, где Flutter указывает виновника.
    final culprit = text
        .split('\n')
        .where((l) =>
            l.contains('The relevant error-causing widget was') ||
            (l.contains('.dart:') && !l.contains('flutter/')))
        .take(2)
        .map((l) => l.trim())
        .join(' | ');
    _findings.add('[$_surfaceName][$where] $first${culprit.isEmpty ? '' : ' → $culprit'}');
  }
}

Future<void> _settle(WidgetTester tester) async {
  try {
    await tester.pumpAndSettle(
      const Duration(milliseconds: 120),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 2),
    );
  } catch (_) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

class Harness {
  Harness(this.lessons, this.quizzes, this.progress);
  final LessonRepository lessons;
  final QuizRepository quizzes;
  final ProgressService progress;
}

Future<Harness> _boot(WidgetTester tester, Widget screen,
    {Map<String, Object>? prefs, Harness? reuse}) async {
  _installOfflineFonts(tester);
  SharedPreferences.setMockInitialValues(prefs ?? <String, Object>{});
  final sp = await SharedPreferences.getInstance();

  final lessonRepo = reuse?.lessons ?? LessonRepository();
  final quizRepo = reuse?.quizzes ?? QuizRepository();
  if (reuse == null) {
    await tester.runAsync(() async {
      await lessonRepo.loadCoreCurriculum();
      await lessonRepo.loadWisdom();
      await quizRepo.loadQuizzes();
    });
  }
  final progress = ProgressService(sp, lessonRepo: lessonRepo);

  await tester.binding.setSurfaceSize(_surface);
  tester.view.physicalSize = _surface * 3;
  tester.view.devicePixelRatio = 3.0;
  addTearDown(() {
    tester.binding.setSurfaceSize(null);
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

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

/// Закрыть пролог/брифинг, если он перехватил экран.
Future<void> _dismissOverlays(WidgetTester tester) async {
  for (var pass = 0; pass < 3; pass++) {
    var tapped = false;
    for (final label in [
      'Начать обучение',
      'Понятно',
      'Продолжить',
      'Закрыть',
      'Ок',
      'Пропустить',
    ]) {
      final f = find.text(label);
      if (f.evaluate().isEmpty) continue;
      await tester.tap(f.first, warnIfMissed: false);
      await _settle(tester);
      tapped = true;
    }
    if (!tapped) break;
  }
}

/// Прокрутить все вертикальные скроллы экрана до конца.
Future<void> _scrollAll(WidgetTester tester) async {
  for (var round = 0; round < 3; round++) {
    final scrollables = find.byType(Scrollable);
    final count = scrollables.evaluate().length;
    for (var i = 0; i < count; i++) {
      try {
        await tester.drag(scrollables.at(i), const Offset(0, -300),
            warnIfMissed: false);
        await _settle(tester);
      } catch (_) {
        // не скроллится — пропускаем
      }
    }
  }
}

void main() {
  setUpAll(() async {
    await _registerFonts();
  });

  tearDownAll(() {
    final buffer = StringBuffer();
    buffer.writeln('# Аудит вёрстки всех уровней');
    buffer.writeln();
    if (_findings.isEmpty) {
      buffer.writeln('переполнений и ошибок вёрстки не найдено');
    } else {
      buffer.writeln('найдено проблем: ${_findings.length}');
      buffer.writeln();
      for (final f in _findings) {
        buffer.writeln(f);
      }
    }
    File('test/qa/LAYOUT_ALL.txt').writeAsStringSync(buffer.toString());
  });

  for (final entry in _surfaces.entries) {
    _surfaceName = entry.key;
    _surface = entry.value;

    testWidgets('${entry.key}: уроки всех уровней, все слайды', (tester) async {
      final h = await _boot(tester, const SizedBox.shrink());
      final lessons = h.lessons.lessons;
      for (final lesson in lessons) {
        // Каждый урок отрисовываем слайд за слайдом: заголовок, ментор,
        // буллеты, интерактивные ветки — всё внутри PageView.
        await _boot(tester, _SlideProbe(lesson: lesson), reuse: h);
        await _settle(tester);
        _drain(tester, 'lesson ${lesson.id} slide1');
        for (var i = 1; i < lesson.slides.length; i++) {
          await tester.drag(find.byType(PageView).first, const Offset(-400, 0),
              warnIfMissed: false);
          await _settle(tester);
          _drain(tester, 'lesson ${lesson.id} slide${i + 1}');
        }
      }
    });

    testWidgets('${entry.key}: карточка урока каждого уровня', (tester) async {
      final h = await _boot(tester, const SizedBox.shrink());
      // По одной карточке из каждого блока + экзамены.
      final sample = <String>[
        'lesson_A_01', 'lesson_B_05', 'lesson_C_09', 'lesson_C_12',
        'lesson_D_13', 'lesson_E_17', 'lesson_F_21', 'lesson_F_24',
      ];
      for (final id in sample) {
        final lesson = h.lessons.getLesson(id);
        if (lesson == null) {
          _findings.add('[$_surfaceName][flip $id] урок не найден в репозитории');
          continue;
        }
        await _boot(tester, FlipCardScreen(lesson: lesson), reuse: h);
        await _settle(tester);
        _drain(tester, 'flip $id front');
        await _scrollAll(tester);
        _drain(tester, 'flip $id scrolled');
        // Обратная сторона карточки.
        final flip = find.textContaining('К ключевым');
        if (flip.evaluate().isNotEmpty) {
          await tester.tap(flip.first, warnIfMissed: false);
          await _settle(tester);
          _drain(tester, 'flip $id back');
        }
      }
    });

    testWidgets('${entry.key}: квизы всех уровней, каждый вопрос', (tester) async {
      final h = await _boot(tester, const SizedBox.shrink());
      for (final lesson in h.lessons.lessons) {
        final quiz = h.quizzes.getQuiz(lesson.id);
        if (quiz == null) continue;
        await _boot(tester, QuizScreen(lessonId: lesson.id), reuse: h);
        await _settle(tester);
        _drain(tester, 'quiz ${lesson.id} load');
        // Проходим вопросы до конца: именно в вариантах ответа, matching,
        // sequence и slider живут самые тесные строки.
        for (var q = 0; q < 12; q++) {
          final before = find.byType(QuizScreen).evaluate().length;
          if (before == 0) break;
          final options = find.byType(InkWell);
          if (options.evaluate().isEmpty) break;
          await tester.tap(options.first, warnIfMissed: false);
          await _settle(tester);
          _drain(tester, 'quiz ${lesson.id} q${q + 1} answer');
          final next = find.widgetWithText(ElevatedButton, 'Далее');
          final finish = find.widgetWithText(ElevatedButton, 'Завершить');
          final check = find.widgetWithText(ElevatedButton, 'Проверить');
          final advance = next.evaluate().isNotEmpty
              ? next
              : (check.evaluate().isNotEmpty ? check : finish);
          if (advance.evaluate().isEmpty) break;
          await tester.tap(advance.first, warnIfMissed: false);
          await _settle(tester);
          _drain(tester, 'quiz ${lesson.id} q${q + 1} next');
        }
      }
    });

    testWidgets('${entry.key}: практика всех заданий, все шаги', (tester) async {
      final h = await _boot(tester, const SizedBox.shrink());
      for (final c in allPracticeChallenges) {
        await _boot(tester, PracticeFlowScreen(challenge: c), reuse: h);
        await _settle(tester);
        _drain(tester, 'practice ${c.id} intro');
        // Прогоняем шаги до результата: чипы ингредиентов и слайдер
        // джиггера на узком экране — главные кандидаты на переполнение.
        for (var step = 0; step < 8; step++) {
          final advance = find.widgetWithText(ElevatedButton, 'Далее');
          final cont = find.widgetWithText(ElevatedButton, 'Продолжить');
          final check = find.widgetWithText(ElevatedButton, 'Проверить');
          final f = advance.evaluate().isNotEmpty
              ? advance
              : (cont.evaluate().isNotEmpty ? cont : check);
          if (f.evaluate().isEmpty) break;
          await tester.tap(f.first, warnIfMissed: false);
          await _settle(tester);
          _drain(tester, 'practice ${c.id} step${step + 1}');
        }
      }
    });

    testWidgets('${entry.key}: экраны школы', (tester) async {
      final screens = <String, Widget>{
        'Level1': const Level1Screen(),
        'Workshop': const WorkshopScreen(),
        'Glossary': const GlossaryScreen(),
        'Certificates': const CertificatesScreen(),
      };
      for (final e in screens.entries) {
        await _boot(tester, e.value);
        await _settle(tester);
        await _dismissOverlays(tester);
        _drain(tester, e.key);
        await _scrollAll(tester);
        _drain(tester, '${e.key}:scrolled');
      }
    });
  }

  testWidgets('итог: переполнений не найдено', (tester) async {
    // Отчёт уже собран в tearDownAll; здесь только громкий сигнал.
    expect(_findings, isEmpty,
        reason: 'см. test/qa/LAYOUT_ALL.txt — ${_findings.length} проблем');
  });
}

/// Показывает урок в LessonScreen и позволяет листать все слайды.
class _SlideProbe extends StatelessWidget {
  final Lesson lesson;
  const _SlideProbe({required this.lesson});

  @override
  Widget build(BuildContext context) => LessonScreen(lesson: lesson);
}
