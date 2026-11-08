import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:coin/features/bartender_school/data/school_config.dart';
import 'package:coin/features/bartender_school/data/lesson_repository.dart';
import 'package:coin/features/bartender_school/domain/entities/progress.dart';
import 'package:coin/features/bartender_school/data/practice_challenges.dart';
import 'package:coin/features/bartender_school/data/workshop_badges.dart';
import 'package:coin/features/bartender_school/data/block_rewards.dart';

/// Service for managing student progress in the bartender school.
class ProgressService extends ChangeNotifier {
  SchoolProgress _progress = SchoolProgress.empty();
  final SharedPreferences _prefs;
  final LessonRepository? _lessonRepo;

  ProgressService(this._prefs, {LessonRepository? lessonRepo})
      : _lessonRepo = lessonRepo {
    _loadProgress();
    _migrateCoinsBalance(); // Migration for existing users
  }

  SchoolProgress get progress => _progress;
  int get totalXP => _progress.totalXP;
  int get coins => _progress.coins;
  int get streak => _progress.streak;

  /// Когда занимался в последний раз. null — ещё ни разу.
  DateTime? get lastStudyDate => _progress.lastStudyDate;

  bool get hasSeenLevel1Prologue =>
      _prefs.getBool('bartender_school_seen_level1_prologue') ?? false;

  Future<void> markLevel1PrologueSeen() async {
    await _prefs.setBool('bartender_school_seen_level1_prologue', true);
    notifyListeners();
  }

  // ── Block Intro Tracking ───────────────────────────────────────────────

  /// Whether the user has seen the intro dialog for a specific block.
  bool hasSeenBlockIntro(String blockId) {
    return _prefs.getBool('bartender_block_intro_$blockId') ?? false;
  }

  /// Mark a block's intro dialog as seen.
  Future<void> markBlockIntroSeen(String blockId) async {
    await _prefs.setBool('bartender_block_intro_$blockId', true);
    notifyListeners();
  }

  // ── Student Name (for Diploma) ─────────────────────────────────────────

  /// Student's first name (for diploma).
  String get studentFirstName =>
      _prefs.getString('bartender_school_first_name') ?? '';

  /// Student's last name (for diploma, optional).
  String get studentLastName =>
      _prefs.getString('bartender_school_last_name') ?? '';

  /// Full display name for diploma.
  String get studentFullName {
    final first = studentFirstName.trim();
    final last = studentLastName.trim();
    if (first.isEmpty && last.isEmpty) return '';
    if (last.isEmpty) return first;
    return '$first $last';
  }

  /// Whether student has entered their name.
  bool get hasEnteredName => studentFirstName.trim().isNotEmpty;

  /// Save student name.
  Future<void> setStudentName({
    required String firstName,
    String lastName = '',
  }) async {
    await _prefs.setString('bartender_school_first_name', firstName.trim());
    await _prefs.setString('bartender_school_last_name', lastName.trim());
    notifyListeners();
  }

  // ── School Completion Check ──────────────────────────────────────────────

  /// Whether the entire school is completed (all blocks A, B, C done).
  /// Used to gate diploma access.
  bool isSchoolCompleted({required LessonRepository lessonRepo}) {
    // Check all lessons in blocks A, B, C are completed
    for (final blockId in ['A', 'B', 'C']) {
      for (final lesson
          in lessonRepo.lessons.where((l) => l.blockId == blockId)) {
        if (getLessonStatus(lesson.id) != LessonStatus.completed) {
          return false;
        }
      }
    }
    // Diploma practice must be demonstrated, not merely attempted once.
    return level1DiplomaChallengeIds
        .every((challengeId) => getPracticeStars(challengeId) >= 2);
  }

  /// Level 2 diploma: all D-F theory, four classics at 2+ stars and at
  /// least 9 stars out of 12 overall (75%).
  bool isLevel2Completed({required LessonRepository lessonRepo}) {
    final level2Lessons = lessonRepo.lessons
        .where((lesson) => const ['D', 'E', 'F'].contains(lesson.blockId))
        .toList();
    if (level2Lessons.length != 12) return false;
    if (level2Lessons.any(
      (lesson) => getLessonStatus(lesson.id) != LessonStatus.completed,
    )) {
      return false;
    }

    final stars = level2DiplomaChallengeIds.map(getPracticeStars).toList();
    return stars.every((value) => value >= 2) &&
        stars.fold<int>(0, (sum, value) => sum + value) >= 9;
  }

