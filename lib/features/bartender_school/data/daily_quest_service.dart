/// Ежедневные задания — механика удержания (из Duolingo).
///
/// 4 задания в день, сбрасываются в 00:00. Каждое даёт монеты.
/// Все 4 выполнены → бонус "День закрыт" (+50 монет).
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Модель задания ──────────────────────────────────────────────────────────

enum DailyQuestType {
  completeLesson,  // Пройди 1 урок
  practiceCocktail, // Сделай коктейль в мастерской
  passQuiz,        // Ответь на квиз на 80%+
  openApp,         // Зайди в приложение
}

class DailyQuest {
  final DailyQuestType type;
  final String title;
  final String emoji;
  final int coinReward;
  bool isCompleted;

  DailyQuest({
    required this.type,
    required this.title,
    required this.emoji,
    required this.coinReward,
    this.isCompleted = false,
  });
}

// ── Сервис ──────────────────────────────────────────────────────────────────

class DailyQuestService extends ChangeNotifier {
  final SharedPreferences _prefs;

  DailyQuestService(this._prefs) {
    _checkAndReset();
  }

  static const String _dateKey = 'daily_quests_date';
  static const String _completedKey = 'daily_quests_completed';
  static const String _bonusClaimedKey = 'daily_quests_bonus_claimed';

  /// Все 4 ежедневных задания.
  List<DailyQuest> _quests = _buildQuests();

  List<DailyQuest> get quests => List.unmodifiable(_quests);

  /// Сколько заданий выполнено сегодня.
  int get completedCount => _quests.where((q) => q.isCompleted).length;

  /// Все 4 выполнены?
  bool get allCompleted => completedCount == 4;

  /// Бонус за все 4 уже получен?
  bool get isBonusClaimed => _prefs.getBool(_bonusClaimedKey) ?? false;

  /// Суммарная награда за все невыполненные задания.
  int get pendingReward => _quests
      .where((q) => !q.isCompleted)
      .fold(0, (sum, q) => sum + q.coinReward);

  /// Суммарная награда за выполненные (но ещё не забранные).
  int get earnedReward => _quests
      .where((q) => q.isCompleted)
      .fold(0, (sum, q) => sum + q.coinReward);

  // ── Проверка даты ────────────────────────────────────────────────────────

  /// Проверяет, нужно ли сбросить задания (новый день).
  void _checkAndReset() {
    final today = _todayString();
    final saved = _prefs.getString(_dateKey);
    if (saved != today) {
      _resetQuests();
    } else {
      _loadCompleted();
    }
  }

  /// Сброс заданий на новые.
  Future<void> _resetQuests() async {
    _quests = _buildQuests();
    await _prefs.setString(_dateKey, _todayString());
    await _prefs.setStringList(_completedKey, []);
    await _prefs.setBool(_bonusClaimedKey, false);
    // Авто-выполнение "Зайди в приложение"
    await completeQuest(DailyQuestType.openApp);
  }

  /// Загрузка выполненных из SharedPreferences.
  void _loadCompleted() {
    _quests = _buildQuests();
    final completed = _prefs.getStringList(_completedKey) ?? [];
    for (final quest in _quests) {
      if (completed.contains(quest.type.name)) {
        quest.isCompleted = true;
      }
    }
  }

  // ── Выполнение заданий ────────────────────────────────────────────────────

  /// Отметить задание как выполненное. Возвращает награду (0 если уже выполнено).
  Future<int> completeQuest(DailyQuestType type) async {
    _checkAndReset();

    final quest = _quests.firstWhere(
      (q) => q.type == type,
      orElse: () => _quests.first,
    );

    if (quest.isCompleted) return 0;

    quest.isCompleted = true;

    // Сохраняем
    final completed = _prefs.getStringList(_completedKey) ?? [];
    completed.add(type.name);
    await _prefs.setStringList(_completedKey, completed);

    notifyListeners();
    return quest.coinReward;
  }

  /// Забрать бонус за все 4 задания. Возвращает бонус (0 если уже забран).
  Future<int> claimBonus() async {
    if (!allCompleted || isBonusClaimed) return 0;
    await _prefs.setBool(_bonusClaimedKey, true);
    notifyListeners();
    return 50; // Бонус за закрытие дня
  }

  // ── Вспомогательные ───────────────────────────────────────────────────────

  static String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static List<DailyQuest> _buildQuests() => [
        DailyQuest(
          type: DailyQuestType.openApp,
          title: 'Зайди в приложение',
          emoji: '👋',
          coinReward: 10,
        ),
        DailyQuest(
          type: DailyQuestType.completeLesson,
          title: 'Пройди 1 урок',
          emoji: '📖',
          coinReward: 50,
        ),
        DailyQuest(
          type: DailyQuestType.practiceCocktail,
          title: 'Сделай коктейль в мастерской',
          emoji: '🍸',
          coinReward: 25,
        ),
        DailyQuest(
          type: DailyQuestType.passQuiz,
          title: 'Ответь на квиз на 80%+',
          emoji: '🎯',
          coinReward: 30,
        ),
      ];
}
