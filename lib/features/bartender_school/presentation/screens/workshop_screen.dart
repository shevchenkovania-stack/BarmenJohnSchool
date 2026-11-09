import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coin/core/theme/app_theme.dart';
import 'package:coin/features/bartender_school/data/progress_service.dart';
import 'package:coin/features/bartender_school/data/practice_challenges.dart';
import 'package:coin/features/bartender_school/presentation/screens/practice_flow_screen.dart';
import 'package:coin/features/bartender_school/domain/entities/progress.dart';
import 'package:coin/features/bartender_school/presentation/widgets/john_school_visuals.dart';

/// Хаб Мастерской — список практических заданий по блокам.
class WorkshopScreen extends StatelessWidget {
  const WorkshopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const JohnThemedAppBar(
        room: JohnSchoolRoom.workshop,
        title: 'Мастерская Джона',
        automaticallyImplyLeading: false,
      ),
      body: Consumer<ProgressService>(
        builder: (context, progress, _) {
          // Группируем задания по блокам. Лимит — это не «сколько есть в
          // данных», а «сколько можно показать сейчас»: уроки блока A уже
          // отправляют в Мастерскую по имени коктейля, поэтому все семь
          // заданий блока должны быть видны.
          const blockLimits = {'A': 7, 'B': 3, 'C': 4};
          final blocks = <String, List<PracticeChallenge>>{};
          for (final c in allPracticeChallenges) {
            final limit = blockLimits[c.blockId];
            if (limit == null) continue; // Skip blocks not in Level 1
            final list = blocks.putIfAbsent(c.blockId, () => []);
            if (list.length < limit) list.add(c);
          }

          // Комната отвечает на прогресс: бокал на стойке, когда хотя бы один
          // коктейль собран, и верхний свет с медалью, когда собраны все.
          // Сам оверлей стадии ещё не подключён к `JohnRoomBackground`,
          // поэтому фон рисуем без него — иначе экран не компилируется.
          return JohnRoomBackground(
            room: JohnSchoolRoom.workshop,
            child: _WorkshopBody(
              blocks: blocks,
              progress: progress,
            ),
          );
        },
      ),
    );
  }
}

class _WorkshopBody extends StatelessWidget {
  final Map<String, List<PracticeChallenge>> blocks;
  final ProgressService progress;

  const _WorkshopBody({required this.blocks, required this.progress});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Заголовок с Джоном + XP ────────────────────────────────
        _JohnHeader(
          xp: progress.workshopPracticeXp,
          level: progress.workshopPracticeLevel,
          nextXp: progress.workshopNextLevelXp,
          streak: progress.streak,
          badges: progress.getUnlockedBadgeIds().length,
          coins: progress.coins,
        ),
        // Мастерская остаётся только для практики.
        // Мудрость открывается с главной, Полка бармена временно скрыта.
        const SizedBox(height: 20),

        // ── Блоки заданий ───────────────────────────────────────────
        for (final blockId in ['A', 'B', 'C'])
          if (blocks.containsKey(blockId)) ...[
            _BlockSection(
              blockId: blockId,
              challenges: blocks[blockId]!,
              progress: progress,
              allBlocks: blocks,
            ),
            const SizedBox(height: 16),
          ],

        const SizedBox(height: 32),
      ],
    );
  }
}

// ── Заголовок с Джоном ──────────────────────────────────────────────────────

class _JohnHeader extends StatelessWidget {
  final int xp;
  final String level;
  final int nextXp;
  final int streak;
  final int badges;
  final int coins;

  const _JohnHeader({
    required this.xp,
    required this.level,
    required this.nextXp,
    required this.streak,
    required this.badges,
    required this.coins,
  });