  // ── Wisdom (Мудрость старого бармена) ────────────────────────────────
  // Мудрость покупается за монеты. Каждый фрагмент имеет цену и требование
  // к прогрессу уроков. Двойное условие: монеты + прогресс.

  /// Count of completed regular lessons (blocks A, B, C).
  int get completedRegularLessons {
    if (_lessonRepo == null) return 0;
    return _lessonRepo.lessons
        .where((l) => const ['A', 'B', 'C'].contains(l.blockId))
        .where((l) => getLessonStatus(l.id) == LessonStatus.completed)
        .length;
  }

  /// Current wisdom level (0-7) — how many fragments are purchasable
  /// based on lesson progress (not coins).
  int get wisdomLevel {
    int count = 0;
    for (final entry
        in BartenderSchoolConfig.wisdomLessonRequirements.entries) {
      if (completedRegularLessons >= entry.value) count++;
    }
    return count;
  }

  /// Total wisdom fragments available.
  int get wisdomTotal => 7;

  /// Whether a wisdom fragment is available for purchase.
  /// Requires: lesson progress met AND not yet purchased.
  bool isWisdomAvailable(int wisdomNumber) {
    if (BartenderSchoolConfig.DEBUG_UNLOCK_ALL) return true;
    if (isWisdomPurchased(wisdomNumber)) return false;
    final requiredLessons =
        BartenderSchoolConfig.wisdomLessonRequirements[wisdomNumber] ?? 999;
    return completedRegularLessons >= requiredLessons;
  }

  /// Whether a wisdom fragment has been purchased.
  bool isWisdomPurchased(int wisdomNumber) {
    if (BartenderSchoolConfig.DEBUG_UNLOCK_ALL) return true;
    final wisdomId = 'wisdom_$wisdomNumber';
    return _progress.purchasedWisdom.contains(wisdomId);
  }

  /// Price of a wisdom fragment in coins.
  int getWisdomPrice(int wisdomNumber) {
    return BartenderSchoolConfig.wisdomPrices[wisdomNumber] ?? 999;
  }

  /// Whether the user can afford a wisdom fragment.
  bool canAffordWisdom(int wisdomNumber) {
    return _progress.coins >= getWisdomPrice(wisdomNumber);
  }

  /// Purchase a wisdom fragment. Returns true if successful.
  bool purchaseWisdom(int wisdomNumber) {
    if (isWisdomPurchased(wisdomNumber)) return false;
    if (!isWisdomAvailable(wisdomNumber)) return false;
    if (!canAffordWisdom(wisdomNumber)) return false;

    final price = getWisdomPrice(wisdomNumber);
    _progress.coins -= price;
    _progress.purchasedWisdom.add('wisdom_$wisdomNumber');
    _saveProgress();
    notifyListeners();
    return true;
  }

  // ── Coin Economy (Монеты — заработок и трата) ───────────────────────────

  /// Earn coins (add to balance).
  void earnCoins(int amount) {
    if (amount <= 0) return;
    _progress.coins += amount;
    _saveProgress();
    notifyListeners();
  }

  /// Migration: if user has totalXP but no coins, give them coins = totalXP.
  /// Called once on first load after update.
  void _migrateCoinsBalance() {
    if (_progress.totalXP > 0 && _progress.coins == 0) {
      _progress.coins = _progress.totalXP;
      _saveProgress();
    }
  }

  // ── Block Rewards (Награды за блоки) ───────────────────────────────────────

  /// Проверить, завершён ли весь блок (все уроки блока пройдены).
  bool isBlockCompleted(String blockId) {
    if (_lessonRepo == null) return false;
    final blockLessons =
        _lessonRepo.lessons.where((l) => l.blockId == blockId).toList();
    if (blockLessons.isEmpty) return false;
    return blockLessons.every(
      (l) => getLessonStatus(l.id) == LessonStatus.completed,
    );
  }

