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
  Key? key,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      // MediaQuery обязательно внутри MaterialApp: снаружи его затирают
      // данные окна, и disableAnimations в тесте не применяется.
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(disableAnimations: disableAnimations),
        child: child!,
      ),
      home: Scaffold(
        body: QuestSceneView(
          key: key,
          scene: _scene,
          onFinished: onFinished,
          onContinue: onContinue,
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

  testWidgets('даже без вопросов выбрать можно — но гость ответит иначе',
      (tester) async {
    await _pump(tester);
    await _tapVisible(tester, const Key('quest_next_beat'));

    // Ни одно состояние не блокирует финал.
    expect(find.byKey(const Key('quest_answer_a_right')), findsOneWidget);

    await _tapVisible(tester, const Key('quest_answer_a_right'));
    expect(find.byKey(const Key('quest_result')), findsOneWidget);
    // Цена выбора — в ответе, а не в запрете.
    expect(find.textContaining('какая разница'), findsOneWidget);
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

  testWidgets('после ответа видно, что игрок понял', (tester) async {
    await _pump(tester);
    await _tapVisible(tester, const Key('quest_next_beat'));
    await _tapVisible(tester, const Key('quest_probe_p1'));

    // Вывод из ответа — отдельной строкой, иначе вопросы читаются
    // как кнопки «дай подсказку». На экране он дважды: под ответом
    // гостя и в сводке перед выбором.
    expect(find.byKey(const Key('quest_insight')), findsWidgets);
    expect(find.textContaining('Вчера было горько'), findsWidgets);
  });

  testWidgets('выводы копятся в сводке по мере вопросов', (tester) async {
    await _pump(tester);
    await _tapVisible(tester, const Key('quest_next_beat'));

    // До первого вопроса сводки нет.
    expect(find.byKey(const Key('quest_insight_summary')), findsNothing);

    await _tapVisible(tester, const Key('quest_probe_p1'));
    expect(find.byKey(const Key('quest_insight_summary')), findsOneWidget);
    expect(find.textContaining('Ты услышал 1 из 3'), findsOneWidget);

    await _tapVisible(tester, const Key('quest_probe_p2'));
    expect(find.textContaining('Ты услышал 2 из 3'), findsOneWidget);

    await _tapVisible(tester, const Key('quest_probe_p3'));
    expect(find.textContaining('Ты услышал 3 из 3'), findsOneWidget);
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
    // Картина собрана полностью — иначе реакция была бы общей, а не по существу.
    for (final id in ['p1', 'p2', 'p3']) {
      await _tapVisible(tester, Key('quest_probe_$id'));
    }

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

  testWidgets('вслепую и с расспросом — доходишь до конца в обоих случаях',
      (tester) async {
    final finished = <QuestOption>[];

    // Вслепую: один вопрос и сразу решение.
    await _pump(tester, onFinished: finished.add);
    await _tapVisible(tester, const Key('quest_next_beat'));
    await _tapVisible(tester, const Key('quest_probe_p1'));
    await _tapVisible(tester, const Key('quest_answer_a_right'));

    expect(finished.map((o) => o.id), ['a_right']);
    expect(find.byKey(const Key('quest_result')), findsOneWidget);
    // Спрошен только один — остальных выводов у игрока нет.
    expect(find.textContaining('Он один и никуда'), findsNothing);
    expect(find.textContaining('Времени много'), findsNothing);

    // С расспросом: все три вопроса, потом то же действие.
    await tester.pumpWidget(const SizedBox());
    await _pump(tester, key: const Key('second_run'), onFinished: finished.add);
    await _tapVisible(tester, const Key('quest_next_beat'));
    for (final id in ['p1', 'p2', 'p3']) {
      await _tapVisible(tester, Key('quest_probe_$id'));
      // После каждого ответа у игрока появляется вывод.
      expect(find.byKey(const Key('quest_insight')), findsWidgets);
    }
    expect(find.textContaining('Вчера было горько'), findsWidgets);
    // Под ответом гостя и в сводке — до двух вхождений на вывод.
    expect(find.textContaining('Он один и никуда'), findsWidgets);
    expect(find.textContaining('Времени много'), findsWidgets);

    await _tapVisible(tester, const Key('quest_answer_a_right'));
    expect(finished.map((o) => o.id), ['a_right', 'a_right']);
    expect(find.byKey(const Key('quest_result')), findsOneWidget);
  });

  testWidgets('сцена дышит: гость отвечает с паузой, текст печатается',
      (tester) async {
    const authorLine = 'Бар на восемь мест. Дождь.';
    await _pump(tester, disableAnimations: false);

    // Авторская реплика печатается посимвольно, а не падает целиком.
    await tester.pump(const Duration(milliseconds: 60));
    expect(find.text(authorLine), findsNothing);

    // Когда она дописана — появляется кнопка «Дальше».
    await tester.pump(const Duration(seconds: 2));
    expect(find.text(authorLine), findsOneWidget);

    // Гость не отвечает в тот же кадр: сцена держит паузу.
    await _tapVisible(tester, const Key('quest_next_beat'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('Мне как вчера'), findsNothing);

    // Через паузу реплика гостя начинает появляться — но не целиком:
    // печать идёт посимвольно.
    await tester.pump(const Duration(milliseconds: 450));
    final partial =
        tester.widget<Text>(find.textContaining('Мне как вчера').first);
    expect(
      partial.data!.length,
      lessThan('Мне как вчера. Только не как вчера.'.length),
    );

    // Дописываем реплику до конца. pumpAndSettle здесь не годится:
    // печать идёт на Timer, а не на кадрах, и settle возвращается раньше.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Мне как вчера. Только не как вчера.'),
      findsOneWidget,
    );
  });
}
