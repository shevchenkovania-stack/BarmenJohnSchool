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
import 'package:coin/features/bartender_school/presentation/screens/lesson_screen.dart';
import 'package:coin/features/bartender_school/presentation/widgets/quest_scene_view.dart';
import 'package:coin/l10n/app_localizations.dart';

Future<LessonRepository> _boot(WidgetTester tester, Widget screen) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final sp = await SharedPreferences.getInstance();
  final lessonRepo = LessonRepository();
  final quizRepo = QuizRepository();
  await tester.runAsync(() async {
    await lessonRepo.loadCoreCurriculum();
    await quizRepo.loadQuizzes();
  });
  final progress = ProgressService(sp, lessonRepo: lessonRepo);

  await tester.binding.setSurfaceSize(const Size(411, 1200));
  tester.view.physicalSize = const Size(411, 1200) * 3;
  tester.view.devicePixelRatio = 3.0;

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
  await tester.pumpAndSettle(const Duration(milliseconds: 300));
  return lessonRepo;
}

void main() {
  testWidgets('урок A_01 начинается со сцены-квеста', (tester) async {
    final repo = await _boot(tester, const SizedBox.shrink());
    final lesson = repo.getLesson('lesson_A_01')!;

    await _boot(tester, LessonScreen(lesson: lesson));

    expect(find.byType(QuestSceneView), findsOneWidget);
    expect(find.textContaining('1874'), findsOneWidget);
    expect(find.textContaining('Пятая авеню'), findsWidgets);
  });

  testWidgets('сцену нельзя пройти без вопроса', (tester) async {
    final repo = await _boot(tester, const SizedBox.shrink());
    final lesson = repo.getLesson('lesson_A_01')!;
    await _boot(tester, LessonScreen(lesson: lesson));

    // Сначала реплики сцены листаются кнопкой «Дальше».
    final beats = lesson.slides.first.questScene!.beats.length;
    for (var i = 0; i < beats; i++) {
      final next = find.byKey(const Key('quest_next_beat'));
      if (next.evaluate().isEmpty) break;
      await tester.tap(next);
      await tester.pump();
      await tester.pump();
    }

    expect(find.textContaining('Сначала спроси'), findsOneWidget);
  });

  testWidgets('после сцены обычные слайды идут как раньше', (tester) async {
    final repo = await _boot(tester, const SizedBox.shrink());
    final lesson = repo.getLesson('lesson_A_01')!;

    // Сцена есть только в первом слайде, остальные — обычная теория.
    expect(lesson.slides.length, greaterThanOrEqualTo(2));
    expect(lesson.slides.first.questScene, isNotNull);
    for (final slide in lesson.slides.skip(1)) {
      expect(slide.questScene, isNull,
          reason: 'сцена не должна протекать в другие слайды');
    }
  });

  testWidgets('уроки без сцены открываются как прежде', (tester) async {
    final repo = await _boot(tester, const SizedBox.shrink());

    for (final id in ['lesson_A_02', 'lesson_A_03', 'lesson_B_05']) {
      final lesson = repo.getLesson(id)!;
      expect(lesson.slides.first.questScene, isNull, reason: id);
    }

    final lesson = repo.getLesson('lesson_A_02')!;
    await _boot(tester, LessonScreen(lesson: lesson));
    expect(find.byType(QuestSceneView), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('во всех уроках Level 1 сцена максимум одна', (tester) async {
    final repo = await _boot(tester, const SizedBox.shrink());
    var total = 0;
    for (final lesson in repo.lessons) {
      final scenes = lesson.slides.where((s) => s.questScene != null).length;
      expect(scenes, lessThanOrEqualTo(1), reason: lesson.id);
      total += scenes;
    }
    expect(total, 1, reason: 'сцена пока только в A_01');
  });
}
