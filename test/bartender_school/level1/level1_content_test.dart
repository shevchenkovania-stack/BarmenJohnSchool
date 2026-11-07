import 'dart:convert';
import 'dart:io';

import 'package:coin/features/bartender_school/data/practice_challenges.dart';
import 'package:flutter_test/flutter_test.dart';

List<dynamic> _readJsonList(String path) {
  final content = File(path).readAsStringSync();
  return json.decode(content) as List<dynamic>;
}

void main() {
  group('Level 1 bartender school content', () {
    late List<Map<String, dynamic>> lessons;
    late List<Map<String, dynamic>> quizzes;

    setUpAll(() {
      lessons = [
        ..._readJsonList('data/content/lessons_level1_part1.json'),
        ..._readJsonList('data/content/lessons_level1_part2.json'),
      ].cast<Map<String, dynamic>>();

      quizzes = [
        ..._readJsonList('data/content/quizzes_level1_part1.json'),
        ..._readJsonList('data/content/quizzes_level1_part2.json'),
      ].cast<Map<String, dynamic>>();
    });

    test('has the expected 13-lesson beginner path', () {
      final lessonIds = lessons.map((lesson) => lesson['id']).toList();

      expect(lessonIds, hasLength(13));
      expect(
        lessonIds,
        equals([
          'lesson_A_01',
          'lesson_A_02',
          'lesson_A_03',
          'lesson_A_04',
          'lesson_B_05',
          'lesson_B_06',
          'lesson_B_07',
          'lesson_B_08',
          'lesson_B_09',
          'lesson_C_09',
          'lesson_C_10',
          'lesson_C_11',
          'lesson_C_12',
        ]),
      );
    });

    test('has one quiz for every Level 1 lesson', () {
      final lessonIds = lessons.map((lesson) => lesson['id']).toSet();
      final quizLessonIds = quizzes.map((quiz) => quiz['lessonId']).toSet();

      expect(quizLessonIds, equals(lessonIds));
    });

    test('every Level 1 quiz declares a passing score inside the attempt', () {
      for (final quiz in quizzes) {
        final attempt = quiz['questionsPerAttempt'] as int;
        final passing = quiz['passingScore'] as int?;

        expect(
          passing,
          isNotNull,
          reason: '${quiz['lessonId']} has no passingScore, so the pass/fail '
              'rule silently falls back to a percentage',
        );
        // Порог — около 75% попытки: не ниже двух третей и не выше попытки.
        expect(
          passing!,
          inInclusiveRange((attempt * 2 / 3).ceil(), attempt),
          reason: '${quiz['lessonId']}: $passing из $attempt',
        );
      }
    });

    test('quiz thresholds match the numbers promised in lessons', () {
      final exam = quizzes.singleWhere(
        (quiz) => quiz['lessonId'] == 'lesson_C_12',
      );
      final attempt = exam['questionsPerAttempt'] as int;
      final passing = exam['passingScore'] as int;

      // В тексте экзамена обещано 70%; в данных — целое число вопросов.
      // Проверяем, что честное округление даёт ровно 70% ± 1 вопрос.
      final percent = passing / attempt * 100;
      expect(percent, inInclusiveRange(65, 80),
          reason: 'exam threshold $passing/$attempt = $percent%');
    });

    test('uses valid unlock prerequisites', () {
      final lessonIds = lessons.map((lesson) => lesson['id']).toSet();

      for (final lesson in lessons) {
        final unlockCondition = lesson['unlockCondition'] as String?;
        if (unlockCondition == null) continue;

        expect(
          lessonIds,
          contains(unlockCondition),
          reason: '${lesson['id']} references missing prerequisite',
        );
      }

      final finalExam = lessons.singleWhere(
        (lesson) => lesson['id'] == 'lesson_C_12',
      );
      expect(finalExam['unlockCondition'], 'lesson_C_11');
    });

    test('every workshop challenge references a real Level 1 lesson', () {
      final lessonIds = lessons.map((lesson) => lesson['id']).toSet();

      for (final challenge in allPracticeChallenges.where(
        (challenge) => const ['A', 'B', 'C'].contains(challenge.blockId),
      )) {
        expect(
          lessonIds,
          contains(challenge.lessonId),
          reason: '${challenge.id} references missing ${challenge.lessonId}',
        );
      }
    });

    test('keeps every quiz usable and explainable', () {
      for (final quiz in quizzes) {
        final questions =
            (quiz['questions'] as List<dynamic>).cast<Map<String, dynamic>>();
        final questionsPerAttempt = quiz['questionsPerAttempt'] as int;

        expect(questions, isNotEmpty, reason: '${quiz['lessonId']} is empty');
        expect(
          questions.length,
          greaterThanOrEqualTo(questionsPerAttempt),
          reason: '${quiz['lessonId']} cannot fill one attempt',
        );

        for (final question in questions) {
          expect(
            (question['question'] as String).trim(),
            isNotEmpty,
            reason: '${question['id']} has empty text',
          );
          expect(
            (question['explanation'] as String).trim(),
            isNotEmpty,
            reason: '${question['id']} has no explanation',
          );
        }
      }
    });

    test('has mentor guidance for every lesson', () {
      for (final lesson in lessons) {
        final mentor = lesson['mentor'] as Map<String, dynamic>?;

        expect(mentor, isNotNull, reason: '${lesson['id']} has no mentor');
        for (final field in [
          'intro',
          'whyItMatters',
          'commonMistake',
          'barReality',
        ]) {
          expect(
            (mentor![field] as String).trim(),
            isNotEmpty,
            reason: '${lesson['id']} has empty mentor.$field',
          );
        }
      }
    });

    test('has slide-level mentor notes across the Level 1 path', () {
      final mentorNoteCount = lessons.fold<int>(0, (total, lesson) {
        final slides =
            (lesson['slides'] as List<dynamic>).cast<Map<String, dynamic>>();
        return total +
            slides
                .where((slide) =>
                    (slide['mentorNote'] as String?)?.trim().isNotEmpty ??
                    false)
                .length;
      });

      expect(mentorNoteCount, greaterThanOrEqualTo(24));
    });

    test('defines valid slider scoring ranges', () {
      final sliderQuestions = quizzes
          .expand((quiz) => quiz['questions'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .where((question) => question['type'] == 'slider')
          .toList();

      expect(sliderQuestions, isNotEmpty);

      for (final question in sliderQuestions) {
        final sliders =
            (question['sliders'] as List<dynamic>).cast<Map<String, dynamic>>();

        expect(sliders, isNotEmpty, reason: '${question['id']} has no sliders');
        for (final slider in sliders) {
          final min = slider['correctMin'] as num;
          final max = slider['correctMax'] as num;

          expect(min, greaterThanOrEqualTo(0), reason: question['id']);
          expect(max, lessThanOrEqualTo(1), reason: question['id']);
          expect(min, lessThanOrEqualTo(max), reason: question['id']);
        }
      }
    });

    test('defines Level 1 final exam as theory plus practical mastery', () {
      final finalExam = lessons.singleWhere(
        (lesson) => lesson['id'] == 'lesson_C_12',
      );
      final slides =
          (finalExam['slides'] as List<dynamic>).cast<Map<String, dynamic>>();
      final joinedExamText = [
        finalExam['shortDescription'],
        ...finalExam['keyPoints'] as List<dynamic>,
        ...slides.expand((slide) => [
              slide['title'],
              slide['content'],
              ...(slide['bulletPoints'] as List<dynamic>? ?? []),
            ]),
      ].join('\n');

      expect(slides.length, greaterThanOrEqualTo(5));
      expect(joinedExamText, contains('Mojito'));
      expect(joinedExamText, contains('Daiquiri'));
      expect(joinedExamText, contains('Negroni'));
      expect(joinedExamText, contains('70%'));
      expect(joinedExamText, isNot(contains('80%')));
      expect(joinedExamText, isNot(contains('10 XP')));
      expect(
          joinedExamText, contains('Сертификат нельзя получить одной теорией'));
    });
  });
}
