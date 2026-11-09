// Аудит: системный масштаб шрифта 0.8 / 1.0 / 1.3 / 2.0 на уроках и квизе.
//
//   flutter test test/qa/font_scale_layout_test.dart
//
// Отчёт: test/qa/FONT_SCALE.txt
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:coin/core/theme/app_theme.dart';
import 'package:coin/features/bartender_school/data/blind_tasting.dart';
import 'package:coin/features/bartender_school/data/daily_quest_service.dart';
import 'package:coin/features/bartender_school/data/guest_echo.dart';
import 'package:coin/features/bartender_school/data/lesson_repository.dart';
import 'package:coin/features/bartender_school/data/progress_service.dart';
import 'package:coin/features/bartender_school/data/quiz_repository.dart';
import 'package:coin/features/bartender_school/data/weekly_contract.dart';
import 'package:coin/features/bartender_school/domain/entities/lesson.dart';
import 'package:coin/features/bartender_school/presentation/screens/lesson_screen.dart';
import 'package:coin/features/bartender_school/presentation/screens/quiz_screen.dart';
import 'package:coin/features/bartender_school/presentation/screens/school_home_screen.dart';
import 'package:coin/l10n/app_localizations.dart';

const _scales = <double>[0.8, 1.0, 1.3, 2.0];
const _surface = Size(360, 640);

final List<String> _findings = <String>[];
String _where = '';

class _Harness {
  _Harness(this.lessons, this.quizzes, this.progress);
  final LessonRepository lessons;
  final QuizRepository quizzes;
  final ProgressService progress;
}

Future<_Harness> _boot(
  WidgetTester tester,
  Widget screen, {
  double scale = 1.0,
  _Harness? reuse,
}) async {
  final bytes = Uint8List.fromList(
      File('assets/fonts/Georgia-Regular.ttf').readAsBytesSync());
  await ui.loadFontFromList(bytes, fontFamily: 'serif');

  SharedPreferences.setMockInitialValues(<String, Object>{});
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
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(() {
    tester.binding.setSurfaceSize(null);
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
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
        ChangeNotifierProvider<WeeklyContractService>(
          create: (_) => WeeklyContractService(sp),
        ),
        ChangeNotifierProvider<BlindTastingService>(
          create: (_) => BlindTastingService(sp),
        ),
        Provider<GuestEchoService>(create: (_) => GuestEchoService(sp)),
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
  return _Harness(lessonRepo, quizRepo, progress);
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

void _drain(WidgetTester tester) {
  while (true) {
    final e = tester.takeException();
    if (e == null) break;
    final text = e.toString();
    final first = text.split('\n').first.trim();
    if (first.contains('google_fonts') || first.contains('allowRuntime')) {
      continue;
    }
    _findings.add('[$_where] $first');
  }
}

Future<void> _scrollAll(WidgetTester tester) async {
  final scrollables = find.byType(Scrollable);
  for (var i = 0; i < scrollables.evaluate().length; i++) {
    try {
      await tester.drag(scrollables.at(i), const Offset(0, -260));
      await _settle(tester);
      await tester.drag(scrollables.at(i), const Offset(0, 260));
      await _settle(tester);
    } catch (_) {
      // Не все Scrollable принимают drag — это не ошибка вёрстки.
    }
  }
}

void main() {
  tearDownAll(() {
    final out = StringBuffer()
      ..writeln('# Аудит системного масштаба шрифта')
      ..writeln();
    if (_findings.isEmpty) {
      out.writeln('переполнений не найдено на 0.8 / 1.0 / 1.3 / 2.0');
    } else {
      for (final f in _findings) {
        out.writeln(f);
      }
    }
    File('test/qa/FONT_SCALE.txt').writeAsStringSync(out.toString());
  });

  for (final scale in _scales) {
    testWidgets('масштаб $scale: урок, квиз, главная', (tester) async {
      final h = await _boot(tester, const SizedBox.shrink(), scale: scale);

      // Урок: все слайды самого длинного урока Level 1.
      final lesson = h.lessons.getLesson('lesson_A_01')!;
      _where = 'scale $scale / lesson A_01';
      await _boot(tester, _SlideProbe(lesson: lesson), scale: scale, reuse: h);
      _drain(tester);
      await _scrollAll(tester);
      _drain(tester);

      _where = 'scale $scale / quiz A_01';
      await _boot(
        tester,
        const QuizScreen(lessonId: 'lesson_A_01'),
        scale: scale,
        reuse: h,
      );
      _drain(tester);
      await _scrollAll(tester);
      _drain(tester);

      _where = 'scale $scale / home';
      await _boot(tester, const SchoolHomeScreen(), scale: scale, reuse: h);
      _drain(tester);
      await _scrollAll(tester);
      _drain(tester);
    });
  }

  testWidgets('итог: под масштабом шрифта переполнений нет', (tester) async {
    expect(_findings, isEmpty,
        reason: 'см. test/qa/FONT_SCALE.txt — ${_findings.length} проблем');
  });
}

class _SlideProbe extends StatelessWidget {
  final Lesson lesson;
  const _SlideProbe({required this.lesson});

  @override
  Widget build(BuildContext context) => LessonScreen(lesson: lesson);
}
