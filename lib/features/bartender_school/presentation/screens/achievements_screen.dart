import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coin/core/theme/app_theme.dart';
import 'package:coin/features/bartender_school/data/progress_service.dart';
import 'package:coin/features/bartender_school/data/lesson_repository.dart';
import 'package:coin/features/bartender_school/domain/entities/progress.dart';
import 'package:coin/features/bartender_school/presentation/widgets/john_school_visuals.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const JohnThemedAppBar(
        room: JohnSchoolRoom.honorsHall,
        title: 'Зал наград',
      ),
      body: JohnRoomBackground(
        room: JohnSchoolRoom.honorsHall,
        child: Consumer2<ProgressService, LessonRepository>(
          builder: (context, progressService, lessonRepo, _) {
            final achievements =
                _getAllAchievements(progressService, lessonRepo);
            final unlockedCount =
                achievements.where((a) => a.isUnlocked).length;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProgressHeader(
                    unlocked: unlockedCount,
                    total: achievements.length,
                  ),
                  const SizedBox(height: 24),
                  _AchievementSection(
                    title: 'Level 1',
                    achievements: achievements
                        .where((a) => a.category == 'level')
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  _AchievementSection(
                    title: 'Коктейли',
                    achievements: achievements
                        .where((a) => a.category == 'cocktail')
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  _AchievementSection(
                    title: 'Серии',
                    achievements: achievements
                        .where((a) => a.category == 'streak')
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  _AchievementSection(
                    title: 'Особые',
                    achievements: achievements
                        .where((a) => a.category == 'special')
                        .toList(),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Achievement> _getAllAchievements(
      ProgressService progress, LessonRepository lessonRepo) {
    final completedLessons = progress.progress.lessonStatuses.values
        .where((s) => s == LessonStatus.completed)
        .length;
    final xp = progress.totalXP;
    final streak = progress.streak;

    return [
      // Level achievements
      Achievement(
        id: 'level_1_complete',
        title: 'Начинающий бармен',
        description: 'Завершить Level 1',
        icon: '🌱',
        category: 'level',
        isUnlocked: completedLessons >= 12,
        progress: completedLessons >= 12 ? 12 : 0,
        target: 12,
      ),
      // Cocktail achievements
      Achievement(
        id: 'cocktail_10',
        title: 'Десятка',
        description: 'Приготовить 10 коктейлей',
        icon: '🍹',
        category: 'cocktail',
        isUnlocked: xp >= 500,
        progress: xp >= 500 ? 10 : (xp ~/ 50),
        target: 10,
      ),
      // Streak achievements
      Achievement(
        id: 'streak_3',
        title: 'Три дня',
        description: 'Учиться 3 дня подряд',
        icon: '🔥',
        category: 'streak',
        isUnlocked: streak >= 3,
        progress: streak >= 3 ? 3 : streak,
        target: 3,
      ),
      Achievement(
        id: 'streak_7',
        title: 'Неделя',
        description: 'Учиться 7 дней подряд',
        icon: '💪',
        category: 'streak',
        isUnlocked: streak >= 7,
        progress: streak >= 7 ? 7 : streak,
        target: 7,
      ),
      Achievement(
        id: 'streak_30',
        title: 'Месяц',
        description: 'Учиться 30 дней подряд',
        icon: '👑',
        category: 'streak',
        isUnlocked: streak >= 30,
        progress: streak >= 30 ? 30 : streak,
        target: 30,
      ),
      // Special achievements
      Achievement(
        id: 'first_lesson',
        title: 'Первый шаг',
        description: 'Пройти первый урок',
        icon: '🎯',
        category: 'special',
        isUnlocked: completedLessons >= 1,
        progress: completedLessons >= 1 ? 1 : 0,
        target: 1,
      ),
      Achievement(
        id: 'perfect_quiz',
        title: 'Перфекционист',
        description: 'Пройти квиз на 100%',
        icon: '💯',
        category: 'special',
        isUnlocked: progress.hasAchievement('perfect_quiz'),
        progress: progress.hasAchievement('perfect_quiz') ? 1 : 0,
        target: 1,
      ),
      Achievement(
        id: 'all_terms',
        title: 'Эрудит',
        description: 'Изучить все термины',
        icon: '📚',
        category: 'special',
        isUnlocked: progress.hasAchievement('all_terms'),
        progress: progress.hasAchievement('all_terms') ? 1 : 0,
        target: 1,
      ),
    ];
  }
}

class _ProgressHeader extends StatelessWidget {
  final int unlocked;
  final int total;

  const _ProgressHeader({required this.unlocked, required this.total});

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? unlocked / total : 0.0;

    return JohnWoodPanel(
      room: JohnSchoolRoom.honorsHall,
      highlighted: true,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(80),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Center(
              child: Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Твои достижения',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$unlocked из $total разблокировано',
                  style: TextStyle(
                    color: AppColors.textSecondary.withAlpha(180),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.surfaceLight,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementSection extends StatelessWidget {
  final String title;
  final List<Achievement> achievements;

  const _AchievementSection({required this.title, required this.achievements});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFFD4A84E),
            fontFamily: 'serif',
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        ...achievements.map((a) => _AchievementCard(achievement: a)),
      ],
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;

  const _AchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final iconAsset = switch (achievement.category) {
      'level' => 'images/ui_icon_term_medal.png',
      'cocktail' => 'images/ui_icon_practice_motion.png',
      'streak' => 'images/ui_icon_tip_citrus.png',
      _ => 'images/ui_icon_checklist.png',
    };
    return JohnWoodPanel(
      room: JohnSchoolRoom.honorsHall,
      highlighted: achievement.isUnlocked,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: achievement.isUnlocked
                  ? AppColors.primary.withAlpha(30)
                  : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: achievement.isUnlocked
                  ? Image.asset(iconAsset)
                  : const Icon(
                      Icons.lock_rounded,
                      color: Color(0xFFAA9980),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      achievement.title,
                      style: TextStyle(
                        color: achievement.isUnlocked
                            ? const Color(0xFFFFE9BF)
                            : AppColors.textSecondary,
                        fontSize: 15,
                        fontFamily: 'serif',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (achievement.isUnlocked) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 16,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  achievement.description,
                  style: TextStyle(
                    color: achievement.isUnlocked
                        ? AppColors.textSecondary
                        : AppColors.textSecondary.withAlpha(150),
                    fontSize: 12,
                  ),
                ),
                if (!achievement.isUnlocked && achievement.target > 1) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: achievement.progress / achievement.target,
                            backgroundColor: AppColors.surfaceLight,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.textSecondary.withAlpha(100),
                            ),
                            minHeight: 4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${achievement.progress}/${achievement.target}',
                        style: TextStyle(
                          color: AppColors.textSecondary.withAlpha(150),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final String category;
  final bool isUnlocked;
  final int progress;
  final int target;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    required this.isUnlocked,
    required this.progress,
    required this.target,
  });
}
