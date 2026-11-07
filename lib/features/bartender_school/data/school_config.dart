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

  /// Minimum completed lessons required to purchase wisdom fragment N.
  /// Prevents buying ahead without learning.
  static const Map<int, int> wisdomLessonRequirements = {
    1: 1,
    2: 2,
    3: 4,
    4: 5,
    5: 7,
    6: 9,
    7: 12,
  };
}
