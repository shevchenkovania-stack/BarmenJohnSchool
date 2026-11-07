// TEMP QA: сквозной проход Level 1 по реальному пути пользователя.
//   карточка → урок (все слайды) → «К тесту» → квиз терминов → квиз → практика → диплом
// Пишет отчёт в test/qa/FLOW.txt. Запуск:
//   flutter test test/qa/level1_flow_test.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:coin/core/theme/app_theme.dart';
import 'package:coin/core/repositories/cocktail_repository.dart';
import 'package:coin/core/services/cocktail_cache_service.dart';
import 'package:coin/features/home/home_viewmodel.dart';
import 'package:coin/features/bartender_school/data/daily_quest_service.dart';
import 'package:coin/features/bartender_school/data/lesson_repository.dart';
import 'package:coin/features/bartender_school/data/practice_challenges.dart';
import 'package:coin/features/bartender_school/data/progress_service.dart';
import 'package:coin/features/bartender_school/data/quiz_repository.dart';
import 'package:coin/features/bartender_school/data/term_service.dart';
import 'package:coin/features/bartender_school/domain/entities/progress.dart';
import 'package:coin/features/bartender_school/domain/entities/quiz.dart';
import 'package:coin/features/bartender_school/presentation/screens/certificates_screen.dart';
import 'package:coin/features/bartender_school/presentation/screens/lesson_screen.dart';
import 'package:coin/features/bartender_school/presentation/screens/practice_flow_screen.dart';
import 'package:coin/features/bartender_school/presentation/screens/level1_screen.dart';
import 'package:coin/features/bartender_school/presentation/screens/quiz_screen.dart';
import 'package:coin/features/bartender_school/presentation/screens/term_quiz_screen.dart';
import 'package:coin/features/bartender_school/presentation/screens/workshop_screen.dart';
import 'package:coin/features/bartender_school/data/weekly_contract.dart';
import 'package:coin/features/bartender_school/data/blind_tasting.dart';
import 'package:coin/features/bartender_school/data/guest_echo.dart';
import 'package:coin/l10n/app_localizations.dart';
import 'package:coin/shell/main_shell.dart';

final List<String> notes = <String>[];
void say(String s) {
  notes.add(s);
  // ignore: avoid_print
  print('QA> ${s.length > 200 ? s.substring(0, 200) + '…' : s}');
}

Future<void> _registerFonts() async {
  final path = File('C:/Windows/Fonts/georgia.ttf').existsSync()
      ? 'C:/Windows/Fonts/georgia.ttf'
      : 'C:/Windows/Fonts/arial.ttf';
  final bytes = Uint8List.fromList(File(path).readAsBytesSync());
  for (final family in [
    'Cinzel', 'Cormorant Garamond', 'EB Garamond',
    'Nunito', 'Nunito Sans', 'Noto Sans', 'Roboto',
  ]) {
    await ui.loadFontFromList(bytes, fontFamily: family);
  }
}

/// Строки «RenderFlex overflowed» без адреса бесполезны: тестовый binding
/// хранит ошибки молча, поэтому собираем полный дамп сами.
final List<String> _layoutDumps = [];

void _silenceFontNoise() {
  final previous = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    final text = details.exception.toString();
    if (text.contains('allowRuntimeFetching') ||
        text.contains('GoogleFonts was unable')) {
      return;
    }
    if (text.contains('overflowed by')) {
      String dump = '';
      try {
        dump = details.toString();
      } catch (_) {
        dump = text;
      }
      _layoutDumps.add(dump);
    }
    previous?.call(details);
  };
}

class Harness {
  Harness(this.lessons, this.quizzes, this.progress, this.prefs);
  final LessonRepository lessons;
  final QuizRepository quizzes;
  final ProgressService progress;
  final SharedPreferences prefs;
}

