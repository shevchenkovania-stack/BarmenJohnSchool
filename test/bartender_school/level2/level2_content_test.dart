import 'dart:convert';
import 'dart:io';

import 'package:coin/features/bartender_school/data/practice_challenges.dart';
import 'package:flutter_test/flutter_test.dart';

List<Map<String, dynamic>> _readJson(String path) =>
    (json.decode(File(path).readAsStringSync()) as List<dynamic>)
        .cast<Map<String, dynamic>>();

void main() {
  group('Level 2 bartender school content', () {
    late List<Map<String, dynamic>> lessons;
    late List<Map<String, dynamic>> quizzes;

    setUpAll(() {
      lessons = _readJson('data/content/lessons_level2.json');
      quizzes = _readJson('data/content/quizzes_level2.json');
    });

    test('has the complete 12-lesson D-F path', () {
      expect(
        lessons.map((lesson) => lesson['id']).toList(),
        equals([
          'lesson_D_13',
          'lesson_D_14',
          'lesson_D_15',
          'lesson_D_16',
          'lesson_E_17',
          'lesson_E_18',
          'lesson_E_19',
          'lesson_E_20',
          'lesson_F_21',
          'lesson_F_22',
          'lesson_F_23',
          'lesson_F_24',
        ]),
      );
    });

    test('uses one strict unlock chain after Level 1', () {
      expect(lessons.first['unlockCondition'], 'lesson_C_12');
      for (var index = 1; index < lessons.length; index++) {
        expect(
          lessons[index]['unlockCondition'],
          lessons[index - 1]['id'],
          reason: '${lessons[index]['id']} must follow the previous lesson',
        );
      }
    });

    test('gives every lesson complete mentor-led content', () {
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

    test('has a usable quiz for every lesson', () {
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
          final type = question['type'] as String;
          expect(
            ['singleChoice', 'multipleChoice', 'trueFalse'],
            contains(type),
            reason: '${question['id']} uses an unverified interaction',
          );
        }
      }
    });

    test('has four separate Level 2 classic practices', () {
      final challenges = allPracticeChallenges
          .where((challenge) => challenge.blockId == 'E')
          .toList();

      expect(
        challenges.map((item) => item.id).toSet(),
        level2DiplomaChallengeIds.toSet(),
      );
      expect(
        challenges.map((item) => item.lessonId).toSet(),
        {'lesson_E_17', 'lesson_E_18', 'lesson_E_19', 'lesson_E_20'},
      );
    });

    test('has a generated card image for every lesson', () {
      const paths = [
        'images/lesson_d_13_spec.jpg',
        'images/lesson_d_14_substitution.jpg',
        'images/lesson_d_15_texture.jpg',
        'images/lesson_d_16_temperature.jpg',
        'images/lesson_e_17_whiskey_sour.jpg',
        'images/lesson_e_18_old_fashioned.jpg',
        'images/lesson_e_19_dry_martini.jpg',
        'images/lesson_e_20_margarita.jpg',
        'images/lesson_f_21_prep_safety.jpg',
        'images/lesson_f_22_guest_brief.jpg',
        'images/lesson_f_23_service_rush.jpg',
        'images/lesson_f_24_exam.jpg',
      ];

      expect(paths, hasLength(lessons.length));
      for (final path in paths) {
        expect(File(path).existsSync(), isTrue, reason: '$path is missing');
      }
    });
  });
}