  /// Получить список наград за блоки, которые ещё не были получены.
  /// Проверяет все блоки Level 1 (A, B, C).
  List<BlockReward> getNewlyCompletedBlockRewards() {
    final newRewards = <BlockReward>[];
    for (final blockId in ['A', 'B', 'C']) {
      if (isBlockCompleted(blockId) && !hasClaimedBlockReward(blockId)) {
        final reward = getBlockReward(blockId);
        if (reward != null) newRewards.add(reward);
      }
    }
    return newRewards;
  }

  /// Получить текущий ранг студента на основе завершённых блоков.
  /// Возвращает null если ни один блок не завершён.
  ({String title, String emoji})? get currentRank {
    if (isBlockCompleted('C')) return (title: 'Миксолог', emoji: '🎓');
    if (isBlockCompleted('B')) return (title: 'Бармен', emoji: '🍸');
    if (isBlockCompleted('A')) return (title: 'Стажёр', emoji: '🍃');
    return null;
  }

  /// Claim (отметить как полученную) награду за блок.
  /// Начисляет бонусный XP и монеты, сохраняет флаг.
  void claimBlockReward(String blockId) {
    final reward = getBlockReward(blockId);
    if (reward == null) return;
    if (hasClaimedBlockReward(blockId)) return;

    // Начисляем бонусный XP (для ранга)
    _progress.totalXP += reward.bonusXp;

    // Начисляем бонусные монеты (для траты на мудрость)
    _progress.coins += reward.bonusCoins;

    // Сохраняем флаг получения
    _prefs.setBool('block_reward_claimed_$blockId', true);
    _saveProgress();
    notifyListeners();
  }

  /// Проверить, была ли уже получена награда за блок.
  bool hasClaimedBlockReward(String blockId) {
    return _prefs.getBool('block_reward_claimed_$blockId') ?? false;
  }

  /// Loads progress from SharedPreferences.
  void _loadProgress() {
    final jsonString = _prefs.getString('bartender_school_progress');
    if (jsonString != null) {
      try {
        final progressJson = SchoolProgress.fromJson(
          Map<String, dynamic>.from(
            json.decode(jsonString) as Map,
          ),
        );
        _progress = progressJson;
      } catch (e) {
        print('Error loading progress: $e');
        _progress = SchoolProgress.empty();
      }
    }
  }

  /// Saves progress to SharedPreferences.
  Future<void> _saveProgress() async {
    try {
      final jsonString = json.encode(_progress.toJson());
      await _prefs.setString('bartender_school_progress', jsonString);
    } catch (e) {
      print('Error saving progress: $e');
    }
  }

  /// Completes a lesson and updates progress.
  void completeLesson(String lessonId, {int score = 100, int xpEarned = 50}) {
    final wasCompleted =
        _progress.lessonStatuses[lessonId] == LessonStatus.completed;

    _progress.lessonStatuses[lessonId] = LessonStatus.completed;
    if (!wasCompleted) {
      _progress.totalXP += xpEarned;
    }

    // Update streak
    _updateStreak();

    // Unlock next lesson if applicable
    _unlockNextLesson(lessonId);

    // Unlock cocktail if lesson has diplomaCocktailId
    _unlockLessonCocktail(lessonId);

    _saveProgress();
    notifyListeners();
  }

  /// Marks a lesson as in progress.
  void startLesson(String lessonId) {
    if (getLessonStatus(lessonId) == LessonStatus.available) {
      _progress.lessonStatuses[lessonId] = LessonStatus.inProgress;
      _saveProgress();
      notifyListeners();
    }
  }

