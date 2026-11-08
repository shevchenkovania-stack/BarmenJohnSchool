import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:coin/features/bartender_school/data/quest_scene.dart';
import 'package:coin/features/bartender_school/presentation/widgets/quest_scene_view.dart';

const _scene = QuestScene(
  id: 'widget_scene',
  title: 'Дождь на Пятой авеню',
  timeStamp: '1874 · Нижний Манхэттен',
  beats: [
    QuestBeat(text: 'Бар на восемь мест. Дождь.'),
    QuestBeat(speaker: 'Гость', text: 'Мне как вчера. Только не как вчера.'),
  ],
  probes: [
    QuestProbe(
      id: 'p1',
      label: 'Что было вчера?',
      response: 'Горчило. И крепко.',
      insight: 'Вчера было горько.',
    ),
    QuestProbe(
      id: 'p2',
      label: 'Ты один сегодня?',
      response: 'Дождь. Жду, пока кончится.',
      insight: 'Он один и никуда не спешит.',
    ),
    QuestProbe(
      id: 'p3',
      label: 'Сколько у тебя времени?',
      response: 'До последнего трамвая.',
      insight: 'Времени много.',
    ),
  ],
  answers: [
    QuestOption(
      id: 'a_right',
      text: 'Высокий, лёгкий, с цитрусом',
      isRight: true,
      guestReaction: 'Вот это — другое дело.',
      johnLesson: 'Он попросил не про крепость.',
    ),
    QuestOption(
      id: 'a_strong',
      text: 'Короткий и крепкий',
      isRight: false,
      guestReaction: 'Я же сказал — не как вчера.',
      johnLesson: 'Ты услышал половину.',
    ),
    QuestOption(
      id: 'a_sweet',
      text: 'Сладкий, без алкоголя',
      isRight: false,
      guestReaction: 'Я не за лимонадом.',
      johnLesson: 'Слушать не значит выполнять буквально.',
    ),
  ],
);

Future<void> _pump(
  WidgetTester tester, {
  bool disableAnimations = true,
  void Function(QuestOption)? onFinished,
  VoidCallback? onContinue,
}) async {
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: MaterialApp(
        home: Scaffold(
          body: QuestSceneView(
            scene: _scene,
            onFinished: onFinished,
            onContinue: onContinue,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

/// Сцена длиннее вьюпорта: перед тапом доводим элемент в зону видимости.
Future<void> _tapVisible(WidgetTester tester, Key key) async {
  final finder = find.byKey(key);
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('при отключённых анимациях титры видны сразу', (tester) async {
    await _pump(tester);
    expect(find.textContaining('Бар на восемь мест'), findsOneWidget);
    expect(find.textContaining('1874 · Нижний Манхэттен'), findsOneWidget);
  });

  testWidgets('реплики идут шагами, а не вываливаются сразу', (tester) async {
    await _pump(tester);
    // Вторая реплика гостя ещё не показана.
    expect(find.textContaining('Мне как вчера'), findsNothing);

    await _tapVisible(tester, const Key('quest_next_beat'));
    expect(find.textContaining('Мне как вчера'), findsOneWidget);
    // Кнопки вопросов появляются только после всех реплик.
    expect(find.byKey(const Key('quest_probe_p1')), findsOneWidget);
  });

  testWidgets('без вопроса действие закрыто', (tester) async {
    await _pump(tester);
    await _tapVisible(tester, const Key('quest_next_beat'));

    expect(find.textContaining('Сначала спроси'), findsOneWidget);
    expect(find.byKey(const Key('quest_answer_a_right')), findsNothing);
  });

  testWidgets('вопрос задаётся один раз и даёт ответ гостя', (tester) async {
    await _pump(tester);
    await _tapVisible(tester, const Key('quest_next_beat'));

    await _tapVisible(tester, const Key('quest_probe_p1'));

    expect(find.textContaining('Горчило'), findsOneWidget);
    // Тот же вопрос исчез из списка доступных, появился следующий.
    expect(find.byKey(const Key('quest_probe_p1')), findsNothing);
    expect(find.byKey(const Key('quest_probe_p2')), findsOneWidget);
  });

  testWidgets('после первого вопроса действие открывается', (tester) async {
    await _pump(tester);
    await _tapVisible(tester, const Key('quest_next_beat'));
    await _tapVisible(tester, const Key('quest_probe_p1'));

    expect(find.byKey(const Key('quest_answer_a_right')), findsOneWidget);
    expect(find.byKey(const Key('quest_answer_a_strong')), findsOneWidget);
  });

  testWidgets('выбор закрывает сцену: остальные варианты исчезают',
      (tester) async {
    QuestOption? finished;
    await _pump(tester, onFinished: (o) => finished = o);
    await _tapVisible(tester, const Key('quest_next_beat'));
    await _tapVisible(tester, const Key('quest_probe_p1'));

    await _tapVisible(tester, const Key('quest_answer_a_strong'));

    expect(finished?.id, 'a_strong');
    expect(find.byKey(const Key('quest_result')), findsOneWidget);
    // Ни одного варианта больше не осталось.
    expect(find.byKey(const Key('quest_answer_a_right')), findsNothing);
    expect(find.byKey(const Key('quest_answer_a_strong')), findsNothing);
    expect(find.byKey(const Key('quest_answer_a_sweet')), findsNothing);
    // Реакция гостя и вывод Джона на экране.
    expect(find.textContaining('Я же сказал'), findsOneWidget);
    expect(find.textContaining('Ты услышал половину'), findsOneWidget);
  });

  testWidgets('кнопка «Дальше» появляется только после выбора', (tester) async {
    var continued = false;
    await _pump(tester, onContinue: () => continued = true);
    await _tapVisible(tester, const Key('quest_next_beat'));

    expect(find.byKey(const Key('quest_continue')), findsNothing);

    await _tapVisible(tester, const Key('quest_probe_p1'));
    await _tapVisible(tester, const Key('quest_answer_a_right'));

    expect(find.byKey(const Key('quest_continue')), findsOneWidget);
    await _tapVisible(tester, const Key('quest_continue'));
    expect(continued, isTrue);
  });

  testWidgets('на всех трёх вопросах сцена проходится до конца',
      (tester) async {
    await _pump(tester);
    await _tapVisible(tester, const Key('quest_next_beat'));

    for (final id in ['p1', 'p2', 'p3']) {
      await _tapVisible(tester, Key('quest_probe_$id'));
    }

    expect(find.textContaining('Вопросов осталось'), findsNothing);
    expect(find.byKey(const Key('quest_answer_a_right')), findsOneWidget);
  });
}
