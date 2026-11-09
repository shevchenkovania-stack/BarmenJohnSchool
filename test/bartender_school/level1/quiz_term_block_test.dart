// Регрессия: блок терминов в квизе обязан заканчиваться и передавать
// управление вопросам урока, а нумерация шагов — не перескакивать.
//
// Раньше на последнем термине индекс не переводился за границу списка,
// поэтому `inTermBlock` оставался true и квиз навсегда застревал.
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
import 'package:coin/features/bartender_school/presentation/screens/quiz_screen.dart';
import 'package:coin/l10n/app_localizations.dart';

Future<void> _boot(WidgetTester tester, Widget screen) async {
  final bytes = Uint8List.fromList(
      File('assets/fonts/Georgia-Regular.ttf').readAsBytesSync());
  await ui.loadFontFromList(bytes, fontFamily: 'serif');

  SharedPreferences.setMockInitialValues(<String, Object>{});
  final sp = await SharedPreferences.getInstance();
  final lessonRepo = LessonRepository();
  final quizRepo = QuizRepository();
  await tester.runAsync(() async {
    await lessonRepo.loadCoreCurriculum();
    await lessonRepo.loadWisdom();
    await quizRepo.loadQuizzes();
  });
  final progress = ProgressService(sp, lessonRepo: lessonRepo);

  await tester.binding.setSurfaceSize(const Size(411, 891));
  tester.view.physicalSize = const Size(411, 891) * 3;
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
  await tester.pumpAndSettle(const Duration(milliseconds: 100));
}

Finder _termHeader() => find.textContaining('Термины урока ·');

void main() {
  testWidgets('блок терминов проходится до конца и отдаёт вопросы урока',
      (tester) async {
    await _boot(tester, const QuizScreen(lessonId: 'lesson_A_01'));

    expect(_termHeader(), findsOneWidget,
        reason: 'у урока A_01 должны быть вопросы по терминам');

    // Заголовок не должен врать: первый терминовый шаг — это 1 из N.
    expect(find.textContaining('Термины · 1/'), findsOneWidget,
        reason: 'на первом термине шаг должен быть 1, а не 5');

    // Проходим все термины, отвечая на каждый.
    for (var guard = 0; guard < 20; guard++) {
      if (_termHeader().evaluate().isEmpty) break;

      // Варианты ответа — это InkWell с onTap, но кнопка «К вопросам урока»
      // тоже TextButton с внутренним InkWell и стоит в заголовке первой.
      // Отсекаем её по тексту, который лежит внутри.
      final options = find.byWidgetPredicate((w) {
        if (w is! InkWell || w.onTap == null) return false;
        final own = find
            .descendant(
              of: find.byWidget(w),
              matching: find.text('К вопросам урока'),
            )
            .evaluate();
        return own.isEmpty;
      });
      expect(options, findsWidgets,
          reason: 'в термине должны быть варианты ответа');
      await tester.tapAt(tester.getCenter(options.first));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      // Без фиксации ответа кнопки перехода не будет — это и был стопор.
      final next = find.byKey(const Key('quiz_term_next'));
      expect(next, findsOneWidget,
          reason: 'выбор варианта должен фиксироваться');
      await tester.tap(next, warnIfMissed: false);
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
    }

    // Главное: блок терминов закрылся, и мы в вопросах урока. Именно здесь
    // раньше нельзя было пройти дальше — экран застревал на последнем термине.
    expect(_termHeader(), findsNothing,
        reason: 'блок терминов обязан закончиться — раньше он застревал');
    expect(find.textContaining('Квиз • Вопросы'), findsOneWidget,
        reason: 'после терминов начинаются вопросы урока');
    // Первый вопрос урока действительно открыт и доступен для ответа.
    expect(find.byType(InkWell, skipOffstage: false), findsWidgets,
        reason: 'вопрос урока должен иметь варианты ответа');
  });

  testWidgets('кнопка «К вопросам урока» сразу пропускает термины',
      (tester) async {
    await _boot(tester, const QuizScreen(lessonId: 'lesson_A_01'));

    final skip = find.text('К вопросам урока');
    expect(skip, findsOneWidget);
    await tester.tap(skip.first, warnIfMissed: false);
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(_termHeader(), findsNothing,
        reason: 'пропуск терминов должен сразу открыть вопросы урока');
    expect(find.textContaining('Квиз • Вопросы'), findsOneWidget);
  });
}