  /// Checks if a lesson is unlocked based on prerequisites.
  bool isLessonUnlocked(String lessonId, String? unlockCondition) {
    // Debug mode: unlock all lessons
    if (BartenderSchoolConfig.DEBUG_UNLOCK_ALL) return true;

    // If no unlock condition, always available
    if (unlockCondition == null) return true;

    // Level 2 starts only after the honest Level 1 diploma requirements:
    // all theory plus Mojito, Daiquiri and Negroni at 2+ stars.
    if (lessonId == 'lesson_D_13' && _lessonRepo != null) {
      return isSchoolCompleted(lessonRepo: _lessonRepo);
    }

    // Check if the required lesson is completed
    final requiredStatus = _progress.lessonStatuses[unlockCondition];
    // If prerequisite is missing, keep the dependent lesson locked.
    return requiredStatus == LessonStatus.completed;
  }

  /// Gets the status of a lesson.
  LessonStatus getLessonStatus(String lessonId) {
    return _progress.lessonStatuses[lessonId] ?? LessonStatus.available;
  }

  /// Sets initial lesson statuses (called when first loading level).
  void initializeLessons(List<String> lessonIds) {
    for (final lessonId in lessonIds) {
      if (!_progress.lessonStatuses.containsKey(lessonId)) {
        _progress.lessonStatuses[lessonId] = LessonStatus.available;
      }
    }
    _saveProgress();
    notifyListeners();
  }

  /// Updates streak based on last study date.
  void _updateStreak() {
    final now = DateTime.now();
    final lastDate = _progress.lastStudyDate;

    if (lastDate == null) {
      // First time studying
      _progress.streak = 1;
    } else {
      final difference = now.difference(lastDate).inDays;
      if (difference == 0) {
        // Same day, don't increment
      } else if (difference == 1) {
        // Consecutive day
        _progress.streak++;
      } else {
        // Streak broken
        _progress.streak = 1;
      }
    }

    _progress.lastStudyDate = now;
  }

  /// Unlocks the next lesson after completing current one.
  void _unlockNextLesson(String completedLessonId) {
    // This is handled by the lesson repository's unlock conditions
    // Here we just mark lessons as available based on their prerequisites
  }

  /// Unlocks cocktail associated with a lesson (diplomaCocktailId).
  void _unlockLessonCocktail(String lessonId) {
    if (_lessonRepo == null) return;

    final lesson = _lessonRepo.getLesson(lessonId);
    if (lesson?.diplomaCocktailId != null) {
      unlockCocktail(lesson!.diplomaCocktailId!);
      print('🍸 Cocktail unlocked: ${lesson.diplomaCocktailId}');
    }
  }

  /// Adds XP to the student's total.
  void addXP(int amount) {
    _progress.totalXP += amount;
    _saveProgress();
    notifyListeners();
  }

  /// Checks if an achievement is unlocked.
  bool hasAchievement(String achievementId) {
    return _progress.achievements.contains(achievementId);
  }

  /// Unlocks an achievement.
  ///
  /// Возвращает `true`, только если достижение открыто впервые: экран
  /// награды должен показываться один раз, а не на каждом идеальном квизе.
  bool unlockAchievement(String achievementId) {
    if (_progress.achievements.contains(achievementId)) return false;
    _progress.achievements.add(achievementId);
    _saveProgress();
    notifyListeners();
    return true;
  }

  /// Gets all unlocked cocktail IDs.
  List<String> get unlockedCocktails =>
      List.unmodifiable(_progress.unlockedCocktails);

  /// Unlocks a cocktail.
  void unlockCocktail(String cocktailId) {
    if (!_progress.unlockedCocktails.contains(cocktailId)) {
      _progress.unlockedCocktails.add(cocktailId);
      _saveProgress();
      notifyListeners();
    }
  }

  /// Resets all progress (for testing).
  Future<void> resetProgress() async {
    _progress = SchoolProgress.empty();
    await _prefs.remove('bartender_school_progress');
    notifyListeners();
  }

  // ── Quiz failures ────────────────────────────────────────────────────────

  /// Сколько раз квиз этого урока был провален.
  ///
  /// Нужно не для наказания: по счётчику Джон на второй и третий раз
  /// говорит по-другому, а не повторяет ту же фразу.
  int getQuizFailures(String lessonId) {
    return _prefs.getInt('quiz_failures_$lessonId') ?? 0;
  }

