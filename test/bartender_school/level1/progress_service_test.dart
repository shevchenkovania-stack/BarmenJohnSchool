import 'package:coin/features/bartender_school/data/progress_service.dart';
import 'package:coin/features/bartender_school/data/practice_challenges.dart';
import 'package:coin/features/bartender_school/data/lesson_repository.dart';
import 'package:coin/features/bartender_school/domain/entities/progress.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProgressService> _newProgressService() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return ProgressService(prefs);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Level 1 ProgressService', () {
    test('keeps a lesson locked when its prerequisite is missing', () async {
      final progress = await _newProgressService();

      expect(
        progress.isLessonUnlocked('lesson_B_05', 'lesson_A_04'),
        isFalse,
      );
    });

    test('unlocks a lesson after its prerequisite is completed', () async {
      final progress = await _newProgressService();

      progress.completeLesson('lesson_A_04');

      expect(
        progress.isLessonUnlocked('lesson_B_05', 'lesson_A_04'),
        isTrue,
      );
    });

    test('marks a new available lesson as in progress', () async {
      final progress = await _newProgressService();

      progress.startLesson('lesson_A_01');

      expect(progress.getLessonStatus('lesson_A_01'), LessonStatus.inProgress);
    });

    test('does not grant XP repeatedly for an already completed lesson',
        () async {
      final progress = await _newProgressService();

      progress.completeLesson('lesson_A_01', xpEarned: 50);
      progress.completeLesson('lesson_A_01', xpEarned: 50);

      expect(progress.totalXP, 50);
      expect(progress.getLessonStatus('lesson_A_01'), LessonStatus.completed);
    });

    test('practice XP is awarded only for a better result', () async {
      final progress = await _newProgressService();
      final challenge = allPracticeChallenges.firstWhere(
        (item) => item.id == 'practice_mojito',
      );

      final first = progress.recordPracticeAttempt(
        challenge: challenge,
        stars: 2,
        timeBonusEarned: false,
      );
      final duplicate = progress.recordPracticeAttempt(
        challenge: challenge,
        stars: 2,
        timeBonusEarned: false,
      );
      final improvement = progress.recordPracticeAttempt(
        challenge: challenge,
        stars: 3,
        timeBonusEarned: false,
      );

      expect(first.xpEarned, 20);
      expect(duplicate.xpEarned, 0);
      expect(improvement.xpEarned, 10);
      expect(progress.workshopPracticeXp, 30);
      expect(progress.isLessonPracticeComplete('lesson_C_09'), isTrue);
    });

    test('time bonus is awarded only once', () async {
      final progress = await _newProgressService();
      final mojito = allPracticeChallenges.firstWhere(
        (item) => item.id == 'practice_mojito',
      );
      final daiquiri = allPracticeChallenges.firstWhere(
        (item) => item.id == 'practice_daiquiri',
      );

      final first = progress.recordPracticeAttempt(
        challenge: mojito,
        stars: 0,
        timeBonusEarned: true,
      );
      final second = progress.recordPracticeAttempt(
        challenge: daiquiri,
        stars: 0,
        timeBonusEarned: true,
      );

      expect(first.timeBonusAwarded, isTrue);
      expect(first.xpEarned, 10);
      expect(second.timeBonusAwarded, isFalse);
      expect(second.xpEarned, 0);
    });

    test('diploma requires all theory and three classic practices', () async {
      final progress = await _newProgressService();
      final lessons = LessonRepository();
      await lessons.loadLevel1();

      for (final lesson in lessons.lessons) {
        progress.completeLesson(lesson.id, xpEarned: 0);
      }
      expect(progress.isSchoolCompleted(lessonRepo: lessons), isFalse);

      for (final challengeId in level1DiplomaChallengeIds) {
        final challenge = allPracticeChallenges.firstWhere(
          (item) => item.id == challengeId,
        );
        progress.recordPracticeAttempt(
          challenge: challenge,
          stars: 2,
          timeBonusEarned: false,
        );
      }

      expect(progress.isSchoolCompleted(lessonRepo: lessons), isTrue);
    });

    test('Level 2 stays locked until the full Level 1 diploma is earned',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final lessons = LessonRepository();
      await lessons.loadCoreCurriculum();
      final progress = ProgressService(prefs, lessonRepo: lessons);

      progress.completeLesson('lesson_C_12', xpEarned: 0);
      expect(
        progress.isLessonUnlocked('lesson_D_13', 'lesson_C_12'),
        isFalse,
      );

      for (final lesson in lessons.lessons.where(
        (item) => const ['A', 'B', 'C'].contains(item.blockId),
      )) {
        progress.completeLesson(lesson.id, xpEarned: 0);
      }
      for (final challengeId in level1DiplomaChallengeIds) {
        final challenge = allPracticeChallenges.firstWhere(
          (item) => item.id == challengeId,
        );
        progress.recordPracticeAttempt(
          challenge: challenge,
          stars: 2,
          timeBonusEarned: false,
        );
      }

      expect(
        progress.isLessonUnlocked('lesson_D_13', 'lesson_C_12'),
        isTrue,
      );
    });
  });
}
