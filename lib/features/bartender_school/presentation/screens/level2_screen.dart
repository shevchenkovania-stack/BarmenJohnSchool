import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coin/core/theme/app_theme.dart';
import 'package:coin/features/bartender_school/data/lesson_repository.dart';
import 'package:coin/features/bartender_school/data/progress_service.dart';
import 'package:coin/features/bartender_school/domain/entities/lesson.dart';
import 'package:coin/features/bartender_school/domain/entities/progress.dart';
import 'package:coin/features/bartender_school/presentation/widgets/lesson_card.dart';
import 'package:coin/features/bartender_school/presentation/screens/flip_card_screen.dart';

class Level2Screen extends StatelessWidget {
  const Level2Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Уровень 2'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          Consumer<ProgressService>(
            builder: (context, progressService, _) {
              return Container(
                margin: const EdgeInsets.only(right: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'images/ui_icon_term_medal.png',
                      width: 16,
                      height: 16,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${progressService.totalXP} XP',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<LessonRepository>(
        builder: (context, lessonRepo, _) {
          if (lessonRepo.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text('Загружаю уроки...'),
                ],
              ),
            );
          }

          final lessons = lessonRepo.lessons
              .where((l) => const ['D', 'E', 'F'].contains(l.blockId))
              .toList();

          if (lessons.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Уроки Level 2 не найдены'),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final block in const [
                  (
                    'D',
                    '🧭',
                    'Контроль техники',
                    'Спецификация, замены, текстура и лёд'
                  ),
                  (
                    'E',
                    '🍸',
                    'Четыре классики',
                    'Whiskey Sour, Old Fashioned, Dry Martini, Margarita'
                  ),
                  (
                    'F',
                    '⚡',
                    'Профессиональная смена',
                    'Prep, безопасность, гость, запара и экзамен'
                  ),
                ]) ...[
                  _Level2BlockHeader(
                    blockId: block.$1,
                    emoji: block.$2,
                    title: block.$3,
                    subtitle: block.$4,
                  ),
                  const SizedBox(height: 16),
                  _LessonGrid(
                    lessons: lessons
                        .where((lesson) => lesson.blockId == block.$1)
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                ],
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Level2BlockHeader extends StatelessWidget {
  final String blockId;
  final String emoji;
  final String title;
  final String subtitle;

  const _Level2BlockHeader({
    required this.blockId,
    required this.emoji,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withAlpha(30), Colors.transparent],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withAlpha(50)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Блок $blockId: $title',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.textSecondary.withAlpha(180),
                    fontSize: 12,
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

class _LessonGrid extends StatelessWidget {
  final List<Lesson> lessons;

  const _LessonGrid({required this.lessons});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProgressService>(
      builder: (context, progressService, _) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: lessons.length,
          itemBuilder: (context, index) {
            final lesson = lessons[index];
            final status = _getLessonStatus(lesson, progressService);

            return LessonCard(
              lesson: lesson,
              status: status,
              practiceComplete:
                  progressService.isLessonPracticeComplete(lesson.id),
              termsLearned: progressService.getLearnedTermCount(lesson.terms),
              onTap: () => _onLessonTap(context, lesson, status),
            );
          },
        );
      },
    );
  }

  LessonStatus _getLessonStatus(
      Lesson lesson, ProgressService progressService) {
    final savedStatus = progressService.getLessonStatus(lesson.id);

    if (savedStatus == LessonStatus.completed) {
      return LessonStatus.completed;
    }

    final isUnlocked = progressService.isLessonUnlocked(
      lesson.id,
      lesson.unlockCondition,
    );

    return isUnlocked ? LessonStatus.available : LessonStatus.locked;
  }

  void _onLessonTap(BuildContext context, Lesson lesson, LessonStatus status) {
    if (status == LessonStatus.locked) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FlipCardScreen(lesson: lesson),
      ),
    );
  }
}