  @override
  Widget build(BuildContext context) {
    final progress = xp / nextXp;
    return JohnWoodPanel(
      room: JohnSchoolRoom.workshop,
      highlighted: true,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'images/barista_john_teach.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.primary.withAlpha(30),
                    child: const Icon(Icons.person, color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$level — $xp XP',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // XP progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: AppColors.divider.withAlpha(60),
                        valueColor:
                            const AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'До $nextXp XP',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary.withAlpha(180),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Streak + badges + coins row
          if (streak > 0 || badges > 0 || coins > 0) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (streak > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '🔥 $streak дн.',
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                if (streak > 0 && badges > 0) const SizedBox(width: 8),
                if (badges > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.amber.withAlpha(25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '🏆 $badges',
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                if ((streak > 0 || badges > 0) && coins > 0)
                  const SizedBox(width: 8),
                if (coins > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withAlpha(20),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '🪙 $coins',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFD4AF37),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Секция блока ────────────────────────────────────────────────────────────

class _BlockSection extends StatelessWidget {
  final String blockId;
  final List<PracticeChallenge> challenges;
  final ProgressService progress;
  final Map<String, List<PracticeChallenge>> allBlocks;

  const _BlockSection({
    required this.blockId,
    required this.challenges,
    required this.progress,
    required this.allBlocks,
  });

  static const _blockTitles = {
    'A': 'Основы вкуса',
    'B': 'Инструменты и техника',
    'C': 'Первые классики',
    'E': 'Классики Level 2',
  };

  /// Предыдущий блок (B→A, C→B). Для A — null (всегда доступен).
  String? get _previousBlockId {
    switch (blockId) {
      case 'B':
        return 'A';
      case 'C':
        return 'B';
      default:
        return null;
    }
  }

  /// Весь предыдущий блок пройден (каждое задание ≥ 1 звезды).
  bool get _isPreviousBlockComplete {
    final prevId = _previousBlockId;
    if (prevId == null) return true; // Блок A всегда доступен
    final prevChallenges = allBlocks[prevId];
    if (prevChallenges == null) return true;
    return prevChallenges.every(
      (c) => progress.getPracticeStars(c.id) > 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBlockLocked = !_isPreviousBlockComplete;
    const room = JohnSchoolRoom.workshop;
    final style = JohnRoomStyle.forRoom(room);

    return JohnWoodPanel(
      room: room,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок блока + прогресс
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (isBlockLocked)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Icon(
                            Icons.lock_outline_rounded,
                            size: 16,
                            color: AppColors.textSecondary.withAlpha(180),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          'Блок $blockId — ${_blockTitles[blockId] ?? ''}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isBlockLocked
                                ? AppColors.textSecondary
                                : style.onDark,
                            fontFamily: 'serif',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${_completedCount()}/${challenges.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isBlockLocked
                        ? AppColors.textSecondary.withAlpha(180)
                        : style.accent,
                  ),
                ),
              ],
            ),
          ),

          if (isBlockLocked)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'Откроется после блока $_previousBlockId',
                style: TextStyle(
                  color: AppColors.textSecondary.withAlpha(180),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

          // Карточки заданий всегда видны. Закрытые блоки нельзя открыть.
          ...challenges.map((challenge) {
            final stars = progress.getPracticeStars(challenge.id);
            final isLessonComplete =
                progress.getLessonStatus(challenge.lessonId) ==
                    LessonStatus.completed;
            final isChallengeLocked = isBlockLocked || !isLessonComplete;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ChallengeCard(
                challenge: challenge,
                stars: stars,
                isLocked: isChallengeLocked,
                onTap: isChallengeLocked
                    ? null
                    : () => _openChallenge(context, challenge),
              ),
            );
          }),
        ],
      ),
    );
  }

  int _completedCount() =>
      challenges.where((c) => progress.getPracticeStars(c.id) > 0).length;

  void _openChallenge(BuildContext context, PracticeChallenge challenge) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PracticeFlowScreen(challenge: challenge),
      ),
    );
  }
}

// ── Карточка задания ────────────────────────────────────────────────────────

class _ChallengeCard extends StatelessWidget {
  final PracticeChallenge challenge;
  final int stars;
  final bool isLocked;
  final VoidCallback? onTap;

  const _ChallengeCard({
    required this.challenge,
    required this.stars,
    required this.isLocked,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const room = JohnSchoolRoom.workshop;
    final style = JohnRoomStyle.forRoom(room);
    final bgColor =
        isLocked ? style.surface.withAlpha(150) : style.surfaceLight;

    final borderColor =
        isLocked ? style.accent.withAlpha(45) : style.accent.withAlpha(115);

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: isLocked ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Row(
            children: [
              // Эмодзи коктейля
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isLocked
                      ? AppColors.textSecondary.withAlpha(20)
                      : style.accent.withAlpha(28),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: isLocked
                      ? const Icon(Icons.lock_outline,
                          size: 20, color: AppColors.textSecondary)
                      : Padding(
                          padding: const EdgeInsets.all(8),
                          child: Image.asset(
                            challenge.blockId == 'A'
                                ? 'images/ui_icon_balance_precision.png'
                                : challenge.blockId == 'B'
                                    ? 'images/ui_icon_tool_station.png'
                                    : 'images/ui_icon_practice_motion.png',
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),

              // Название и статус
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.cocktailName,
                      style: TextStyle(
                        color:
                            isLocked ? AppColors.textSecondary : style.onDark,
                        fontFamily: 'serif',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isLocked
                          ? 'Пройди ${challenge.lessonId.replaceAll('lesson_', 'Урок ')}'
                          : stars > 0
                              ? _starsLabel(stars)
                              : 'Готово к практике',
                      style: TextStyle(
                        color: isLocked
                            ? AppColors.textSecondary.withAlpha(180)
                            : style.onDark.withAlpha(180),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    // [LEVEL-DUPE] Восемь коктейлей встречаются и в Level 1,
                    // и в Level 2. Это осознанное повторение навыка, но
                    // прятать его нельзя — иначе новизна выглядит обманом.
                    if (_isRepetition) ...[
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: style.accent.withAlpha(30),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: style.accent.withAlpha(90)),
                        ),
                        child: Text(
                          'повторение',
                          style: TextStyle(
                            color: style.accent,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Звёзды или стрелка
              if (!isLocked && stars > 0) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    3,
                    (i) => Icon(
                      i < stars
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      size: 18,
                      color: i < stars ? Colors.amber : AppColors.divider,
                    ),
                  ),
                ),
              ] else if (!isLocked)
                Icon(Icons.play_arrow_rounded, color: style.accent, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Коктейль есть и в Level 1, и в Level 2.
  bool get _isRepetition {
    if (challenge.blockId != 'D' &&
        challenge.blockId != 'E' &&
        challenge.blockId != 'F') {
      return false;
    }
    return allPracticeChallenges.any(
      (c) =>
          (c.blockId == 'A' || c.blockId == 'B' || c.blockId == 'C') &&
          c.cocktailName == challenge.cocktailName,
    );
  }

  String _starsLabel(int stars) {
    switch (stars) {
      case 3:
        return 'Идеально! 3 звезды';
      case 2:
        return 'Хорошо! 2 звезды';
      case 1:
        return 'Начало положено. 1 звезда';
      default:
        return '';
    }
  }
}
