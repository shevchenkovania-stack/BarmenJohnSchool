import 'package:coin/features/bartender_school/data/lesson_repository.dart';
import 'package:coin/features/bartender_school/data/practice_challenges.dart';
import 'package:coin/features/bartender_school/data/progress_service.dart';
import 'package:coin/features/bartender_school/domain/entities/lesson.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProgressService> _newProgress({
  LessonRepository? repository,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return ProgressService(prefs, lessonRepo: repository);
}

Future<LessonRepository> _newRepository() async {
  final repository = LessonRepository();
  await repository.loadLevel1();
  await repository.loadWisdom();
  return repository;
}

List<Lesson> _level1Lessons(LessonRepository repository) {
  return repository.lessons
      .where((lesson) => const ['A', 'B', 'C'].contains(lesson.blockId))
      .toList()
    ..sort((a, b) => a.lessonNumber.compareTo(b.lessonNumber));
}

void _completeRegular(ProgressService progress, int count) {
  final ids = [
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
  ];
  for (final id in ids.take(count)) {
    progress.completeLesson(id, xpEarned: 0);
  }
}

void _awardDiplomaStars(ProgressService progress, {int stars = 2}) {
  for (final id in level1DiplomaChallengeIds) {
    final challenge = allPracticeChallenges.firstWhere(
      (item) => item.id == id,
    );
    progress.recordPracticeAttempt(
      challenge: challenge,
      stars: stars,
      timeBonusEarned: false,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Wisdom fragments open sequentially', () {
    test('a later fragment is locked until the previous one is completed',
        () async {
      final repository = await _newRepository();
      final progress = await _newProgress(repository: repository);
      progress.earnCoins(10000);
      _completeRegular(progress, 13);

      expect(progress.isWisdomAvailable(1), isTrue);
      for (var number = 2; number <= 7; number++) {
        expect(
          progress.isWisdomAvailable(number),
          isFalse,
          reason: 'фрагмент $number не должен открываться до предыдущего',
        );
      }

      expect(progress.purchaseWisdom(1), isTrue);
      expect(progress.isWisdomPurchased(1), isTrue);
      expect(progress.isWisdomAvailable(2), isFalse,
          reason: 'покупка без прочтения не открывает следующий фрагмент');

      progress.completeLesson('lesson_W_01', xpEarned: 0);
      expect(progress.isWisdomAvailable(2), isTrue);
      expect(progress.isWisdomAvailable(3), isFalse);
    });

    test('wisdom follows the school blocks', () async {
      final repository = await _newRepository();
      final progress = await _newProgress(repository: repository);
      progress.earnCoins(100000);

      // Блок A (4 урока) — открываются записи 1 и 2.
      _completeRegular(progress, 4);
      expect(progress.isWisdomAvailable(1), isTrue);
      expect(progress.isWisdomAvailable(2), isFalse,
          reason: 'вторая запись ждёт прочтения первой');
      progress.purchaseWisdom(1);
      progress.completeLesson('lesson_W_01', xpEarned: 0);
      expect(progress.isWisdomAvailable(2), isTrue);
      expect(progress.isWisdomAvailable(3), isFalse,
          reason: 'до конца блока B третьей записи быть не должно');

      // Блок B (уроки 5-9) — открываются записи 3, 4, 5.
      _completeRegular(progress, 9);
      progress.purchaseWisdom(2);
      progress.completeLesson('lesson_W_02', xpEarned: 0);
      expect(progress.isWisdomAvailable(3), isTrue);
      expect(progress.isWisdomAvailable(6), isFalse,
          reason: 'записи блока C ещё закрыты');

      // Блок C (10-13) — открываются последние две.
      _completeRegular(progress, 13);
      for (var number = 3; number <= 6; number++) {
        progress.purchaseWisdom(number);
        progress.completeLesson(
          'lesson_W_${number.toString().padLeft(2, '0')}',
          xpEarned: 0,
        );
      }
      expect(progress.isWisdomAvailable(7), isTrue);
      expect(progress.purchaseWisdom(7), isTrue);
    });

    test('block B does not open the last fragments by itself', () async {
      final repository = await _newRepository();
      final progress = await _newProgress(repository: repository);
      progress.earnCoins(100000);
      _completeRegular(progress, 9);

      expect(progress.isWisdomBlockCompleted(5), isTrue);
      expect(progress.isWisdomBlockCompleted(6), isFalse);
      expect(progress.wisdomBlockFor(6), 'C');
      expect(progress.wisdomRequiredLessons(6), 9);
    });

    test('fragment waits for its block to be finished', () async {
      final repository = await _newRepository();
      final progress = await _newProgress(repository: repository);
      progress.earnCoins(10000);
      _completeRegular(progress, 3);

      expect(progress.isWisdomAvailable(1), isFalse,
          reason: 'в блоке A ещё есть непройденный урок');
      _completeRegular(progress, 4);
      expect(progress.isWisdomAvailable(1), isTrue);
    });

    test('purchase is coin-gated and idempotent', () async {
      final repository = await _newRepository();
      final progress = await _newProgress(repository: repository);
      _completeRegular(progress, 4);

      expect(progress.isWisdomAvailable(1), isTrue);
      expect(progress.purchaseWisdom(1), isFalse);
      expect(progress.isWisdomPurchased(1), isFalse);

      progress.earnCoins(progress.getWisdomPrice(1));
      expect(progress.purchaseWisdom(1), isTrue);
      expect(progress.coins, 0);
      expect(progress.purchaseWisdom(1), isFalse);
      expect(progress.coins, 0);
    });
  });

  group('Level 1 diploma is honest', () {
    test('requires all 13 Level 1 lessons', () async {
      final repository = await _newRepository();
      final lessons = _level1Lessons(repository);
      expect(lessons.length, 13);

      final progress = await _newProgress(repository: repository);
      for (final lesson in lessons.take(12)) {
        progress.completeLesson(lesson.id, xpEarned: 0);
      }
      _awardDiplomaStars(progress);

      expect(progress.isSchoolCompleted(lessonRepo: repository), isFalse);
    });

    test('requires all three classic practices at 2+ stars', () async {
      final repository = await _newRepository();
      final progress = await _newProgress(repository: repository);
      for (final lesson in _level1Lessons(repository)) {
        progress.completeLesson(lesson.id, xpEarned: 0);
      }

      _awardDiplomaStars(progress);
      expect(progress.isSchoolCompleted(lessonRepo: repository), isTrue);

      final weak = await _newProgress(repository: repository);
      for (final lesson in _level1Lessons(repository)) {
        weak.completeLesson(lesson.id, xpEarned: 0);
      }
      for (final id in level1DiplomaChallengeIds) {
        final challenge = allPracticeChallenges.firstWhere(
          (item) => item.id == id,
        );
        weak.recordPracticeAttempt(
          challenge: challenge,
          stars: id == level1DiplomaChallengeIds.last ? 1 : 2,
          timeBonusEarned: false,
        );
      }
      expect(weak.isSchoolCompleted(lessonRepo: repository), isFalse);
    });

    test('does not award a diploma from an empty or partial curriculum',
        () async {
      final empty = await _newProgress(repository: LessonRepository());
      _awardDiplomaStars(empty);
      expect(
        empty.isSchoolCompleted(lessonRepo: LessonRepository()),
        isFalse,
      );
    });

    test('Level 2 stays locked until the honest diploma is earned', () async {
      final repository = await _newRepository();
      final progress = await _newProgress(repository: repository);
      for (final lesson in _level1Lessons(repository)) {
        progress.completeLesson(lesson.id, xpEarned: 0);
      }
      _awardDiplomaStars(progress, stars: 1);

      expect(
        progress.isLessonUnlocked('lesson_D_13', 'lesson_C_12'),
        isFalse,
      );

      _awardDiplomaStars(progress, stars: 2);
      expect(
        progress.isLessonUnlocked('lesson_D_13', 'lesson_C_12'),
        isTrue,
      );
    });
  });
}