Future<Harness> _boot(WidgetTester tester, Widget screen,
    {Map<String, Object>? prefs, Harness? reuse,
    Size surface = const Size(411, 891), bool wisdom = false,
    bool homeDeps = false, bool settle = true}) async {
  // reuse == null → чистый лист; reuse != null → продолжаем ту же сессию
  // прогресса (иначе setMockInitialValues стирает XP/звёзды предыдущего шага).
  if (reuse != null) {
    // хранилище не трогаем
  } else {
    SharedPreferences.setMockInitialValues(prefs ?? <String, Object>{});
  }
  final sp = reuse?.prefs ?? await SharedPreferences.getInstance();
  final lessonRepo = reuse?.lessons ?? LessonRepository();
  final quizRepo = reuse?.quizzes ?? QuizRepository();
  if (reuse == null) {
    await tester.runAsync(() async {
      await lessonRepo.loadCoreCurriculum();
      await quizRepo.loadQuizzes();
      if (wisdom) await lessonRepo.loadWisdom();
    });
  }
  final progress = reuse?.progress ?? ProgressService(sp, lessonRepo: lessonRepo);

  await tester.binding.setSurfaceSize(surface);
  tester.view.physicalSize = surface * 3;
  tester.view.devicePixelRatio = 3.0;
  addTearDown(() => tester.binding.setSurfaceSize(null));

  // Принудительный демонтаж прошлого экрана: без этого root-тип тот же
  // (MultiProvider→MaterialApp→LessonScreen) и Flutter переиспользует State
  // прошлого урока — _currentPage остаётся с последней страницы.
  await tester.pumpWidget(const SizedBox.shrink());
  final providers = [
    Provider<SharedPreferences>.value(value: sp),
    ChangeNotifierProvider<LessonRepository>.value(value: lessonRepo),
    ChangeNotifierProvider<QuizRepository>.value(value: quizRepo),
    ChangeNotifierProvider<ProgressService>.value(value: progress),
    ChangeNotifierProvider<DailyQuestService>(
        create: (_) => DailyQuestService(sp)),
    // Механики-надстройки: квиз и мастерская пишут в них прогресс, поэтому
    // без них оболочка падает на первом же экране.
    ChangeNotifierProvider<WeeklyContractService>(
        create: (_) => WeeklyContractService(sp)),
    ChangeNotifierProvider<BlindTastingService>(
        create: (_) => BlindTastingService(sp)),
    Provider<GuestEchoService>(create: (_) => GuestEchoService(sp)),
    // HomeScreen внутри MainShell требует свой ViewModel — без него оболочку
    // на узком экране не проверить.
    if (homeDeps)
      ChangeNotifierProvider<HomeViewModel>(
        create: (_) =>
            HomeViewModel(CocktailRepository(), CocktailCacheService()),
      ),
  ];
  await tester.pumpWidget(
    MultiProvider(
      providers: providers,
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
  // settle=false для экранов с бесконечной анимацией: pumpAndSettle там
  // уходит в таймаут, а для замера вёрстки хватает двух кадров.
  if (settle) {
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
  } else {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }
  return Harness(lessonRepo, quizRepo, progress, sp);
}

void _drain(WidgetTester tester, String where) {
  while (true) {
    final e = tester.takeException();
    if (e == null) break;
    say('[LAYOUT][$where] ${e.toString().split('\n').first.trim()}');
  }
}

bool _has(Finder f) {
  try {
    return f.evaluate().isNotEmpty;
  } catch (_) {
    return false;
  }
}

int _n(Finder f) {
  try {
    return f.evaluate().length;
  } catch (_) {
    return 0;
  }
}

List<String> _texts(WidgetTester tester, {int take = 45}) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => (t.data ?? '').replaceAll('\n', ' '))
    .where((s) => s.trim().isNotEmpty)
    .take(take)
    .toList();

Future<bool> _tap(WidgetTester tester, Finder f) async {
  if (!_has(f)) return false;
  try {
    await tester.ensureVisible(f.first);
  } catch (_) {}
  await tester.tap(f.first, warnIfMissed: false);
  await tester.pumpAndSettle(const Duration(milliseconds: 250));
  return true;
}

Future<bool> _tapText(WidgetTester tester, String text) =>
    _tap(tester, find.text(text));

Future<bool> _tapContaining(WidgetTester tester, String part) =>
    _tap(tester, find.textContaining(part).first);

/// Тап без ensureVisible: иначе PageView сама доскроллит до соседней
/// страницы и харнес окажется не на том шаге.
Future<bool> _tapRaw(WidgetTester tester, Finder f) async {
  if (!_has(f)) return false;
  await tester.tap(f.first, warnIfMissed: false);
  await tester.pumpAndSettle(const Duration(milliseconds: 250));
  return true;
}

/// Видит ли пользователь этот виджет целиком в области 411×891.
bool _visible(WidgetTester tester, Finder f) {
  try {
    final r = tester.getRect(f);
    return r.top >= 0 &&
        r.bottom <= 891 &&
        r.left >= 0 &&
        r.right <= 411;
  } catch (_) {
    return false;
  }
}

/// Тап по кликабельному предку подписи (InkWell/GestureDetector), а не по
/// самому Text — иначе совпадение с текстом в вопросе даёт ложный ответ.
Finder _optionTap(String text) {
  final t = find.text(text);
  final well = find.ancestor(of: t.first, matching: find.byType(InkWell));
  final gest = find.ancestor(of: t.first, matching: find.byType(GestureDetector));
  // ближайший предок = сам чип/строка; .last дал бы тап по центру страницы
  if (_n(well) > 0) return well.first;
  if (_n(gest) > 0) return gest.first;
  return t;
}

/// Подписи всех ElevatedButton с пометкой выключенных.
List<String> _buttons(WidgetTester tester) {
  final list = tester.widgetList<ElevatedButton>(find.byType(ElevatedButton)).toList();
  final out = <String>[];
  for (var i = 0; i < list.length; i++) {
    final b = list[i];
    final txt = tester
        .widgetList<Text>(
            find.descendant(of: find.byType(ElevatedButton).at(i), matching: find.byType(Text)))
        .map((t) => t.data ?? '')
        .join('+');
    out.add('$txt${b.onPressed == null ? "[выкл]" : ""}');
  }
  return out;
}

/// Поставить Slider в нужное значение. Сначала калибруем концы трека
/// тапами (реальные отступы Slider неизвестны), затем целимся в target.
Future<double> _setSlider(WidgetTester tester, int index, double target) async {
  // карточка может быть не построена, пока не доскроллили ListView
  for (var k = 0; k < 12 && _n(find.byType(Slider)) <= index; k++) {
    final lists = find.byType(ListView);
    if (_n(lists) == 0) break;
    await tester.drag(lists.last, const Offset(0, -170));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
  }
  final finder = find.byType(Slider).at(index);
  if (!_has(finder)) return -1;
  final rect = tester.getRect(finder);
  final s = tester.widget<Slider>(finder);

  Future<double> probe(double x) async {
    await tester.tapAt(Offset(x, rect.center.dy));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    try {
      return tester.widget<Slider>(find.byType(Slider).at(index)).value;
    } catch (_) {
      return double.nan;
    }
  }

  // калибровка: какое значение реально получается у левого и правого края
  final left = rect.left + 14, right = rect.right - 14;
  final vLeft = await probe(left);
  final vRight = await probe(right);
  if (vLeft.isNaN || vRight.isNaN) return double.nan;
  if ((vRight - vLeft).abs() < 0.001) return vRight;
  final frac = ((target - vLeft) / (vRight - vLeft)).clamp(0.0, 1.0);
  final got = await probe(left + frac * (right - left));
  return got.isNaN ? got : got.clamp(s.min, s.max);
}

/// То же самое, но слайдер ищется по карточке ингредиента — список
/// пропорций это ListView, его элементы перерабатываются при скролле.
Future<double> _setSliderFor(
    WidgetTester tester, String ingredient, double target) async {
  Finder card = find
      .ancestor(of: find.text(ingredient), matching: find.byType(Container))
      .first;
  Finder slider = find.descendant(of: card, matching: find.byType(Slider));
  for (var k = 0; k < 12 && _n(slider) == 0; k++) {
    final lists = find.byType(ListView);
    if (_n(lists) == 0) break;
    await tester.drag(lists.last, const Offset(0, -170));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
  }
  if (_n(slider) == 0) return -999;
  final rect = tester.getRect(slider);

  Future<double> probe(double x) async {
    try {
      await tester.ensureVisible(slider);
      await tester.pumpAndSettle(const Duration(milliseconds: 150));
    } catch (_) {}
    if (_n(slider) == 0) return double.nan;
    await tester.tapAt(Offset(x, tester.getRect(slider).center.dy));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    if (_n(slider) == 0) return double.nan;
    return tester.widget<Slider>(slider).value;
  }

  final left = rect.left + 14, right = rect.right - 14;
  final vLeft = await probe(left);
  final vRight = await probe(right);
  if (vLeft.isNaN || vRight.isNaN || (vRight - vLeft).abs() < 0.001) {
    return vRight;
  }
  final frac = ((target - vLeft) / (vRight - vLeft)).clamp(0.0, 1.0);
  return await probe(left + frac * (right - left));
}

/// Пройти тест терминов: тапаем правильный вариант, потом «Дальше →»/«Завершить».
Future<String> _runTermQuiz(WidgetTester tester) async {
  var answered = 0;
  var wrong = 0;
  for (var guard = 0; guard < 12; guard++) {
    if (!_has(find.byType(TermQuizScreen))) break;
    final questionText = _visibleQuestionText(tester);
    if (questionText == null) {
      say('[TermQuiz] вопрос не читается — экран пустой');
      break;
    }
    final options = find.descendant(
        of: find.byType(TermQuizScreen), matching: find.byType(InkWell));
    if (_n(options) == 0) {
      say('[TermQuiz] нет вариантов ответа на «$questionText»');
      break;
    }
    final correct = _correctOptionFor(tester, questionText);
    final tapped = correct == null
        ? await _tap(tester, options)
        : await _tap(tester, find.descendant(
            of: find.byType(TermQuizScreen),
            matching: find.text(correct)));
    if (!tapped) {
      say('[TermQuiz] не удалось отметить ответ на «$questionText»');
      break;
    }
    answered++;
    if (_has(find.text('Не совсем. Попробуй запомнить — ещё раз увидишь в повторении.'))) {
      wrong++;
    }
    if (!await _tapContaining(tester, 'Дальше →') &&
        !await _tapContaining(tester, 'Завершить')) {
      say('[TermQuiz] нет кнопки перехода после ответа');
      break;
    }
  }
  final reachedQuiz = _has(find.byType(QuizScreen));
  return '$answered вопросов, $wrong неверно → основной квиз: $reachedQuiz';
}

String? _visibleQuestionText(WidgetTester tester) {
  for (final w in tester.widgetList<Text>(find.byType(Text))) {
    final t = w.data ?? '';
    if (t.startsWith('Что такое ') || t.startsWith('Как называется:')) return t;
  }
  return null;
}

String? _correctOptionFor(WidgetTester tester, String question) {
  final ts = TermService();
  final m = RegExp('Что такое "(.+?)"\\?').firstMatch(question);
  if (m != null) {
    final term = ts.getTerm(m.group(1)!);
    if (term == null) {
      say('[TermQuiz] термин «${m.group(1)}» отсутствует в словаре (Glossary неполон)');
      return null;
    }
    return term.definition;
  }
  final m2 = RegExp(r'Как называется: "(.+)"\?$').firstMatch(question);
  if (m2 != null) {
    // Обратный вопрос: по определению находим именно тот термин, а не
    // «первое увиденное название» — иначе харнес сам отвечал неверно.
    final definition = m2.group(1)!;
    for (final term in TermService.allTerms) {
      if (term.definition == definition) return term.russianName;
    }
    say('[TermQuiz] определения «${definition.substring(0, definition.length > 60 ? 60 : definition.length)}…» нет в словаре');
  }
  return null;
}

/// Пройти основной квиз, отвечая правильно по данным пула.
Future<String> _runMainQuiz(WidgetTester tester, Harness h, String lessonId) async {
  final quiz = h.quizzes.getQuiz(lessonId);
  final pool = quiz?.questionPool ?? const [];
  final perAttempt = quiz?.questionsPerAttempt ?? pool.length;
  final seen = <String>{};
  final typeLog = <String>[];
  var graded = 0;
  var stall = '';
  for (var guard = 0; guard < perAttempt + 4; guard++) {
    if (_has(find.byType(Dialog))) break;
    if (!_has(find.byType(QuizScreen))) break;
    QuizQuestion? q;
    for (final c in pool) {
      if (_has(find.text(c.question))) {
        q = c;
        break;
      }
    }
    if (q == null) break;
    if (!seen.add(q.question)) {
      stall = 'повтор вопроса (${q.type.name}) — UI не пропустил дальше';
      break;
    }
    typeLog.add(q.type.name);
    switch (q.type) {
      case QuestionType.singleChoice:
      case QuestionType.trueFalse:
      case QuestionType.imageMatch:
      case QuestionType.dragOrder:
        final text = q.options != null && q.correctAnswerIndex != null
            ? q.options![q.correctAnswerIndex!]
            : null;
        if (text != null) await _tapRaw(tester, _optionTap(text));
      case QuestionType.multipleChoice:
        for (final i in (q.correctAnswerIndices ?? const <int>[])) {
          await _tapRaw(tester, _optionTap(q.options![i]));
        }
        await _tapRaw(tester, find.widgetWithText(ElevatedButton, 'Проверить'));
      case QuestionType.matching:
        for (final pair in (q.pairs ?? const <Map<String, String>>[])) {
          await _tap(tester, find.text('Выбери вариант').first);
          await _tap(tester, find.text(pair['right']!).last);
        }
        await _tapRaw(tester, find.textContaining('Проверить пары').first);
      case QuestionType.sequence:
        final correct = q.sequence ?? const <String>[];
        for (var attempt = 0; attempt < correct.length; attempt++) {
          final order = _sequenceOrder(tester);
          if (order.isEmpty || attempt >= order.length) break;
          if (order[attempt] == correct[attempt]) continue;
          final currentPos = order.indexOf(correct[attempt]);
          if (currentPos < 0) break;
          final handle = find.byIcon(Icons.drag_handle).at(currentPos);
          if (!_has(handle)) {
            say('[Quiz $lessonId] sequence: рукоятка перетаскивания не найдена');
            break;
          }
          final itemH = _sequenceItemHeight(tester, order.length);
          await tester.drag(handle, Offset(0, (attempt - currentPos) * itemH));
          await tester.pumpAndSettle(const Duration(milliseconds: 250));
        }
        final finalOrder = _sequenceOrder(tester);
        await _tapRaw(tester, find.textContaining('Проверить порядок').first);
        say('[Quiz $lessonId] sequence: переставил ${finalOrder.length} элементов, '
            'порядок совпадает: ${finalOrder.join('|') == (q.sequence ?? []).join('|')}');
      case QuestionType.slider:
        final sliders = q.sliders ?? const <Map<String, dynamic>>[];
        for (var i = 0; i < sliders.length; i++) {
          final lo = (sliders[i]['correctMin'] as num).toDouble();
          final hi = (sliders[i]['correctMax'] as num).toDouble();
          final got = await _setSlider(tester, i, (lo + hi) / 2);
          if (got < lo - 0.001 || got > hi + 0.001) {
            say('[Quiz $lessonId] slider[$i]: целились ${(100 * (lo + hi) / 2).round()}%, '
                'получили $got (полоса ${lo * 100}%…${hi * 100}%)');
          }
        }
        await _tapRaw(tester, find.widgetWithText(ElevatedButton, 'Готово'));
    }
    // после засчитанного ответа обязан появиться футер «Далее»/«Завершить»
    final footer = find.textContaining(RegExp(r'^(Далее|Завершить)$'));
    if (!_has(footer)) {
      stall = 'нет футера после ответа (${q.type.name}), кнопки: ${_buttons(tester)}';
      break;
    }
    graded++;
    await _tapRaw(tester, footer);
  }
  final dialog = _has(find.byType(Dialog));
  String verdict;
  if (dialog) {
    final dtexts = _texts(tester, take: 60)
        .where((t) => t.contains('%') || t.contains('/') || t.length > 12)
        .take(6)
        .toList();
    verdict = 'диалог итога $dtexts';
  } else if (stall.isNotEmpty) {
    verdict = 'ОБОРВАЛСЯ: $stall';
  } else {
    verdict = 'диалог итога НЕ появился (пройдено $graded из $perAttempt)';
  }
  return 'вопросов ${seen.length}, засчитано $graded из $perAttempt, '
      'типов [${typeLog.join(', ')}], $verdict';
}

List<String> _sequenceOrder(WidgetTester tester) {
  final items = find.byType(ReorderableListView);
  if (!_has(items)) return const [];
  final texts = tester
      .widgetList<Text>(find.descendant(of: items, matching: find.byType(Text)))
      .map((t) => t.data ?? '')
      .where((s) => s.length > 3)
      .toList();
  return texts;
}

double _sequenceItemHeight(WidgetTester tester, int count) {
  if (count < 2) return 60;
  final items = find.byType(ReorderableListView);
  final texts = find.descendant(of: items, matching: find.byIcon(Icons.drag_handle));
  if (_n(texts) < 2) return 60;
  final a = tester.getCenter(find.byIcon(Icons.drag_handle).at(0));
  final b = tester.getCenter(find.byIcon(Icons.drag_handle).at(1));
  return (b.dy - a.dy).abs();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
    await _registerFonts();
  });

  tearDownAll(() {
    File('test/qa/LAYOUT.txt')
        .writeAsStringSync(_layoutDumps.isEmpty
            ? 'переполнений нет\n'
            : _layoutDumps.join('\n\n════════════\n\n'));
    File('test/qa/FLOW.txt').writeAsStringSync(
        notes.isEmpty ? 'чисто\n' : notes.map((e) => '- $e').join('\n'));
  });

  testWidgets('Level 1: урок → «К тесту» → тест терминов → основной квиз', (tester) async {
    _silenceFontNoise();
    final h = await _boot(tester, const SizedBox.shrink());
    final l1 = h.lessons.lessons
        .where((l) => ['A', 'B', 'C'].contains(l.blockId))
        .toList()
      ..sort((a, b) => a.lessonNumber.compareTo(b.lessonNumber));
    say('── проход по ${l1.length} урокам Level 1 ──');

    for (final lesson in l1) {
      await _boot(tester, LessonScreen(lesson: lesson), reuse: h);
      _drain(tester, 'Lesson ${lesson.id}');
      var guard = 0;
      var pressed = 0;
      var onQuizGate = false;
      while (guard++ < 30) {
        if (await _tapText(tester, 'К тесту')) {
          // тап уже увёл с урока — проверять наличие текста бессмысленно
          onQuizGate = true;
          break;
        }
        if (!await _tapText(tester, 'Далее')) break;
        pressed++;
        _drain(tester, 'Lesson ${lesson.id} slide');
      }
      if (!onQuizGate) {
        say('[${lesson.id}] НЕ ДОШЛИ до кнопки «К тесту» (переключено слайдов: $pressed, '
            'в уроке ${lesson.slides.length}) — путь оборван');
        continue;
      }
      _drain(tester, '${lesson.id} after К тесту');
      if (_has(find.byType(TermQuizScreen))) {
        final termReport = await _runTermQuiz(tester);
        say('[${lesson.id}] тест терминов: $termReport');
      } else if (_has(find.byType(QuizScreen))) {
        say('[${lesson.id}] терминов не потребовалось → сразу основной квиз');
      } else {
        say('[${lesson.id}] после «К тесту» не появился ни тест терминов, ни квиз — МЁРТВЫЙ ПУТЬ');
        continue;
      }
      if (_has(find.byType(QuizScreen))) {
        final quizReport = await _runMainQuiz(tester, h, lesson.id);
        say('[${lesson.id}] основной квиз: $quizReport → статус урока: '
            '${h.progress.getLessonStatus(lesson.id)}, XP=${h.progress.totalXP}');
      }
      _drain(tester, '${lesson.id} end');
    }
  });

  testWidgets('Level 1: практика — все задания проходят 5 шагов', (tester) async {
    _silenceFontNoise();
    final h = await _boot(tester, const SizedBox.shrink());
    final l1Lessons = h.lessons.lessons
        .where((l) => ['A', 'B', 'C'].contains(l.blockId))
        .map((l) => l.id)
        .toSet();
    final challenges =
        allPracticeChallenges.where((c) => l1Lessons.contains(c.lessonId)).toList();
    say('── практика Level 1: ${challenges.length} заданий ──');

    for (final c in challenges) {
      final xpBefore = h.progress.workshopPracticeXp;
      await _boot(tester, PracticeFlowScreen(challenge: c), reuse: h);
      _drain(tester, 'Practice ${c.id} intro');
      if (!await _tapRaw(tester, find.widgetWithText(ElevatedButton, 'Начать'))) {
        say('[${c.id}] шаг 0: нет кнопки «Начать»');
        continue;
      }
      // шаг 1: ингредиенты. Скриншот-безопасно: тапаем только то, что в вьюпорте.
      if (!_has(find.textContaining('Нажми на те, что нужны'))) {
        final all = _texts(tester, take: 60);
        say('[${c.id}] после «Начать» экран не похож на шаг ингредиентов: $all');
        continue;
      }
      final offscreen = <String>[];
      for (final o in c.allOptions) {
        if (!_visible(tester, find.text(o).first)) offscreen.add(o);
      }
      if (offscreen.isNotEmpty) {
        say('[${c.id}] шаг 1: чипов вне экрана ${offscreen.length} '
            '(${offscreen.join(', ')}) из ${c.allOptions.length} — '
            'список ингредиентов не скроллится');
      }
      for (final ing in c.correctIngredients) {
        if (!_has(find.text(ing))) {
          say('[${c.id}] ингредиент «$ing» вообще отсутствует в дереве');
        } else if (!_visible(tester, find.text(ing).first)) {
          say('[${c.id}] ингредиент «$ing» на экране недоступен (вне вьюпорта, '
              'тап физически некуда)');
        } else {
          await _tapRaw(tester, _optionTap(ing));
        }
      }
      final nextCta = find.textContaining('Дальше (');
      if (!_has(nextCta)) {
        say('[${c.id}] шаг 1: кнопки «Дальше (N выбрано)» нет; '
            'кнопки=${_buttons(tester)}, GestureDetector=${_n(find.byType(GestureDetector))}');
        continue;
      }
      if (!_visible(tester, nextCta)) {
        say('[${c.id}] шаг 1: кнопка «Дальше» ушла за пределы экрана');
      }
      await _tapRaw(tester, nextCta);
      // шаг 2: метод
      final label = methodDescriptions[c.correctMethod]?.label;
      if (label == null || !await _tapRaw(tester, _optionTap(label))) {
        say('[${c.id}] шаг 2: метод «${c.correctMethod}» ($label) недоступен тапом');
        continue;
      }
      if (!await _tapRaw(tester, find.widgetWithText(ElevatedButton, 'Дальше'))) {
        say('[${c.id}] шаг 2: нет кнопки «Дальше», кнопки=${_buttons(tester)}');
        continue;
      }
      // шаг 3: пропорции
      final sliderCount = _n(find.byType(Slider));
      if (sliderCount == 0) {
        say('[${c.id}] шаг 3: на экране ни одного слайдера, хотя ингредиентов '
            '${c.correctIngredients.length}');
      } else if (sliderCount < c.correctIngredients.length) {
        say('[${c.id}] шаг 3: без прокрутки видно $sliderCount слайдеров из '
            '${c.correctIngredients.length} — дальше только со скроллом');
      }
      for (final ing in c.correctIngredients) {
        final target = c.proportions[ing];
        if (target == null) continue;
        final got = await _setSliderFor(tester, ing, target.targetMl.toDouble());
        if (got == -999) {
          say('[${c.id}] шаг 3: карточка пропорций «$ing» так и не появилась '
              'ни в каком скролле');
          continue;
        }
        if (got.isNaN || !target.isWithin(got.round())) {
          say('[${c.id}] шаг 3: «$ing» цель ${target.targetMl}мл '
              '±${target.toleranceMl}, получено ${got}мл — '
              'в зелёную зону тапом не попасть');
        }
      }
      if (!await _tapRaw(tester, find.widgetWithText(ElevatedButton, 'Проверить'))) {
        say('[${c.id}] шаг 3: нет кнопки «Проверить», кнопки=${_buttons(tester)}');
        continue;
      }
      _drain(tester, 'Practice ${c.id} result');
      final stars = h.progress.getPracticeStars(c.id);
      final xpAfter = h.progress.workshopPracticeXp;
      say('[${c.id}] идеальное выполнение → звёзд: $stars, XP практики +${xpAfter - xpBefore}, '
          'экран результата: ${_has(find.textContaining('Звёзд')) || _has(find.text('Повторить'))}');
    }
  });

  testWidgets('XP идемпотентность: повтор задания не добавляет звёзды/XP', (tester) async {
    _silenceFontNoise();
    final h = await _boot(tester, const SizedBox.shrink());
    final c = allPracticeChallenges.firstWhere((x) => x.id == 'practice_mojito');
    for (var run = 0; run < 2; run++) {
      final before = h.progress.workshopPracticeXp;
      final coins = h.progress.coins;
      await _boot(tester, PracticeFlowScreen(challenge: c), reuse: h);
      await _tapRaw(tester, find.widgetWithText(ElevatedButton, 'Начать'));
      for (final ing in c.correctIngredients) {
        await _tapRaw(tester, _optionTap(ing));
      }
      await _tapRaw(tester, find.textContaining('Дальше (').first);
      await _tapRaw(tester, _optionTap(methodDescriptions[c.correctMethod]!.label));
      await _tapRaw(tester, find.widgetWithText(ElevatedButton, 'Дальше'));
      for (final ing in c.correctIngredients) {
        final p = c.proportions[ing];
        if (p == null) continue;
        await _setSliderFor(tester, ing, p.targetMl.toDouble());
      }
      await _tapRaw(tester, find.widgetWithText(ElevatedButton, 'Проверить'));
      _drain(tester, 'idempotency run $run');
      say('[идемпотентность] прогон ${run + 1}: XP практики ${before} → ${h.progress.workshopPracticeXp}, '
          'монеты $coins → ${h.progress.coins}, звёзды ${h.progress.getPracticeStars(c.id)}');
    }
  });

  testWidgets('Диплом Level 1: гейт честный', (tester) async {
    _silenceFontNoise();
    final seed = await _boot(tester, const SizedBox.shrink());
    final l1 = seed.lessons.lessons
        .where((l) => ['A', 'B', 'C'].contains(l.blockId))
        .map((l) => l.id)
        .toList();
    Map<String, Object> progressJson({bool stars = false, bool allLessons = true}) {
      final statuses = <String, String>{};
      if (allLessons) {
        for (final id in l1) {
          statuses[id] = 'completed';
        }
      } else {
        for (var i = 0; i < l1.length - 1; i++) {
          statuses[l1[i]] = 'completed';
        }
      }
      final jsonProgress = <String, Object>{
        'totalXP': 1200,
        'coins': 300,
        'streak': 3,
        'lessonStatuses': {
          for (final e in statuses.entries) e.key: 'LessonStatus.${e.value}'
        },
        'usedQuestionIds': <String, List<String>>{},
        'unlockedCocktails': const <String>[],
        'achievements': const <String>[],
        'purchasedWisdom': const <String>[],
      };
      return <String, Object>{
        'bartender_school_progress': json.encode(jsonProgress),
        for (final id in (stars ? level1DiplomaChallengeIds : const <String>[]))
          'practice_stars_$id': 3,
      };
    }

    // 1) все уроки, но практика не сделана
    var h = await _boot(tester, const CertificatesScreen(),
        prefs: progressJson(stars: false));
    say('[диплом] все уроки + без практики: isSchoolCompleted='
        '${h.progress.isSchoolCompleted(lessonRepo: h.lessons)}');
    say('[диплом UI без практики] ${_texts(tester).join(' § ')}');
    _drain(tester, 'certs no-practice');

    // 2) все уроки + обязательная практика
    h = await _boot(tester, const CertificatesScreen(),
        prefs: progressJson(stars: true));
    final completed = h.progress.isSchoolCompleted(lessonRepo: h.lessons);
    say('[диплом UI с практикой] ${_texts(tester).join(' § ')}');
    h = await _boot(tester, const SizedBox.shrink(),
        prefs: progressJson(stars: true));
    final d13 = h.progress.isLessonUnlocked('lesson_D_13', 'lesson_C_12');
    say('[диплом] все уроки + Mojito/Daiquiri/Negroni по 3★: isSchoolCompleted=$completed, '
        'Level 2 (lesson_D_13) разблокирован=$d13');

    // 3) один недоученный урок
    h = await _boot(tester, const SizedBox.shrink(),
        prefs: progressJson(stars: true, allLessons: false));
    say('[диплом] один урок не закрыт: isSchoolCompleted='
        '${h.progress.isSchoolCompleted(lessonRepo: h.lessons)} (ожидается false)');
    if (h.progress.isSchoolCompleted(lessonRepo: h.lessons)) {
      say('[диплом] P0: диплом выдаётся без полного Level 1');
    }
    if (!completed) {
      say('[диплом] P0: при полностью закрытых уроках и 3★ практики диплом НЕ считается полученным');
    }
    if (!d13) {
      say('[диплом] P0: Level 2 не открывается после честного диплома Level 1');
    }
  });

  testWidgets('Вёрстка Level 1 на узком экране', (tester) async {
    _silenceFontNoise();
    final h = await _boot(tester, const SizedBox.shrink(), wisdom: true);
    const screens = <String, Widget>{
      'оболочка': MainShell(),
      'школа Level 1': Level1Screen(),
      'мастерская': WorkshopScreen(),
      'дипломы': CertificatesScreen(),
    };
    for (final size in const [Size(360, 640), Size(320, 568)]) {
      for (final e in screens.entries) {
        await _boot(tester, e.value,
            reuse: h,
            surface: size,
            homeDeps: true,
            settle: false);
        _drain(tester, '${size.width.round()}×${size.height.round()} ${e.key}');
      }
    }
  });

  testWidgets('Тест терминов: не переполняется после ответа', (tester) async {
    _silenceFontNoise();
    final h = await _boot(tester, const SizedBox.shrink(), wisdom: true);
    final lesson = h.lessons.getLesson('lesson_A_01')!;
    addTearDown(() => tester.platformDispatcher.clearTextScaleFactorTestValue());
    for (final scale in const [1.0, 1.3]) {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      for (final size in const [
        Size(411, 891),
        Size(360, 640),
        Size(320, 568),
      ]) {
        final label = '${size.width.round()}×${size.height.round()} '
            'scale $scale';
        await _boot(
          tester,
          TermQuizScreen(lesson: lesson, onComplete: () {}),
          reuse: h,
          surface: size,
          settle: false,
        );
        await tester.pump(const Duration(milliseconds: 400));
        _drain(tester, 'TermQuiz $label');
        final options = find.descendant(
          of: find.byType(TermQuizScreen),
          matching: find.byType(InkWell),
        );
        if (_n(options) == 0) {
          say('[TermQuiz] $label: вариантов ответа нет');
          continue;
        }
        // После ответа появляются подсказка и кнопка «Дальше →» — именно
        // этот кадр раньше давал RenderFlex overflowed at the bottom.
        await tester.tap(options.first, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 600));
        _drain(tester, 'TermQuiz $label answered');
        if (_n(find.textContaining('Дальше')) == 0 &&
            _n(find.textContaining('Завершить')) == 0) {
          say('[TermQuiz] $label: нет кнопки перехода после ответа');
        }
      }
    }
  });

  testWidgets('ДИАГНОСТИКА: что реально на экране урока и практики', (tester) async {
    _silenceFontNoise();
    final h = await _boot(tester, const SizedBox.shrink());
    for (final id in ['lesson_A_01', 'lesson_A_02']) {
      await _boot(tester, LessonScreen(lesson: h.lessons.getLesson(id)!));
      _drain(tester, 'diag $id');
      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => (t.data ?? '').replaceAll('\n', ' '))
          .where((s) => s.trim().isNotEmpty)
          .take(40)
          .toList();
      say('[diag $id] кнопок=${_n(find.byType(ElevatedButton))} '
          'тексты: ${texts.join(' § ')}');
    }
    final c = allPracticeChallenges.firstWhere((x) => x.id == 'practice_mojito');
    await _boot(tester, PracticeFlowScreen(challenge: c));
    _drain(tester, 'diag practice');
    final pt = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => (t.data ?? '').replaceAll('\n', ' '))
        .where((s) => s.trim().isNotEmpty)
        .take(40)
        .toList();
    say('[diag practice intro] ${pt.join(' § ')}');
    await _tapText(tester, 'Начать');
    _drain(tester, 'diag practice step1');
    final p1 = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => (t.data ?? '').replaceAll('\n', ' '))
        .where((s) => s.trim().isNotEmpty)
        .take(40)
        .toList();
    say('[diag practice step1] ${p1.join(' § ')}');
  });

  testWidgets('ДИАГНОСТИКА 2: чем кончается урок', (tester) async {
    _silenceFontNoise();
    final h = await _boot(tester, const SizedBox.shrink());
    final lesson = h.lessons.getLesson('lesson_A_01')!;
    await _boot(tester, LessonScreen(lesson: lesson));
    say('[diag2] слайдов в уроке: ${lesson.slides.length}, '
        'типы: ${lesson.slides.map((s) => s.type.name).join(',')}');
    for (var i = 0; i < 12; i++) {
      final buttons = tester
          .widgetList<ElevatedButton>(find.byType(ElevatedButton))
          .toList();
      final buttonTexts = <String>[];
      for (var bi = 0; bi < buttons.length; bi++) {
        final f = find.byType(ElevatedButton).at(bi);
        buttonTexts.add(tester
            .widgetList<Text>(find.descendant(of: f, matching: find.byType(Text)))
            .map((t) => t.data ?? '')
            .join('+'));
      }
      say('[diag2 шаг $i] кнопок=${buttons.length} [$buttonTexts]');
      if (!_has(find.text('Далее'))) break;
      await _tapText(tester, 'Далее');
      _drain(tester, 'diag2');
    }
    final tappedQuiz = await _tapText(tester, 'К тесту');
    _drain(tester, 'diag2 after К тесту');
    say('[diag2 финал] тап «К тесту»=$tappedQuiz, тест терминов: '
        '${_has(find.byType(TermQuizScreen))}, основной квиз: '
        '${_has(find.byType(QuizScreen))}, тексты: ${_texts(tester, take: 6).join(' § ')}');
  });

  testWidgets('Проваленный квиз не завершает урок', (tester) async {
    _silenceFontNoise();
    final h = await _boot(tester, const SizedBox.shrink());
    final lesson = h.lessons.getLesson('lesson_A_02')!;
    await _boot(tester, QuizScreen(lessonId: lesson.id));
    final pool = h.quizzes.getQuiz(lesson.id)?.questionPool ?? const [];
    for (var guard = 0; guard < 12; guard++) {
      if (!_has(find.byType(QuizScreen))) break;
      QuizQuestion? q;
      for (final c in pool) {
        if (_has(find.text(c.question))) {
          q = c;
          break;
        }
      }
      if (q == null) break;
      // заведомо неверный ответ
      if (q.options != null && q.correctAnswerIndex != null) {
        final bad = (q.correctAnswerIndex! + 1) % q.options!.length;
        if (!_has(find.text(q.options![bad]))) break;
        await _tap(tester, find.text(q.options![bad]).first);
      } else {
        await _tapContaining(tester, 'Проверить');
      }
      final advanced = await _tap(tester, find.text('Далее')) ||
          await _tap(tester, find.text('Завершить'));
      if (!advanced) break;
    }
    _drain(tester, 'quiz fail');
    final status = h.progress.getLessonStatus(lesson.id);
    say('[провал квиза] lesson_A_02 статус: $status (должен быть НЕ completed)');
    if (status == LessonStatus.completed) {
      say('[провал квиза] P0: проваленный квиз завершил урок');
    }
  });
}