  /// Запоминает ещё один провал и возвращает новое число.
  int registerQuizFailure(String lessonId) {
    final next = getQuizFailures(lessonId) + 1;
    _prefs.setInt('quiz_failures_$lessonId', next);
    return next;
  }

  /// Квиз сдан — счётчик провалов больше не нужен.
  Future<void> resetQuizFailures(String lessonId) async {
    await _prefs.remove('quiz_failures_$lessonId');
  }

  // ── Daily Cocktail Tracking ──────────────────────────────────────────────

  /// Check if user marked a cocktail as "I made this"
  bool isCocktailMade(String cocktailName) {
    return _prefs.getBool('cocktail_made_$cocktailName') ?? false;
  }

  /// Mark a cocktail as "I made this" (+10 XP bonus)
  void markCocktailMade(String cocktailName) {
    final key = 'cocktail_made_$cocktailName';
    if (_prefs.getBool(key) == true) return; // already marked
    _prefs.setBool(key, true);
    _progress.totalXP += 10;
    _updateStreak();
    _saveProgress();
    notifyListeners();
  }

  /// Get user's rating for a cocktail (0 = not rated)
  int getCocktailRating(String cocktailName) {
    return _prefs.getInt('cocktail_rating_$cocktailName') ?? 0;
  }

  /// Set user's rating for a cocktail (1-5 stars)
  void setCocktailRating(String cocktailName, int rating) {
    _prefs.setInt('cocktail_rating_$cocktailName', rating.clamp(0, 5));
    _saveProgress();
    notifyListeners();
  }

  // ── Workshop Mission Tracking ─────────────────────────────────────────────

  /// How many times a mission cocktail has been built in the workshop.
  int getWorkshopMissionCount(String missionId) {
    return _prefs.getInt('workshop_mission_${missionId}_count') ?? 0;
  }

  /// Increment the build count for a workshop mission.
  void incrementWorkshopMission(String missionId) {
    final key = 'workshop_mission_${missionId}_count';
    final current = _prefs.getInt(key) ?? 0;
    _prefs.setInt(key, current + 1);
    notifyListeners();
  }

  /// Whether a mission has reached its target build count.
  bool isWorkshopMissionComplete(String missionId, {int targetCount = 3}) {
    return getWorkshopMissionCount(missionId) >= targetCount;
  }

  /// Total practice XP earned in the workshop.
  int get workshopPracticeXp => _prefs.getInt('workshop_practice_xp') ?? 0;

  /// Award practice XP for a workshop build.
  void addWorkshopXp(int amount) {
    final current = workshopPracticeXp;
    _prefs.setInt('workshop_practice_xp', current + amount);
    notifyListeners();
  }

  /// Practice level title based on total practice XP.
  String get workshopPracticeLevel {
    final xp = workshopPracticeXp;
    if (xp >= 300) return 'Миксолог';
    if (xp >= 150) return 'Бармен';
    if (xp >= 50) return 'Стажёр';
    return 'Новичок';
  }

  /// XP threshold for the next practice level.
  int get workshopNextLevelXp {
    final xp = workshopPracticeXp;
    if (xp >= 300) return 300;
    if (xp >= 150) return 300;
    if (xp >= 50) return 150;
    return 50;
  }

  // ── Lesson Practice Tracking (Theory → Practice cycle) ─────────────────

  /// Mark a lesson's practice as completed in the workshop.
  /// Called when the student successfully builds the mission cocktail.
  void completeLessonPractice(String lessonId) {
    final key = 'lesson_practice_$lessonId';
    if (_prefs.getBool(key) == true) return; // already done
    _prefs.setBool(key, true);
    notifyListeners();
  }

  /// Whether a lesson's practice has been completed.
  bool isLessonPracticeComplete(String lessonId) {
    return _prefs.getBool('lesson_practice_$lessonId') ?? false;
  }

  /// Whether a lesson is FULLY complete: theory (quiz) + practice (workshop).
  /// A level is only done when ALL its lessons are fully complete.
  bool isLessonFullyComplete(String lessonId) {
    final theoryDone =
        _progress.lessonStatuses[lessonId] == LessonStatus.completed;
    final practiceDone = isLessonPracticeComplete(lessonId);
    return theoryDone && practiceDone;
  }

