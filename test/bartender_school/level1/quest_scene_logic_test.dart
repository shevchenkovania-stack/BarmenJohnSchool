import 'package:flutter_test/flutter_test.dart';

import 'package:coin/features/bartender_school/data/quest_scene.dart';

QuestScene _scene() => const QuestScene(
      id: 'test_scene',
      title: 'Тестовая сцена',
      timeStamp: '1874 · Манхэттен',
      beats: [
        QuestBeat(text: 'Дождь.'),
        QuestBeat(
            speaker: 'Гость', text: 'Мне как вчера. Только не как вчера.'),
      ],
      probes: [
        QuestProbe(
          id: 'p1',
          label: 'Что было вчера?',
          response: 'Горчило.',
          insight: 'Вчера было горько.',
        ),
        QuestProbe(
          id: 'p2',
          label: 'Ты один?',
          response: 'Дождь.',
          insight: 'Он один.',
        ),
        QuestProbe(
          id: 'p3',
          label: 'Сколько у тебя времени?',
          response: 'До трамвая.',
          insight: 'Времени много.',
        ),
      ],
      answers: [
        QuestOption(
          id: 'a_right',
          text: 'Высокий и лёгкий',
          isRight: true,
          guestReaction: 'Вот это другое дело.',
          johnLesson: 'Ты услышал.',
        ),
        QuestOption(
          id: 'a_strong',
          text: 'Короткий и крепкий',
          isRight: false,
          guestReaction: 'Я же сказал.',
          johnLesson: 'Он просил не про крепость.',
        ),
        QuestOption(
          id: 'a_sweet',
          text: 'Сладкий без алкоголя',
          isRight: false,
          guestReaction: 'Я не за лимонадом.',
          johnLesson: 'Слушать не значит выполнять буквально.',
        ),
      ],
    );

void main() {
  group('QuestScene: данные', () {
    test('сцена валидна: реплики, вопросы, ровно один верный ответ', () {
      final scene = _scene();
      expect(scene.isValid, isTrue);
      expect(scene.rightAnswer?.id, 'a_right');
      expect(scene.answers.where((a) => a.isRight).length, 1);
    });

    test('сериализация из JSON не теряет поля', () {
      final scene = QuestScene.fromJson({
        'id': 'json_scene',
        'title': 'Из JSON',
        'timeStamp': '1874',
        'beats': [
          {'text': 'Дождь.'},
          {'speaker': 'Гость', 'text': 'Наливай.'},
        ],
        'probes': [
          {
            'id': 'p1',
            'label': 'Что вчера?',
            'response': 'Горчило.',
            'insight': 'Горько.',
          },
        ],
        'answers': [
          {
            'id': 'a1',
            'text': 'Лёгкий',
            'isRight': true,
            'guestReaction': 'Хорошо.',
            'johnLesson': 'Верно.',
          },
        ],
      });

      expect(scene.id, 'json_scene');
      expect(scene.beats.length, 2);
      expect(scene.beats[1].speaker, 'Гость');
      expect(scene.probes.single.label, 'Что вчера?');
      expect(scene.answers.single.isRight, isTrue);
      expect(scene.isValid, isTrue);
    });

    test('битые данные не проходят валидацию', () {
      const broken = QuestScene(
        id: 'broken',
        title: '',
        timeStamp: '',
        beats: [],
        probes: [],
        answers: [],
      );
      expect(broken.isValid, isFalse);
      expect(broken.rightAnswer, isNull);
    });
  });

  group('QuestSceneState: правила прохождения', () {
    test('вопрос задаётся ровно один раз', () {
      final state = QuestSceneState(_scene());
      expect(state.ask('p1'), isTrue);
      expect(state.ask('p1'), isFalse, reason: 'повторно задать нельзя');
      expect(state.askedProbes.length, 1);
    });

    test('финал доступен всегда, даже без единого вопроса', () {
      final state = QuestSceneState(_scene());
      expect(state.canAnswer, isTrue,
          reason: 'ни одно состояние не блокирует финал');
      expect(state.choose('a_right'), isNotNull);
      expect(state.isFinished, isTrue);
    });

    test('финал доступен после первого вопроса, не после всех', () {
      final state = QuestSceneState(_scene());
      state.ask('p1');
      expect(state.canAnswer, isTrue);
    });

    test('финал засчитывается при 0, 1 и 3 вопросах', () {
      for (final probesAsked in [0, 1, 2, 3]) {
        final state = QuestSceneState(_scene());
        for (var i = 0; i < probesAsked; i++) {
          state.ask(state.scene.probes[i].id);
        }
        expect(state.choose('a_strong'), isNotNull,
            reason: 'выбор доступен при $probesAsked вопросах');
        expect(state.isFinished, isTrue);
        expect(state.wasRight, isFalse);
      }
    });

    test('ответ гостя зависит от числа заданных вопросов', () {
      final blind = QuestSceneState(_scene())..choose('a_right');
      // Ни одного вопроса — гость не рассказывает, а спрашивает сам.
      expect(blind.guestReaction, contains('какая разница'));
      expect(blind.guestReaction, isNot(_scene().answers.first.guestReaction));

      final partial = QuestSceneState(_scene())
        ..ask('p1')
        ..choose('a_right');
      expect(partial.guestReaction, isNot(blind.guestReaction));

      final full = QuestSceneState(_scene());
      for (final probe in _scene().probes) {
        full.ask(probe.id);
      }
      full.choose('a_right');
      // Всё выяснено — гость отвечает по существу варианта.
      expect(full.guestReaction, _scene().answers.first.guestReaction);
      expect(full.guestReaction, isNot(partial.guestReaction));
    });

    test('вывод Джона на раннее решение говорит о потере, а не о вине', () {
      final state = QuestSceneState(_scene())..choose('a_right');
      expect(state.johnLesson, isNot(_scene().answers.first.johnLesson));
      expect(state.johnLesson, contains('не спросил'));
    });

    test('после выбора сцена закрыта: второй выбор не проходит', () {
      final state = QuestSceneState(_scene());
      state.ask('p1');
      expect(state.choose('a_right'), isNotNull);
      expect(state.choose('a_sweet'), isNull);
      expect(state.wasRight, isTrue);
      expect(state.ask('p2'), isFalse, reason: 'после финала вопросы закрыты');
    });

    test('неизвестные id не ломают состояние', () {
      final state = QuestSceneState(_scene());
      expect(state.ask('нет_такого'), isFalse);
      state.ask('p1');
      expect(state.choose('нет_такого'), isNull);
      expect(state.isFinished, isFalse);
    });

    test('инсайты копятся и показывают раскрытие сцены', () {
      final state = QuestSceneState(_scene());
      expect(state.insights, isEmpty);
      expect(state.insightProgress, 0);

      state.ask('p1');
      expect(state.insights, ['Вчера было горько.']);
      expect(state.insightProgress, closeTo(1 / 3, 0.001));

      state.ask('p2');
      state.ask('p3');
      expect(state.insights.length, 3);
      expect(state.insightProgress, 1);
      expect(state.hasQuestionsLeft, isFalse);
    });

    test('без вопросов игрок не получил ни одного вывода', () {
      final state = QuestSceneState(_scene());
      expect(state.insights, isEmpty);
      expect(state.isFullyInformed, isFalse);
    });
  });
}
