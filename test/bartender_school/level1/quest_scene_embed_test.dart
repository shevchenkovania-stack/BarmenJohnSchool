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
import 'package:coin/features/bartender_school/presentation/widgets/quest_investigation_view.dart';
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
  testWidgets('урок A_01 открывается сценой квеста', (tester) async {
    final repo = await _boot(tester, const SizedBox.shrink());
    final lesson = repo.getLesson('lesson_A_01')!;

    expect(lesson.quest, isNotNull,
        reason: 'A_01 должен нести квест, а не плоский список слайдов');
    await _boot(tester, LessonScreen(lesson: lesson));

    // Первый экран — сцена: гость говорит про вчерашний стакан.
    // Текст печатается посимвольно, поэтому искать целую фразу сразу
    // нельзя: проверяем сам виджет сцены и её данные.
    expect(tester.takeException(), isNull);
    expect(find.byType(QuestSceneView), findsOneWidget);
    expect(lesson.slides.first.questScene!.probes.length, 3);
    expect(lesson.slides.first.questScene!.answers.length, 3);
  });

  testWidgets('слайд расследования показывает вопросы гостю', (tester) async {
    final repo = await _boot(tester, const SizedBox.shrink());
    final lesson = repo.getLesson('lesson_A_01')!;
    final flow = lesson.quest!;

    await _boot(
      tester,
      LessonScreen(lesson: lesson, initialSlide: 1),
    );

    expect(find.byType(QuestInvestigationView), findsOneWidget);
    // Вопросы видны все три: их можно задавать в любом порядке.
    for (final item in flow.investigation.items) {
      expect(find.byKey(Key('quest_ask_${item.id}')), findsOneWidget,
          reason: item.id);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('сцена не протекает в другие слайды', (tester) async {
    final repo = await _boot(tester, const SizedBox.shrink());
    final lesson = repo.getLesson('lesson_A_01')!;

    expect(lesson.slides.length, greaterThanOrEqualTo(2));
    // A_01 идёт путём `questScene`, как A_02–A_04: сцена стоит первым
    // слайдом, остальные слайды сцены не несут.
    expect(lesson.slides.first.questScene, isNotNull);
    final withScene =
        lesson.slides.where((s) => s.questScene != null).length;
    expect(withScene, 1,
        reason: 'сцена только на первом слайде A_01');
    // questRef остаётся у четырёх сценарных слайдов квеста:
    // investigation, serve, outcomes, progression.
    final withRef =
        lesson.slides.where((s) => (s.questRef ?? '').isNotEmpty).length;
    expect(withRef, 4,
        reason: 'investigation, serve, outcomes, progression');
  });

  testWidgets('уроки без сцены открываются как прежде', (tester) async {
    final repo = await _boot(tester, const SizedBox.shrink());

    for (final id in ['lesson_B_05', 'lesson_B_06', 'lesson_B_07']) {
      final lesson = repo.getLesson(id)!;
      expect(lesson.slides.first.questScene, isNull, reason: id);
    }

    final lesson = repo.getLesson('lesson_B_05')!;
    await _boot(tester, LessonScreen(lesson: lesson));
    expect(find.byType(QuestSceneView), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('в каждом уроке максимум одна сцена, и она первая',
      (tester) async {
    final repo = await _boot(tester, const SizedBox.shrink());
    var total = 0;
    for (final lesson in repo.lessons) {
      final scenes = lesson.slides.where((s) => s.questScene != null).length;
      expect(scenes, lessThanOrEqualTo(1), reason: lesson.id);
      if (scenes == 1) {
        expect(lesson.slides.first.questScene, isNotNull,
            reason: 'сцена должна открывать урок: ${lesson.id}');
      }
      total += scenes;
    }
    // Блок A — четыре вкуса, у каждого своя сцена, и все четыре идут
    // одним путём `questScene`.
    expect(total, 4, reason: 'сцены в A_01…A_04');
  });
}
