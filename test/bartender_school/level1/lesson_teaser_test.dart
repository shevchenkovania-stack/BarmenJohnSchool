import 'package:coin/features/bartender_school/presentation/widgets/lesson_teaser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Заставка — первое, что человек видит перед уроком. Она не должна
/// становиться стеной: пропуск работает сразу, а при включённой системной
/// настройке «без анимаций» урок открывается мгновенно.
void main() {
  Widget host({required VoidCallback onFinished, bool disableAnimations = false}) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: LessonTeaser(
          title: 'ПЕРВЫЙ УРОК',
          line: 'За стойкой нет мелочей.',
          onFinished: onFinished,
        ),
      ),
    );
  }

  testWidgets('заставка показывает заголовок и кнопку «Пропустить»',
      (tester) async {
    await tester.pumpWidget(host(onFinished: () {}));
    // Один кадр: дальше идёт анимация, а нам достаточно первого.
    await tester.pump();

    expect(find.text('Пропустить'), findsOneWidget);
    expect(find.text('ПЕРВЫЙ УРОК'), findsOneWidget);
  });

  testWidgets('пропуск срабатывает сразу, без ожидания', (tester) async {
    var finished = 0;
    await tester.pumpWidget(host(onFinished: () => finished++));
    await tester.pump();

    await tester.tap(find.text('Пропустить'));
    await tester.pump();

    expect(finished, 1);
  });

  testWidgets('при системном «без анимаций» заставка сразу отдаёт урок',
      (tester) async {
    var finished = 0;
    await tester.pumpWidget(
      host(onFinished: () => finished++, disableAnimations: true),
    );
    await tester.pump();
    await tester.pump();

    expect(finished, 1, reason: 'без анимаций ждать нечего');
  });

  testWidgets('сама заканчивается, если её не пропускать', (tester) async {
    var finished = 0;
    await tester.pumpWidget(host(onFinished: () => finished++));
    await tester.pump();

    // Длительность заставки — 4.2 с. Ждём чуть больше.
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();

    expect(finished, 1);
  });

  testWidgets('текст печатается постепенно', (tester) async {
    await tester.pumpWidget(host(onFinished: () {}));
    await tester.pump();

    // Целая фраза в первый кадр не появляется — её ещё «говорят».
    expect(find.text('За стойкой нет мелочей.'), findsNothing);

    await tester.pump(const Duration(milliseconds: 3000));
    expect(find.text('За стойкой нет мелочей.'), findsOneWidget);
  });
}
