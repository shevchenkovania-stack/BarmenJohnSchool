// QA: каждый текст слайда Level 1 должен лежать на деревянной панели комнаты.
// Без панели слайд печатается прямо на фотографии комнаты (прозрачный фон), и
// светлый текст AppColors сливается с картинкой — именно так выглядел слайд 6
// урока 1 (тренажёр баланса). Запуск:
//   flutter test test/qa/lesson_slide_backdrop_test.dart
// Скриншоты проблемных типов слайдов: flutter test test/qa/lesson_slide_backdrop_test.dart --update-goldens
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:coin/core/theme/app_theme.dart';
import 'package:coin/features/bartender_school/data/lesson_repository.dart';
import 'package:coin/features/bartender_school/domain/entities/lesson.dart';
import 'package:coin/features/bartender_school/presentation/screens/lesson_screen.dart';
import 'package:coin/features/bartender_school/presentation/widgets/john_school_visuals.dart';
import 'package:coin/l10n/app_localizations.dart';

final List<String> notes = <String>[];
void say(String s) {
  notes.add(s);
  // ignore: avoid_print
  print('QA> $s');
}

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

/// Переполнения не валят тест, но попадают в отчёт — как в level1_flow_test.
final List<String> _overflows = [];

void _silenceFontNoise() {
  final previous = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    final text = details.exception.toString();
    if (text.contains('allowRuntimeFetching') ||
        text.contains('GoogleFonts was unable')) {
      return;
    }
    if (text.contains('overflowed by')) _overflows.add(text.split('\n').first);
    previous?.call(details);
  };
}

Future<LessonRepository> _boot(WidgetTester tester, Widget screen,
    {Size surface = const Size(411, 891)}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final sp = await SharedPreferences.getInstance();
  final lessonRepo = LessonRepository();
  await tester.runAsync(lessonRepo.loadCoreCurriculum);

  await tester.binding.setSurfaceSize(surface);
  tester.view.physicalSize = surface * 3;
  tester.view.devicePixelRatio = 3.0;
  addTearDown(() => tester.binding.setSurfaceSize(null));

  // Принудительный демонтаж прошлого экрана, иначе LessonScreen переиспользует
  // State и _currentPage остаётся на последнем слайде.
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<SharedPreferences>.value(value: sp),
        ChangeNotifierProvider<LessonRepository>.value(value: lessonRepo),
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
  await tester.pumpAndSettle(const Duration(milliseconds: 200));
  return lessonRepo;
}

/// Надписи слайда, у которых нет деревянной панели под текстом.
List<String> _orphanTexts(WidgetTester tester) {
  final panels = find
      .descendant(
          of: find.byType(PageView), matching: find.byType(JohnWoodPanel))
      .evaluate()
      .toSet();
  final texts = find
      .descendant(of: find.byType(PageView), matching: find.byType(Text))
      .evaluate();
  final orphan = <String>[];
  for (final element in texts) {
    final data =
        ((element.widget as Text).data ?? '').trim().replaceAll('\n', ' ');
    if (data.isEmpty) continue;
    var covered = false;
    element.visitAncestorElements((ancestor) {
      if (panels.contains(ancestor)) covered = true;
      return true;
    });
    if (!covered) orphan.add(data);
  }
  return orphan;
}

/// Панель обязана закрывать всю страницу, иначе под коротким слайдом
/// просвечивает фотография комнаты.
bool _panelCoversPage(WidgetTester tester) {
  final pageHeight = tester.getSize(find.byType(PageView)).height;
  final panels = find
      .descendant(
          of: find.byType(PageView), matching: find.byType(JohnWoodPanel))
      .evaluate();
  for (final element in panels) {
    final box = element.renderObject as RenderBox?;
    if (box == null || !box.hasSize) continue;
    if (box.size.height < pageHeight - 24) return false;
  }
  return true;
}

Future<void> _advance(WidgetTester tester) async {
  final next = find.text('Далее');
  if (next.evaluate().isEmpty) return;
  await tester.tap(next.first, warnIfMissed: false);
  await tester.pumpAndSettle(const Duration(milliseconds: 250));
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
    await _registerFonts();
  });

  tearDownAll(() {
    File('test/qa/BACKDROP.txt').writeAsStringSync(
        notes.isEmpty ? 'чисто\n' : notes.map((e) => '- $e').join('\n'));
  });

  testWidgets('Level 1: ни один слайд не висит на прозрачном фоне',
      (tester) async {
    _silenceFontNoise();
    final repo = await _boot(tester, const SizedBox.shrink());
    final lessons = repo.lessons
        .where((l) => const ['A', 'B', 'C'].contains(l.blockId))
        .toList()
      ..sort((a, b) => a.lessonNumber.compareTo(b.lessonNumber));

    var checked = 0;
    for (final lesson in lessons) {
      await _boot(tester, LessonScreen(lesson: lesson));
      for (var i = 0; i < lesson.slides.length; i++) {
        final slide = lesson.slides[i];
        final orphan = _orphanTexts(tester);
        checked++;
        if (orphan.isNotEmpty) {
          say('[${lesson.id} слайд ${i + 1} (${slide.type.name})] '
              'текст без панели: ${orphan.take(4).join(" § ")}');
        }
        if (!_panelCoversPage(tester)) {
          say('[${lesson.id} слайд ${i + 1} (${slide.type.name})] '
              'панель не покрывает страницу');
        }
        // Скриншоты типов, которые исторически рисовались без панели.
        if (const {
              SlideType.balanceTrainer,
              SlideType.toolVisual,
              SlideType.interactive,
              SlideType.barTip,
            }.contains(slide.type) &&
            i < 9) {
          try {
            await expectLater(
              find.byType(MaterialApp),
              matchesGoldenFile(
                  'shots/backdrop/${lesson.id}_${i + 1}_${slide.type.name}.png'),
            );
          } catch (e) {
            say('[shot ${lesson.id} ${i + 1}] $e');
          }
        }
        await _advance(tester);
      }
    }
    say('проверено слайдов: $checked в ${lessons.length} уроках');
    expect(notes.where((n) => n.contains('текст без панели')), isEmpty);
    expect(notes.where((n) => n.contains('панель не покрывает страницу')),
        isEmpty);
  });

  testWidgets('Level 1: панельные слайды не ломаются на узком экране',
      (tester) async {
    _silenceFontNoise();
    final repo = await _boot(tester, const SizedBox.shrink());
    final lessons = repo.lessons
        .where((l) => const ['A', 'B', 'C'].contains(l.blockId))
        .toList()
      ..sort((a, b) => a.lessonNumber.compareTo(b.lessonNumber));

    for (final lesson in lessons) {
      await _boot(tester, LessonScreen(lesson: lesson),
          surface: const Size(320, 568));
      for (var i = 0; i < lesson.slides.length; i++) {
        if (_overflows.isNotEmpty) {
          say('[${lesson.id} слайд ${i + 1} (${lesson.slides[i].type.name})] '
              '320×568: ${_overflows.join(' | ')}');
          _overflows.clear();
        }
        await _advance(tester);
      }
    }
    expect(notes.where((n) => n.contains('320×568')), isEmpty);
  });
}
