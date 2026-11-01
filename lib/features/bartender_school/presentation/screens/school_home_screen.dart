import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:coin/core/theme/app_theme.dart';
import 'package:coin/features/bartender_school/data/lesson_repository.dart';
import 'package:coin/features/bartender_school/data/progress_service.dart';
import 'package:coin/features/bartender_school/domain/entities/progress.dart';
import 'package:coin/features/bartender_school/presentation/screens/level1_screen.dart';
import 'package:coin/features/bartender_school/presentation/screens/glossary_screen.dart';
import 'package:coin/features/bartender_school/presentation/screens/achievements_screen.dart';
import 'package:coin/features/bartender_school/presentation/screens/certificates_screen.dart';
import 'package:coin/features/bartender_school/presentation/screens/wisdom_vault_screen.dart';
import 'package:coin/features/cocktail_list/view/cocktail_list_screen.dart';

/// Ссылка на полное приложение школы барменов (заглушка)
const String _fullSchoolAppUrl =
    'https://play.google.com/store/apps/details?id=com.johnrocksh.bartender_school_full';

Future<void> _openFullSchoolApp() async {
  final uri = Uri.parse(_fullSchoolAppUrl);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class SchoolHomeScreen extends StatelessWidget {
  const SchoolHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SchoolHeader(topPad: topPad),
            _UserStats(),
            _LevelCardsSection(),
            _QuickAccessSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class SchoolHomeScreenWithBack extends StatelessWidget {
  const SchoolHomeScreenWithBack({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Bartender School'),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const SchoolHomeScreen(),
    );
  }
}

class _SchoolHeader extends StatelessWidget {
  final double topPad;

  const _SchoolHeader({required this.topPad});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, topPad + 16, 24, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface,
            AppColors.surface.withAlpha(200),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppColors.primary.withAlpha(30),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(80),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🎓', style: TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'BARTENDER SCHOOL',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Путь от новичка до Миксолога',
                      style: TextStyle(
                        color: AppColors.textSecondary.withAlpha(180),
                        fontSize: 12,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserStats extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ProgressService>(
      builder: (context, progressService, _) {
        final lessonRepo = context.watch<LessonRepository>();
        final coreLessons = lessonRepo.lessons
            .where((lesson) => const ['A', 'B', 'C'].contains(lesson.blockId))
            .toList();
        final totalLessons = coreLessons.length;
        final completedLessons = progressService.progress.lessonStatuses.entries
            .where((entry) =>
                coreLessons.any((lesson) => lesson.id == entry.key) &&
                entry.value == LessonStatus.completed)
            .length;
        final progress =
            totalLessons > 0 ? completedLessons / totalLessons : 0.0;

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StatItem(
                      icon: null,
                      customIconPath: 'images/ui_icon_term_medal.png',
                      iconColor: AppColors.primary,
                      label: 'XP',
                      value: '${progressService.totalXP}',
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: AppColors.border,
                  ),
                  Expanded(
                    child: _StatItem(
                      icon: null,
                      customIconPath: 'images/ui_icon_practice_motion.png',
                      iconColor: Colors.orange,
                      label: 'Streak',
                      value: '${progressService.streak}',
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: AppColors.border,
                  ),
                  Expanded(
                    child: _StatItem(
                      icon: null,
                      customIconPath: 'images/ui_icon_book_theory.png',
                      iconColor: AppColors.accent,
                      label: 'Уроков',
                      value: '$completedLessons/$totalLessons',
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: AppColors.border,
                  ),
                  Expanded(
                    child: _StatItem(
                      icon: Icons.attach_money,
                      iconColor: const Color(0xFFD4AF37),
                      label: 'Монет',
                      value: '${progressService.coins}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.surfaceLight,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress >= 1.0 ? AppColors.success : AppColors.primary,
                  ),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                progress >= 1.0
                    ? '🎉 Все уроки пройдены!'
                    : '${(progress * 100).toInt()}% завершено',
                style: TextStyle(
                  color: progress >= 1.0
                      ? AppColors.success
                      : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData? icon;
  final String? customIconPath;
  final Color iconColor;
  final String label;
  final String value;

  const _StatItem({
    this.icon,
    this.customIconPath,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (customIconPath != null)
          Image.asset(
            customIconPath!,
            width: 22,
            height: 22,
            fit: BoxFit.contain,
          )
        else
          Icon(icon, color: iconColor, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary.withAlpha(180),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _LevelCardsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'КУРС',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        _LevelCard(
          level: 1,
          title: 'Базовый курс',
          subtitle: 'Основы вкуса и баланса',
          lessonsCount: 12,
          blockIds: const ['A', 'B', 'C'],
          icon: '🌱',
          gradientColors: [Colors.green.shade600, Colors.green.shade800],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const Level1Screen()),
          ),
        ),
        const SizedBox(height: 16),
        // Карточка перехода в полное приложение
        GestureDetector(
          onTap: _openFullSchoolApp,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.open_in_new_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Полная версия',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Полная профессиональная школа бармана',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LevelCard extends StatelessWidget {
  final int level;
  final String title;
  final String subtitle;
  final int lessonsCount;
  final List<String> blockIds;
  final String icon;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _LevelCard({
    required this.level,
    required this.title,
    required this.subtitle,
    required this.lessonsCount,
    required this.blockIds,
    required this.icon,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ProgressService>(
      builder: (context, progressService, _) {
        final lessonRepo = context.read<LessonRepository>();
        final levelLessonIds = blockIds
            .expand((b) => lessonRepo.lessons
                .where((l) => l.blockId == b)
                .map((l) => l.id))
            .toList();

        // Theory progress: lessons with quiz completed
        final theoryCompleted = levelLessonIds
            .where((id) =>
                progressService.getLessonStatus(id) == LessonStatus.completed)
            .length;

        // Practice progress: lessons with workshop practice completed
        final practiceCompleted =
            progressService.getPracticeCompleteCount(levelLessonIds);

        // Fully complete: both theory AND practice done
        final fullyCompleted = levelLessonIds
            .where((id) => progressService.isLessonFullyComplete(id))
            .length;

        final progress = levelLessonIds.isNotEmpty
            ? fullyCompleted / levelLessonIds.length
            : 0.0;
        final isUnlocked = level == 1 || theoryCompleted > 0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GestureDetector(
            onTap: isUnlocked ? onTap : null,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isUnlocked
                      ? gradientColors
                      : [AppColors.surface, AppColors.surfaceLight],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: isUnlocked
                    ? [
                        BoxShadow(
                          color: gradientColors.first.withAlpha(60),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                children: [
                  if (!isUnlocked)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(100),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.lock_rounded,
                            color: AppColors.textSecondary,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(30),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(icon,
                                style: const TextStyle(fontSize: 28)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(30),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'LEVEL $level',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (progress >= 1.0)
                                    const Text(
                                      '✓',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                title,
                                style: TextStyle(
                                  color: isUnlocked
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              // Show theory/practice breakdown
                              if (theoryCompleted > 0 || practiceCompleted > 0)
                                Text(
                                  '📖 $theoryCompleted ✓  🍸 $practiceCompleted ✓',
                                  style: TextStyle(
                                    color: isUnlocked
                                        ? Colors.white.withAlpha(180)
                                        : AppColors.textSecondary
                                            .withAlpha(150),
                                    fontSize: 11,
                                  ),
                                )
                              else
                                Text(
                                  subtitle,
                                  style: TextStyle(
                                    color: isUnlocked
                                        ? Colors.white.withAlpha(200)
                                        : AppColors.textSecondary
                                            .withAlpha(150),
                                    fontSize: 12,
                                  ),
                                ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        backgroundColor:
                                            Colors.white.withAlpha(50),
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                        minHeight: 4,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$fullyCompleted/$lessonsCount',
                                    style: TextStyle(
                                      color: isUnlocked
                                          ? Colors.white.withAlpha(200)
                                          : AppColors.textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: isUnlocked
                              ? Colors.white.withAlpha(180)
                              : AppColors.textSecondary,
                          size: 28,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _QuickAccessSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'СПРАВОЧНИК',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _QuickAccessCard(
                  customIconPath: 'images/ui_icon_book_theory.png',
                  title: 'Термины',
                  subtitle: 'Словарь бармена',
                  color: AppColors.accent,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GlossaryScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickAccessCard(
                  icon: Icons.auto_awesome_rounded,
                  title: 'Рецепты',
                  subtitle: '50+ классических',
                  color: AppColors.primary,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CocktailListScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Consumer2<ProgressService, LessonRepository>(
            builder: (context, progressService, lessonRepo, _) {
              final wisdomLessons = lessonRepo.getWisdomLessons();
              final unlockedWisdom = wisdomLessons.where((lesson) {
                return progressService.isLessonUnlocked(
                  lesson.id,
                  lesson.unlockCondition,
                );
              }).length;

              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const WisdomVaultScreen(),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFFF8EAC8),
                        const Color(0xFFF1DCAB),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFF9D6B2C).withAlpha(42)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(20),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: const Color(0xFF9D6B2C).withAlpha(14),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: const Color(0xFF9D6B2C).withAlpha(28),
                          ),
                        ),
                        child: Image.asset(
                          'images/wisdom_chest.jpg',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Сундук мудрости',
                              style: TextStyle(
                                color: Color(0xFF3C2718),
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Открыто $unlockedWisdom из ${wisdomLessons.length} фрагментов мудрости',
                              style: TextStyle(
                                color: Color(0xFF5A3C27).withAlpha(190),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '›',
                        style: TextStyle(
                          color: const Color(0xFF9D6B2C),
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        _AwardsSection(),
      ],
    );
  }
}

class _AwardsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.purple,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'ДОСТИЖЕНИЯ',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _AwardCard(
                  customIconPath: 'images/ui_icon_term_medal.png',
                  title: 'Награды',
                  subtitle: '12 достижений',
                  color: Colors.amber,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AchievementsScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Consumer2<ProgressService, LessonRepository>(
                  builder: (context, progress, lessonRepo, _) {
                    final level1Complete =
                        _isLevelComplete(progress, lessonRepo, ['A', 'B', 'C']);
                    final earned = level1Complete ? 1 : 0;
                    final label = earned == 1
                        ? '1 диплом'
                        : earned == 0
                            ? 'Нет дипломов'
                            : '$earned диплома';
                    return _AwardCard(
                      customIconPath: 'images/ui_icon_checklist.png',
                      title: 'Дипломы',
                      subtitle: label,
                      color: AppColors.primary,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CertificatesScreen()),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

bool _isLevelComplete(ProgressService progress, LessonRepository lessonRepo,
    List<String> blockIds) {
  for (final blockId in blockIds) {
    for (final lesson
        in lessonRepo.lessons.where((l) => l.blockId == blockId)) {
      if (progress.getLessonStatus(lesson.id) != LessonStatus.completed) {
        return false;
      }
    }
  }
  return true;
}

class _AwardCard extends StatelessWidget {
  final String? customIconPath;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _AwardCard({
    this.customIconPath,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withAlpha(30),
              color.withAlpha(15),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withAlpha(40),
                borderRadius: BorderRadius.circular(10),
              ),
              child: customIconPath != null
                  ? Image.asset(customIconPath!, width: 22, height: 22)
                  : const SizedBox.shrink(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.textSecondary.withAlpha(180),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary.withAlpha(100),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  final IconData? icon;
  final String? customIconPath;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickAccessCard({
    this.icon,
    this.customIconPath,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: customIconPath != null
                  ? Image.asset(customIconPath!, width: 22, height: 22)
                  : Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: AppColors.textSecondary.withAlpha(180),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
