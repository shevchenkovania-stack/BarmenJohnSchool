/// Bartender School configuration.
/// Set DEBUG_MODE to true to unlock all lessons for testing.
class BartenderSchoolConfig {
  /// When true, all lessons are unlocked regardless of prerequisites.
  /// Set to false in production.
  static const bool DEBUG_UNLOCK_ALL = false; // Production mode

  /// Expected number of lessons in each level.
  static const int level1LessonCount = 13;
  static const int level2LessonCount = 12;

  /// Number of Wisdom fragments in the vault.
  static const int wisdomFragmentCount = 7;

  /// XP earned per completed lesson (cumulative, for rank)
  static const int xpPerLesson = 50;

  /// XP earned per quiz passed (cumulative, for rank)
  static const int xpPerQuiz = 25;

  /// Minimum score to pass a quiz (percentage)
  static const int quizPassingScore = 70;

  // ── Coin Economy (Монеты — spendable currency) ────────────────────────

  /// Base coins earned per lesson completion.
  static const int coinsPerLesson = 50;

  /// Bonus coins based on quiz performance.
  /// Returns bonus coins for a given quiz percentage.
  static int coinsQuizBonus(int percentage) {
    if (percentage >= 100) return 75; // Perfect score
    if (percentage >= 90) return 50; // Excellent
    if (percentage >= 70) return 25; // Passed
    return 0; // Failed
  }

  /// Coins earned per practice challenge star.
  static const int coinsPerPracticeStar = 25;

  // ── Wisdom Prices (Стоимость фрагментов мудрости) ─────────────────────

  /// Price of each wisdom fragment (by lessonNumber 1-7).
  /// Progressive pricing: early fragments are cheap, later ones cost more.
  static const Map<int, int> wisdomPrices = {
    1: 50,
    2: 80,
    3: 120,
    4: 150,
    5: 180,
    6: 220,
    7: 300,
  };

  /// Blocks of Level 1 whose completion opens each wisdom fragment.
  ///
  /// Wisdom follows the school, not the calendar: finished block A — two
  /// notes, finished B — three more, finished C — the last two with the
  /// exam. Kept here (not in the screens) so the counter on the main screen
  /// and the vault always agree.
  static const Map<int, String> wisdomBlocks = {
    1: 'A',
    2: 'A',
    3: 'B',
    4: 'B',
    5: 'B',
    6: 'C',
    7: 'C',
  };

  /// Level-1 blocks in the order the student passes them.
  static const List<String> level1BlockOrder = ['A', 'B', 'C'];

  /// Minimum completed lessons required to purchase wisdom fragment N.
  ///
  /// Derived from [wisdomBlocks]: the number of lessons in the blocks that
  /// come before the one that opens the fragment. Kept as numbers because
  /// the UI shows "Откроется после урока N".
  static Map<int, int> get wisdomLessonRequirements {
    const lessonsPerBlock = {'A': 4, 'B': 5, 'C': 4};
    final result = <int, int>{};
    for (final entry in wisdomBlocks.entries) {
      final orderIndex = level1BlockOrder.indexOf(entry.value);
      var required = 0;
      for (var i = 0; i < orderIndex; i++) {
        required += lessonsPerBlock[level1BlockOrder[i]] ?? 0;
      }
      result[entry.key] = required;
    }
    return result;
  }
}
