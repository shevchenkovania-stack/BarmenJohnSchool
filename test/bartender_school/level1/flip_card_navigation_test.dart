// Регрессия: кнопка «Начать урок» на открытой карточке ОБЯЗАНА открывать
// урок, а не переворачивать карточку.
//
// Раньше переворот висел на всей площади карточки: тап по кнопке
// перехватывался жестом переворота, и в урок попасть было нельзя вообще —
// ни с одной карточки.
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
import 'package:coin/features/bartender_school/presentation/screens/flip_card_screen.dart';
import 'package:coin/features/bartender_school/presentation/screens/lesson_screen.dart';
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

/// Переворачивает карточку на обратную сторону через кнопку «К ключевым
/// точкам». Тап по тексту истории тоже переворачивает — проверяем оба пути.
Future<void> _flipToBack(WidgetTester tester) async {
  await tester.tap(find.text('К ключевым точкам'));
  await tester.pumpAndSettle(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('«Начать урок» открывает урок, а не переворачивает карточку',
      (tester) async {
    final lessons = LessonRepository();
    await tester.runAsync(lessons.loadCoreCurriculum);
    final lesson = lessons.getLesson('lesson_A_02')!;

    await _boot(tester, FlipCardScreen(lesson: lesson));

    // Лицевая сторона: история Джона + кнопка входа в урок.
    expect(find.text('Начать урок'), findsOneWidget);

    // Тап по тексту истории переворачивает карточку.
    await tester.tapAt(tester.getCenter(find.textContaining('Лайм и лимон')));
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    expect(find.text('Начать урок'), findsNothing,
        reason: 'на обороте кнопки входа в урок нет');

    // Возвращаемся на лицевую и входим в урок.
    await _flipToBack(tester);
    expect(find.text('Начать урок'), findsOneWidget);

    await tester.tap(find.text('Начать урок'));
    await tester.pumpAndSettle(const Duration(milliseconds: 400));

    expect(find.byType(LessonScreen), findsOneWidget,
        reason: 'тап по «Начать урок» обязан открыть урок');
    expect(find.textContaining('из '), findsWidgets);
  });
}
