/// Represents the student's progress in the bartender school.
class SchoolProgress {
  int totalXP;
  int coins; // Spendable currency for wisdom
  int streak;
  Map<String, LessonStatus> lessonStatuses;
  Map<String, List<String>> usedQuestionIds;
  List<String> unlockedCocktails;
  List<String> achievements;
  List<String> purchasedWisdom; // IDs of purchased wisdom fragments
  DateTime? lastStudyDate;

  SchoolProgress({
    this.totalXP = 0,
    this.coins = 0,
    this.streak = 0,
    Map<String, LessonStatus>? lessonStatuses,
    Map<String, List<String>>? usedQuestionIds,
    List<String>? unlockedCocktails,
    List<String>? achievements,
    List<String>? purchasedWisdom,
    this.lastStudyDate,
  })  : lessonStatuses = lessonStatuses ?? {},
        usedQuestionIds = usedQuestionIds ?? {},
        unlockedCocktails = unlockedCocktails ?? [],
        achievements = achievements ?? [],
        purchasedWisdom = purchasedWisdom ?? [];

  /// Converts progress to JSON for Hive storage.
  Map<String, dynamic> toJson() {
    return {
      'totalXP': totalXP,
      'coins': coins,
      'streak': streak,
      'lessonStatuses': lessonStatuses.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
      'usedQuestionIds': usedQuestionIds,
      'unlockedCocktails': unlockedCocktails,
      'achievements': achievements,
      'purchasedWisdom': purchasedWisdom,
      'lastStudyDate': lastStudyDate?.toIso8601String(),
    };
  }

  /// Creates progress from JSON stored in Hive.
  factory SchoolProgress.fromJson(Map<String, dynamic> json) {
    return SchoolProgress(
      totalXP: json['totalXP'] as int? ?? 0,
      coins: json['coins'] as int? ?? 0,
      streak: json['streak'] as int? ?? 0,
      lessonStatuses: (json['lessonStatuses'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              LessonStatus.values.firstWhere(
                (e) => e.toString() == value,
                // Неизвестная строка (даунгрейд версии приложения) не должна
                // превращать пройденный урок в заблокированный.
                orElse: () => LessonStatus.available,
              ),
            ),
          ) ??
          {},
      usedQuestionIds: (json['usedQuestionIds'] as Map<String, dynamic>?)
              ?.map((key, value) => MapEntry(key, (value as List).cast<String>())) ??
          {},
      unlockedCocktails: (json['unlockedCocktails'] as List?)?.cast<String>() ?? [],
      achievements: (json['achievements'] as List?)?.cast<String>() ?? [],
      purchasedWisdom: (json['purchasedWisdom'] as List?)?.cast<String>() ?? [],
      lastStudyDate: json['lastStudyDate'] != null
          ? DateTime.parse(json['lastStudyDate'] as String)
          : null,
    );
  }

  /// Creates empty progress for first-time users.
  factory SchoolProgress.empty() {
    return SchoolProgress();
  }
}

/// Status of a lesson.
enum LessonStatus {
  locked,
  available,
  inProgress,
  completed,
}
