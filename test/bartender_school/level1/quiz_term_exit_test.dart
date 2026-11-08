// Регрессия: из блока терминов всегда есть выход.
//
// 1. «Мексиканский локоть» — ручной пресс для цитрусовых, а не «привычка пить
//    текилу с лаймом»: квиз урока A_02 проверял ложное определение.
// 2. На последнем термине без выбранного ответа не было ни одной кнопки вне
//    прокрутки: квиз читался как тупик, «куда ни нажми — нет продолжения».
// 3. Выход после результата снимал до трёх экранов подряд и терял сам урок.
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
import 'package:coin/features/bartender_school/data/term_service.dart';
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
  test('у «Мексиканского локтя» описание инструмента, а не привычки', () {
    final term = TermService().getTerm('Мексиканский локоть');
    expect(term, isNotNull);
    expect(term!.category, 'Инструмент');
    expect(term.definition.toLowerCase(), contains('пресс'));
    expect(term.definition.toLowerCase(), isNot(contains('текил')));
  });

  test('вопросы по терминам стабильны при одном seed', () {
    final service = TermService();
    const terms = ['Свежевыжатый сок', 'Мексиканский локоть'];
    final first = service.generateQuiz(terms, maxQuestions: 4, seed: 42);
    final second = service.generateQuiz(terms, maxQuestions: 4, seed: 42);
    expect(first.map((q) => q.question).toList(),
        second.map((q) => q.question).toList());
    expect(first.first.options, second.first.options);
  });

  testWidgets('из последнего термина без ответа можно уйти кнопкой внизу',
      (tester) async {
    await _boot(tester, const QuizScreen(lessonId: 'lesson_A_02'));

    expect(_termHeader(), findsOneWidget,
        reason: 'у урока A_02 должны быть вопросы по терминам');

    // Долистываем до последнего термина, ни разу не отвечая: именно в этом
    // состоянии раньше не было ни одной кнопки перехода.
    // Читаем счётчик из заголовка блока, а не из AppBar: AppBar показывает
    // шаг всей сессии (включая вопросы урока).
    var total = 0;
    for (var guard = 0; guard < 10; guard++) {
      final skip = find.byKey(const Key('quiz_term_footer_skip'));
      expect(skip, findsOneWidget,
          reason: 'нижняя панель должна быть видна на каждом термине');

      final next = find.byKey(const Key('quiz_term_footer_next'));
      expect(tester.widget<ElevatedButton>(next).onPressed, isNull,
          reason: 'без ответа «Дальше» неактивна');

      final header = tester.widget<Text>(_termHeader()).data!;
      total = _termCount(header);
      // На последнем термине выходим ровно той кнопкой, которой пользователь
      // и не мог найти выход: нижняя панель вне прокрутки.
      final isLast = header.endsWith('$total/$total');
      await tester.tap(skip);
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      if (isLast) break;
      if (_termHeader().evaluate().isEmpty) break;
    }

    expect(total, greaterThan(0));

    expect(_termHeader(), findsNothing,
        reason: 'из блока терминов обязан быть выход');
    expect(find.textContaining('Квиз • Вопросы'), findsOneWidget);
  });
}

/// «Термины урока · 3/3» → 3.
int _termCount(String header) {
  final tail = header.split('·').last.trim();
  return int.parse(tail.split('/').last);
}
