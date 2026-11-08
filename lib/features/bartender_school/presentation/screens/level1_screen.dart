import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coin/core/theme/app_theme.dart';
import 'package:coin/features/bartender_school/data/lesson_repository.dart';
import 'package:coin/features/bartender_school/data/progress_service.dart';
import 'package:coin/features/bartender_school/domain/entities/lesson.dart';
import 'package:coin/features/bartender_school/domain/entities/progress.dart';
import 'package:coin/features/bartender_school/presentation/widgets/lesson_card.dart';
import 'package:coin/features/bartender_school/presentation/widgets/block_header.dart';
import 'package:coin/features/bartender_school/presentation/screens/flip_card_screen.dart';
import 'package:coin/features/bartender_school/presentation/screens/mission_briefing_screen.dart';
import 'package:coin/features/bartender_school/presentation/widgets/john_prologue_dialog.dart';
import 'package:coin/features/bartender_school/presentation/widgets/john_school_visuals.dart';

/// Block intro narrative data.
class _BlockIntroData {
  final String title;
  final String text;
  final String assetPath;

  const _BlockIntroData({
    required this.title,
    required this.text,
    required this.assetPath,
  });
}

const Map<String, _BlockIntroData> _blockIntroData = {
  'A': _BlockIntroData(
    title: 'Глава A: пробуждение вкуса',
    text:
        'Прежде чем смешивать коктейли, ты учишься чувствовать. Язык — первый инструмент бармена: кислота, сладость, горечь, соль и тело напитка. Четыре урока — и ты начнёшь слышать вкус.',
    assetPath: 'images/barista_john_teach.png',
  ),
  'B': _BlockIntroData(
    title: 'Глава B: руки и инструменты',
    text:
        'Теперь вкус должен перейти в руки. Станция, джиггер, шейкер и лёд учат точности: 30 мл — это 30 мл, а shake — техника, а не суета. Пять уроков — и твои руки будут знать, что делать.',
    assetPath: 'images/barista_john_practice.png',
  ),
  'C': _BlockIntroData(
    title: 'Глава C: первые классики',
    text:
        'Всё, что ты узнал — вкус, баланс, инструменты — сейчас сходится в трёх коктейлях: Mojito, Daiquiri и Negroni. Каждый проверяет отдельный навык. А в конце — финальное испытание.',
    assetPath: 'images/barista_john_exam.png',
  ),
};

/// Level 1 screen showing all lesson cards in blocks.
class Level1Screen extends StatefulWidget {
  const Level1Screen({super.key});

  @override
  State<Level1Screen> createState() => _Level1ScreenState();
}

class _Level1ScreenState extends State<Level1Screen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final progressService =
          Provider.of<ProgressService>(context, listen: false);
      if (!progressService.hasSeenLevel1Prologue) {
        _showLevel1Prologue(progressService).then((_) {
          if (mounted) _checkAndShowBlockIntro(progressService);
        });
      } else {
        _checkAndShowBlockIntro(progressService);
      }
    });
  }

  /// Shows the first unseen block intro dialog, if any block is ready.
  void _checkAndShowBlockIntro(ProgressService progressService) {
    if (!mounted) return;
    final lessonRepo = Provider.of<LessonRepository>(context, listen: false);
    final lessons = lessonRepo.lessons;

    // Check blocks in order — show the first unseen one whose first lesson
    // is available (so the student is actually entering that block).
    for (final blockId in ['A', 'B', 'C']) {
      if (progressService.hasSeenBlockIntro(blockId)) continue;

      final firstLesson =
          lessons.where((l) => l.blockId == blockId).firstOrNull;
      if (firstLesson == null) continue;

      final isUnlocked = progressService.isLessonUnlocked(
        firstLesson.id,
        firstLesson.unlockCondition,
      );
      if (!isUnlocked) break; // Block not reached yet, stop checking

      _showBlockBriefing(blockId);
      return; // Show one at a time
    }
  }

  /// Navigate to full-screen mission briefing (StarCraft-style).
  void _showBlockBriefing(String blockId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MissionBriefingScreen(blockId: blockId),
      ),
    );
  }

  Future<void> _showLevel1Prologue(ProgressService progressService) async {
    await showJohnPrologue(
      context: context,
      progressService: progressService,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: JohnThemedAppBar(
        room: JohnSchoolRoom.foyer,
        title: 'Level 1 • Базовый курс',
        actions: [
          // XP Badge
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
      body: JohnRoomBackground(
        room: JohnSchoolRoom.foyer,
        child: Consumer<LessonRepository>(
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

            final lessons = lessonRepo.lessons;
            if (lessons.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      '⚠️ Уроки не загружены!',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('Проверьте консоль Flutter (терминал где запускали)'),
                  ],
                ),
              );
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  JohnRoomSection(
                    room: JohnSchoolRoom.flavorLab,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const BlockHeader(
                          blockId: 'A',
                          title: 'Основы вкуса',
                          lessonRange: '1-4',
                        ),
                        _BlockIntroCard(
                          blockId: 'A',
                          data: _blockIntroData['A']!,
                        ),
                        const SizedBox(height: 12),
                        _LessonGrid(
                          lessons:
                              lessons.where((l) => l.blockId == 'A').toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  JohnRoomSection(
                    room: JohnSchoolRoom.toolBench,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const BlockHeader(
                          blockId: 'B',
                          title: 'Инструменты и mise en place',
                          lessonRange: '5-9',
                        ),
                        _BlockIntroCard(
                          blockId: 'B',
                          data: _blockIntroData['B']!,
                        ),
                        const SizedBox(height: 12),
                        _LessonGrid(
                          lessons:
                              lessons.where((l) => l.blockId == 'B').toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  JohnRoomSection(
                    room: JohnSchoolRoom.classicsLounge,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const BlockHeader(
                          blockId: 'C',
                          title: 'Первые коктейли',
                          lessonRange: '10-13',
                        ),
                        _BlockIntroCard(
                          blockId: 'C',
                          data: _blockIntroData['C']!,
                        ),
                        const SizedBox(height: 12),
                        _LessonGrid(
                          lessons:
                              lessons.where((l) => l.blockId == 'C').toList(),
                        ),
                      ],
                    ),
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
}

class _BlockIntroCard extends StatelessWidget {
  final String blockId;
  final _BlockIntroData data;

  const _BlockIntroCard({required this.blockId, required this.data});

  @override
  Widget build(BuildContext context) {
    final room = JohnRoomStyle.roomForBlock(blockId);
    final style = JohnRoomStyle.forRoom(room);
    return JohnWoodPanel(
      room: room,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: style.accent, width: 1.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              data.assetPath,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: TextStyle(
                    color: style.accent,
                    fontFamily: 'serif',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  data.text,
                  style: TextStyle(
                    color: style.onDark.withAlpha(205),
                    fontSize: 12,
                    height: 1.35,
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

/// Grid of lesson cards.
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
            final practiceDone =
                progressService.isLessonPracticeComplete(lesson.id);
            final termsLearned =
                progressService.getLearnedTermCount(lesson.terms);

            return LessonCard(
              lesson: lesson,
              status: status,
              practiceComplete: practiceDone,
              termsLearned: termsLearned,
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

    // If already completed, keep it
    if (savedStatus == LessonStatus.completed) {
      return LessonStatus.completed;
    }

    // Check if unlocked
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
