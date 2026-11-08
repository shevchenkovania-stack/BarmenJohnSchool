import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:coin/features/bartender_school/data/guest_echo.dart';
import 'package:coin/features/bartender_school/data/quest_scene.dart';
import 'package:coin/features/bartender_school/presentation/widgets/quest_scene_view.dart';

const _scene = QuestScene(
  id: 'echo_scene',
  title: 'Дождь на Пятой авеню',
  timeStamp: '1874 · Нижний Манхэттен',
  beats: [
    QuestBeat(text: 'Дождь.'),
    QuestBeat(speaker: 'Гость', text: 'Мне как вчера. Только не как вчера.'),
  ],
  probes: [
    QuestProbe(
      id: 'p1',
      label: 'Что было вчера?',
      response: 'Горчило.',
      insight: 'Горько.',
    ),
  ],
  answers: [
    QuestOption(
      id: 'right',
      text: 'Высокий, лёгкий, с цитрусом',
      isRight: true,
      guestReaction: 'Вот это другое дело.',
      johnLesson: 'Ты услышал.',
    ),
    QuestOption(
      id: 'wrong',
      text: 'Короткий и крепкий',
      isRight: false,
      guestReaction: 'Я же сказал.',
      johnLesson: 'Он просил не про крепость.',
    ),
  ],
);

Future<GuestEchoService> _prefs() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final sp = await SharedPreferences.getInstance();
  return GuestEchoService(sp);
}

/// Сцена сама сообщает о выборе — проверяем, что эхо записывается
/// ровно так, как его потом прочитает главный экран.
Future<void> _playScene(
  WidgetTester tester,
  GuestEchoService echo, {
  required String answerId,
}) async {
  await tester.pumpWidget(
    Provider<GuestEchoService>.value(
      value: echo,
      child: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => QuestSceneView(
                scene: _scene,
                onFinished: (option) {
                  context.read<GuestEchoService>().remember(
                        sceneTitle: _scene.title,
                        choiceText: option.text,
                        wasRight: option.isRight,
                      );
                },
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();

  // Все реплики вперёд.
  while (find.byKey(const Key('quest_next_beat')).evaluate().isNotEmpty) {
    await tester.tap(find.byKey(const Key('quest_next_beat')));
    await tester.pump();
    await tester.pump();
  }

  // Один вопрос.
  final probe = find.byKey(const Key('quest_probe_p1'));
  await tester.ensureVisible(probe);
  await tester.pump();
  await tester.tap(probe);
  await tester.pump();
  await tester.pump();

  final answer = find.byKey(Key('quest_answer_$answerId'));
  await tester.ensureVisible(answer);
  await tester.pump();
  await tester.tap(answer);
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('выбор из сцены сохраняется в эхо гостя', (tester) async {
    final echo = await _prefs();
    expect(echo.last, isNull);

    await _playScene(tester, echo, answerId: 'right');

    final saved = echo.last;
    expect(saved, isNotNull);
    expect(saved!.sceneTitle, 'Дождь на Пятой авеню');
    expect(saved.choiceText, contains('Высокий'));
    expect(saved.wasRight, isTrue);
  });

  testWidgets('неверный выбор тоже запоминается, но мягко', (tester) async {
    final echo = await _prefs();
    await _playScene(tester, echo, answerId: 'wrong');

    expect(echo.last?.wasRight, isFalse);

    // Через три дня гость «вернулся» — реплика без стыда.
    final line = echo.takeEcho(
      DateTime.now().add(const Duration(days: 4)),
    );
    expect(line, isNotNull);
    expect(line!.toLowerCase(), isNot(contains('позор')));
    expect(line.toLowerCase(), isNot(contains('стыдно')));
    expect(line.toLowerCase(), isNot(contains('слабо')));
  });

  testWidgets('эхо не появляется раньше трёх дней', (tester) async {
    final echo = await _prefs();
    await _playScene(tester, echo, answerId: 'right');

    expect(echo.takeEcho(DateTime.now()), isNull);
  });

  testWidgets('эхо показывается не чаще раза в день', (tester) async {
    final echo = await _prefs();
    await _playScene(tester, echo, answerId: 'right');

    final later = DateTime.now().add(const Duration(days: 4));
    expect(echo.takeEcho(later), isNotNull);
    // В тот же день повторно не показываем.
    expect(echo.takeEcho(later.add(const Duration(hours: 2))), isNull);
  });
}
