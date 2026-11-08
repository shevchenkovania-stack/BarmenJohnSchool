import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

List<Map<String, dynamic>> _readJson(String path) =>
    (json.decode(File(path).readAsStringSync()) as List<dynamic>)
        .cast<Map<String, dynamic>>();

void main() {
  group('Level 3 block G content', () {
    late List<Map<String, dynamic>> lessons;
    late List<Map<String, dynamic>> quizzes;

    setUpAll(() {
      // Архив Level 3 лежит с префиксом legacy_: приложение его не загружает,
      // но валидация содержимого остаётся полезной.
      lessons = _readJson('data/content/legacy_lessons_level3_part1.json');
      quizzes = _readJson('data/content/legacy_quizzes_level3_part1.json');
    });

    test('contains the three G lessons in order', () {
      expect(
        lessons.map((lesson) => lesson['id']).toList(),
        equals(['lesson_G_25', 'lesson_G_26', 'lesson_G_27']),
      );
      expect(
        lessons.map((lesson) => lesson['lessonNumber']).toList(),
        equals([25, 26, 27]),
      );
    });

    test('keeps a strict unlock chain from Level 2 into block G', () {
      // unlockCondition ссылается на id урока, а не на номер,
      // поэтому перенумерация Level 2 (24 → 25) цепочку не ломает.
      expect(lessons.first['unlockCondition'], 'lesson_F_24');
      for (var index = 1; index < lessons.length; index++) {
        expect(
          lessons[index]['unlockCondition'],
          lessons[index - 1]['id'],
          reason: '${lessons[index]['id']} must follow the previous lesson',
        );
      }
    });

    test('gives every G lesson complete mentor-led content', () {
      for (final lesson in lessons) {
        final slides =
            (lesson['slides'] as List<dynamic>).cast<Map<String, dynamic>>();
        final mentor = lesson['mentor'] as Map<String, dynamic>?;

        expect(slides.length, greaterThanOrEqualTo(5), reason: lesson['id']);
        expect(mentor, isNotNull, reason: '${lesson['id']} has no mentor');
        expect((lesson['historicalStory'] as String).trim(), isNotEmpty);
        expect((lesson['nextLessonHook'] as String).trim(), isNotEmpty);
        expect(
          slides.any((slide) => slide['type'] == 'practice'),
          isTrue,
          reason: '${lesson['id']} has no practice slide',
        );
        for (final key in [
          'intro',
          'whyItMatters',
          'commonMistake',
          'barReality',
          'examAdvice',
        ]) {
          expect((mentor![key] as String).trim(), isNotEmpty);
        }
      }
    });

    test('has a usable quiz for every G lesson', () {
      final lessonIds = lessons.map((lesson) => lesson['id']).toSet();
      expect(quizzes.map((quiz) => quiz['lessonId']).toSet(), lessonIds);

      for (final quiz in quizzes) {
        final questions =
            (quiz['questions'] as List<dynamic>).cast<Map<String, dynamic>>();
        final perAttempt = quiz['questionsPerAttempt'] as int;
        expect(questions.length, greaterThanOrEqualTo(perAttempt));
        expect(
          questions.length,
          greaterThanOrEqualTo(8),
          reason: '${quiz['lessonId']} needs a meaningful question pool',
        );
        for (final question in questions) {
          expect((question['explanation'] as String).trim(), isNotEmpty);
          expect(
            ['singleChoice', 'multipleChoice', 'trueFalse'],
            contains(question['type']),
            reason: '${question['id']} uses an unverified interaction',
          );
        }
      }
    });

    test('keeps block G out of the shipped Level 1 and Level 2 paths', () {
      final level1 = [
        ..._readJson('data/content/lessons_level1_part1.json'),
        ..._readJson('data/content/lessons_level1_part2.json'),
      ];
      final level2 = _readJson('data/content/lessons_level2.json');
      final activeIds = {
        ...level1.map((lesson) => lesson['id']),
        ...level2.map((lesson) => lesson['id']),
      };

      for (final lesson in lessons) {
        expect(activeIds, isNot(contains(lesson['id'])));
      }
    });
  });
}
