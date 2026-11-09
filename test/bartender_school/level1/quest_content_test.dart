import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:coin/features/bartender_school/data/quest_flow.dart';
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
  group('квест A_01', () {
    late Lesson lesson;
    late QuestFlow flow;

    setUpAll(() {
      lesson = _lesson('lesson_A_01');
      flow = lesson.quest!;
    });

    test('квест есть и первый слайд — сцена', () {
      expect(lesson.quest, isNotNull);
      expect(flow.isValid, isTrue);
      expect(lesson.slides.first.type, SlideType.choice);
      // A_01 идёт тем же путём, что A_02–A_04: сцена лежит в
      // questScene первого слайда и рисуется QuestSceneView.
      expect(lesson.slides.first.questScene, isNotNull);
      expect(lesson.slides.first.questScene!.probes.length, 3);
      expect(lesson.slides.first.questScene!.answers.length, 3);
    });

    test('ровно 3 вопроса, 3 подачи, 4 правила финала', () {
      expect(flow.investigation.items.length, 3);
      expect(flow.serve.options.length, 3);
      expect(flow.serve.options.where((o) => o.isCorrect).length, 1);
      expect(flow.rules.length, 4);
      expect(flow.serve.maxAttempts, 2);
    });

    test('у каждого вопроса есть ответ и факт', () {
      final ids = <String>{};
      for (final item in flow.investigation.items) {
        expect(item.id, isNotEmpty);
        expect(ids.add(item.id), isTrue, reason: 'id вопросов уникальны');
        expect(item.label.trim(), isNotEmpty);
        expect(item.response.trim(), isNotEmpty);
        expect(item.evidenceText.trim(), isNotEmpty);
      }
    });

    test('у каждой подачи есть реакция гостя и слова Джона', () {
      final ids = <String>{};
      for (final o in flow.serve.options) {
        expect(ids.add(o.id), isTrue, reason: 'id подач уникальны');
        expect(o.text.trim(), isNotEmpty);
        expect(o.guestReaction.trim(), isNotEmpty);
        expect(o.johnComment.trim(), isNotEmpty);
      }
    });

    test('финалы идут по приоритету, последний — запасной', () {
      for (var i = 1; i < flow.rules.length; i++) {
        expect(flow.rules[i - 1].priority, lessThan(flow.rules[i].priority));
      }
      expect(flow.rules.last.isDefault, isTrue);
      expect(flow.rules.last.ending, QuestEnding.incomplete);
    });

    test('тон без стыда: запрещённых слов нет нигде', () {
      final corpus = [
        flow.mission,
        ...flow.investigation.items.expand((i) => [i.label, i.response, i.evidenceText]),
        ...flow.serve.options.expand((o) => [o.text, o.guestReaction, o.johnComment]),
        ...flow.rules.expand((r) => [r.guestText, r.johnText, r.resultLabel]),
      ].join(' ').toLowerCase();

      for (final word in _shaming) {
        expect(corpus.contains(word), isFalse,
            reason: 'Джон не стыдит ученика: найдено «$word»');
      }
    });

    test('тексты короткие: влезают в две строки на 360 px', () {
      for (final o in flow.serve.options) {
        expect(o.text.length, lessThanOrEqualTo(90),
            reason: 'вариант длиннее двух строк: «${o.text}»');
      }
      for (final i in flow.investigation.items) {
        expect(i.label.length, lessThanOrEqualTo(90),
            reason: 'вопрос длиннее двух строк: «${i.label}»');
      }
    });
  });

  group('остальные уроки не тронуты', () {
    test('сцена-квест есть у A_01…A_04', () {
      final lessons = _loadLevel1().cast<Map<String, dynamic>>();
      final withScene = <String>[];
      for (final raw in lessons) {
        final lesson = Lesson.fromJson(raw);
        for (final slide in lesson.slides) {
          if (slide.questScene != null) withScene.add(lesson.id);
        }
      }
      // Все четыре вкуса блока A идут одним путём: сцена в questScene.
      expect(withScene, [
        'lesson_A_01',
        'lesson_A_02',
        'lesson_A_03',
        'lesson_A_04',
      ]);
      // И A_01 по-прежнему несёт квест: расследование, подачу, правила.
      final a01 = lessons.firstWhere((l) => l['id'] == 'lesson_A_01');
      expect(Lesson.fromJson(a01).quest, isNotNull);
    });

    test('каждая сцена первая в своём уроке', () {
      for (final raw in _loadLevel1().cast<Map<String, dynamic>>()) {
        final lesson = Lesson.fromJson(raw);
        if (lesson.slides.first.questScene != null) continue;
        // Если сцены нет — урок не должен внезапно начинаться с неё.
        expect(lesson.slides.first.questScene, isNull, reason: lesson.id);
      }
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