  /// How many lessons in a list have practice completed.
  int getPracticeCompleteCount(List<String> lessonIds) {
    return lessonIds.where((id) => isLessonPracticeComplete(id)).length;
  }

  /// Whether all lessons in a level are fully complete (theory + practice).
  bool isLevelFullyComplete(List<String> lessonIds) {
    if (lessonIds.isEmpty) return false;
    return lessonIds.every((id) => isLessonFullyComplete(id));
  }

  // ── Practice Challenge Stars (Workshop) ──────────────────────────────────

  /// Get best star rating for a practice challenge (0-3).
  int getPracticeStars(String challengeId) {
    return _prefs.getInt('practice_stars_$challengeId') ?? 0;
  }

  /// Get practice stars by cocktail name (convenience for Recipes tab).
  ///
  /// Один и тот же коктейль может встречаться в нескольких уровнях
  /// (`level1_margarita` и `level2_margarita`). Вкладки рецептов нет
  /// контекста уровня, поэтому берём ЛУЧШИЙ результат по всем заданиям
  /// с таким названием. Раньше бралось первое совпадение по списку,
  /// из-за чего прогресс «перетекал» между уровнями nondeterministically.
  int getPracticeStarsByCocktail(String cocktailName) {
    final needle = cocktailName.toLowerCase().trim();
    var best = 0;
    for (final c in allPracticeChallenges) {
      if (c.cocktailName.toLowerCase() != needle) continue;
      final s = getPracticeStars(c.id);
      if (s > best) best = s;
    }
    return best;
  }

  /// Save practice result — keeps the best star rating.
  void savePracticeResult(String challengeId, int stars) {
    final current = getPracticeStars(challengeId);
    if (stars > current) {
      _prefs.setInt('practice_stars_$challengeId', stars);
      notifyListeners();
    }
  }

  /// Records one finished workshop attempt exactly once.
  ///
  /// XP is awarded only for newly earned stars and for the first time bonus,
  /// so widget rebuilds and identical retries cannot farm XP.
  PracticeAttemptAward recordPracticeAttempt({
    required PracticeChallenge challenge,
    required int stars,
    required bool timeBonusEarned,
  }) {
    final normalizedStars = stars < 0 ? 0 : (stars > 3 ? 3 : stars);
    final previousStars = getPracticeStars(challenge.id);
    final improvedStars =
        normalizedStars > previousStars ? normalizedStars - previousStars : 0;

    if (normalizedStars > previousStars) {
      _prefs.setInt('practice_stars_${challenge.id}', normalizedStars);
    }

    final timeBonusAwarded = timeBonusEarned && !hasTimeBonus();
    if (timeBonusAwarded) {
      _prefs.setBool('workshop_time_bonus', true);
    }

    final xpEarned = improvedStars * 10 + (timeBonusAwarded ? 10 : 0);
    if (xpEarned > 0) {
      _prefs.setInt('workshop_practice_xp', workshopPracticeXp + xpEarned);
    }

    // Начисляем монеты за практику: 25 монет за каждую новую звезду
    final coinsEarned =
        improvedStars * BartenderSchoolConfig.coinsPerPracticeStar;
    if (coinsEarned > 0) {
      _progress.coins += coinsEarned;
    }

    if (normalizedStars >= 2) {
      _prefs.setBool('lesson_practice_${challenge.lessonId}', true);
      if (!_progress.unlockedCocktails.contains(challenge.cocktailName)) {
        _progress.unlockedCocktails.add(challenge.cocktailName);
      }
    }

    _saveProgress();
    checkAndAwardBadges();
    notifyListeners();

    return PracticeAttemptAward(
      xpEarned: xpEarned,
      coinsEarned: coinsEarned,
      improvedStars: improvedStars,
      timeBonusAwarded: timeBonusAwarded,
    );
  }

  // ── Time Bonus Tracking ─────────────────────────────────────────────────

