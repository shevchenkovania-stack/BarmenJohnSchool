import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:coin/features/bartender_school/data/quest_scene.dart';
import 'package:coin/features/bartender_school/domain/entities/lesson.dart';

/// Слова, которыми Джон стыдит ученика. Тот же список, что проверяет
/// `john_reactions_test.dart`: сцена не наказывает за ошибку.
const _shaming = [
  'позор',
  'стыдно',
  'слабо',
  'провалил окончательно',
];

List<dynamic> _loadLevel1() {
  final part1 = jsonDecode(
    File('data/content/lessons_level1_part1.json').readAsStringSync(),
  ) as List;
  final part2 = jsonDecode(
    File('data/content/lessons_level1_part2.json').readAsStringSync(),
  ) as List;
  return [...part1, ...part2];
}

Lesson _lesson(String id) {
  final raw = _loadLevel1().cast<Map<String, dynamic>>();
  return Lesson.fromJson(raw.firstWhere((l) => l['id'] == id));
}

void main() {
  group('сцена A_01', () {
    late LessonSlide sceneSlide;
    late QuestScene scene;

    setUpAll(() {
      final lesson = _lesson('lesson_A_01');
      sceneSlide = lesson.slides.first;
      scene = sceneSlide.questScene!;
    });

    test('сцена стоит первым слайдом урока', () {
      expect(sceneSlide.type, SlideType.choice);
      expect(scene, isNotNull);
    });

    test('есть титры, реплики и слова гостя', () {
      expect(scene.timeStamp, contains('1874'));
      expect(scene.beats.length, greaterThanOrEqualTo(3));
      expect(
        scene.beats.any((b) => b.speaker != null && b.speaker!.isNotEmpty),
        isTrue,
        reason: 'в сцене должна звучать реплика гостя',
      );
    });

    test('ровно 3 вопроса и 3 действия, верный ровно один', () {
      expect(scene.probes.length, 3);
      expect(scene.answers.length, 3);
      expect(scene.answers.where((a) => a.isRight).length, 1);
      expect(scene.isValid, isTrue);
    });

    test('у каждого вопроса есть ответ и вывод', () {
      final ids = <String>{};
      for (final probe in scene.probes) {
        expect(probe.id, isNotEmpty);
        expect(ids.add(probe.id), isTrue, reason: 'id вопросов уникальны');
        expect(probe.label.trim(), isNotEmpty);
        expect(probe.response.trim(), isNotEmpty);
        expect(probe.insight.trim(), isNotEmpty);
      }
    });

    test('у каждого действия есть реакция гостя и вывод Джона', () {
      final ids = <String>{};
      for (final option in scene.answers) {
        expect(option.id, isNotEmpty);
        expect(ids.add(option.id), isTrue, reason: 'id действий уникальны');
        expect(option.text.trim(), isNotEmpty);
        expect(option.guestReaction.trim(), isNotEmpty);
        expect(option.johnLesson.trim(), isNotEmpty);
      }
    });

    test('гость отвечает на каждый вопрос по-своему', () {
      final responses = scene.probes.map((p) => p.response).toSet();
      expect(responses.length, scene.probes.length,
          reason: 'иначе вопросы бессмысленны');
    });

    test('тон без стыда: запрещённых слов нет нигде', () {
      final corpus = [
        scene.title,
        scene.timeStamp,
        ...scene.beats.map((b) => b.text),
        ...scene.probes.expand((p) => [p.label, p.response, p.insight]),
        ...scene.answers.expand(
          (a) => [a.text, a.guestReaction, a.johnLesson],
        ),
      ].join(' ').toLowerCase();

      for (final word in _shaming) {
        expect(
          corpus.contains(word),
          isFalse,
          reason: 'Джон не стыдит ученика: найдено «$word»',
        );
      }
    });

    test('реплики не превращаются в простыню', () {
      for (final beat in scene.beats) {
        expect(beat.text.length, lessThanOrEqualTo(320),
            reason: 'длинная реплика не влезет в сцену');
      }
      for (final option in scene.answers) {
        expect(option.johnLesson.length, lessThanOrEqualTo(420));
        expect(option.guestReaction.length, lessThanOrEqualTo(240));
      }
    });
  });

  group('остальные уроки не тронуты', () {
    test('сцена есть только у A_01', () {
      final lessons = _loadLevel1().cast<Map<String, dynamic>>();
      final withScene = <String>[];
      for (final raw in lessons) {
        final lesson = Lesson.fromJson(raw);
        for (final slide in lesson.slides) {
          if (slide.questScene != null) withScene.add(lesson.id);
        }
      }
      expect(withScene, ['lesson_A_01']);
    });

    test('все 12 уроков Level 1 читаются и непустые', () {
      final lessons = _loadLevel1().cast<Map<String, dynamic>>();
      expect(lessons.length, greaterThanOrEqualTo(12));
      for (final raw in lessons) {
        final lesson = Lesson.fromJson(raw);
        expect(lesson.slides, isNotEmpty, reason: lesson.id);
      }
    });
  });
}