  /// Mark that user earned a time bonus (for badge checking).
  void saveTimeBonus() {
    if (_prefs.getBool('workshop_time_bonus') == true) return;
    _prefs.setBool('workshop_time_bonus', true);
  }

  bool hasTimeBonus() => _prefs.getBool('workshop_time_bonus') ?? false;

  // ── Badge Checking ─────────────────────────────────────────────────────

  /// Build badge context from current progress state.
  BadgeContext _buildBadgeContext() {
    final stars = <String, int>{};
    for (final c in allPracticeChallenges) {
      stars[c.id] = getPracticeStars(c.id);
    }
    return BadgeContext(
      challengeStars: stars,
      streak: _progress.streak,
      hasTimeBonus: hasTimeBonus(),
    );
  }

  /// Check all badges, award newly earned ones.
  /// Returns list of newly unlocked badge IDs.
  List<String> checkAndAwardBadges() {
    final ctx = _buildBadgeContext();
    final newlyUnlocked = <String>[];
    for (final badge in workshopBadges) {
      if (!_progress.achievements.contains(badge.id) && badge.check(ctx)) {
        _progress.achievements.add(badge.id);
        newlyUnlocked.add(badge.id);
      }
    }
    if (newlyUnlocked.isNotEmpty) {
      _saveProgress();
      notifyListeners();
    }
    return newlyUnlocked;
  }

  /// Get list of unlocked badge IDs.
  List<String> getUnlockedBadgeIds() =>
      List.unmodifiable(_progress.achievements);

  // ── Term Learning Tracking ─────────────────────────────────────────────

  /// Mark a term as learned (student passed the term quiz for it).
  void markTermLearned(String termName) {
    final key = 'term_learned_$termName';
    if (_prefs.getBool(key) == true) return;
    _prefs.setBool(key, true);
    _prefs.setString(
        'term_learned_date_$termName', DateTime.now().toIso8601String());
    notifyListeners();
  }

  /// Whether a specific term has been learned.
  bool isTermLearned(String termName) {
    return _prefs.getBool('term_learned_$termName') ?? false;
  }

  /// When a term was learned (for spaced repetition).
  DateTime? getTermLearnedDate(String termName) {
    final dateStr = _prefs.getString('term_learned_date_$termName');
    if (dateStr == null) return null;
    return DateTime.tryParse(dateStr);
  }

  /// How many terms from a list have been learned.
  int getLearnedTermCount(List<String> termNames) {
    return termNames.where((name) => isTermLearned(name)).length;
  }

  /// Whether all terms for a lesson have been learned.
  bool areLessonTermsLearned(List<String> lessonTermNames) {
    if (lessonTermNames.isEmpty) return true;
    return lessonTermNames.every((name) => isTermLearned(name));
  }

  /// Get terms that need repetition (learned more than N days ago).
  /// Uses simplified spaced repetition: repeat after 1, 3, 7 days.
  List<String> getTermsToRepeat(List<String> allKnownTermNames) {
    final now = DateTime.now();
    final toRepeat = <String>[];

    for (final name in allKnownTermNames) {
      if (!isTermLearned(name)) continue;
      final learnedDate = getTermLearnedDate(name);
      if (learnedDate == null) continue;

      final daysSince = now.difference(learnedDate).inDays;
      // Simple schedule: repeat at 1, 3, 7 days
      if (daysSince == 1 || daysSince == 3 || daysSince == 7) {
        toRepeat.add(name);
      }
    }
    return toRepeat;
  }

  /// Total number of learned terms across all lessons.
  int get totalLearnedTerms {
    int count = 0;
    final keys = _prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('term_learned_') &&
          !key.startsWith('term_learned_date_') &&
          _prefs.getBool(key) == true) {
        count++;
      }
    }
    return count;
  }
}

class PracticeAttemptAward {
  final int xpEarned;
  final int coinsEarned;
  final int improvedStars;
  final bool timeBonusAwarded;

  const PracticeAttemptAward({
    required this.xpEarned,
    this.coinsEarned = 0,
    required this.improvedStars,
    required this.timeBonusAwarded,
  });
}
