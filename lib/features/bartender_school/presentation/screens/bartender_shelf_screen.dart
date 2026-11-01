/// Полка бармена — визуальная коллекция освоенных коктейлей.
///
/// Каждая бутылка = коктейль, освоенный в мастерской.
/// Группировка по блокам (A, B, C). Звёзды показаны на этикетке.
library;

import 'package:coin/features/bartender_school/data/practice_challenges.dart';
import 'package:coin/features/bartender_school/data/progress_service.dart';
import 'package:coin/features/bartender_school/presentation/widgets/john_school_visuals.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BartenderShelfScreen extends StatelessWidget {
  const BartenderShelfScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const room = JohnSchoolRoom.classicsLounge;

    return Scaffold(
      backgroundColor: const Color(0xFF120B08),
      appBar: const JohnThemedAppBar(
        room: room,
        title: 'Полка бармена',
      ),
      body: JohnRoomBackground(
        room: room,
        child: Consumer<ProgressService>(
          builder: (context, progress, _) {
            final allChallenges = allPracticeChallenges;
            final totalChallenges = allChallenges.length;
            final masteredCount = allChallenges
                .where(
                    (challenge) => progress.getPracticeStars(challenge.id) > 0)
                .length;
            final threeStarCount = allChallenges
                .where(
                    (challenge) => progress.getPracticeStars(challenge.id) >= 3)
                .length;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  _ShelfStats(
                    total: totalChallenges,
                    mastered: masteredCount,
                    threeStar: threeStarCount,
                  ),
                  const SizedBox(height: 18),
                  for (final blockId in ['A', 'B', 'C'])
                    _ShelfBlock(
                      blockId: blockId,
                      challenges: challengesForBlock(blockId),
                      progress: progress,
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ShelfStats extends StatelessWidget {
  final int total;
  final int mastered;
  final int threeStar;

  const _ShelfStats({
    required this.total,
    required this.mastered,
    required this.threeStar,
  });

  @override
  Widget build(BuildContext context) {
    const room = JohnSchoolRoom.classicsLounge;
    final style = JohnRoomStyle.forRoom(room);
    final pct = total > 0 ? mastered / total : 0.0;

    return JohnWoodPanel(
      room: room,
      highlighted: true,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: style.accent.withAlpha(28),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: style.accent.withAlpha(130)),
                ),
                child: Image.asset('images/ui_icon_tool_station.png'),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'КОЛЛЕКЦИЯ МАСТЕРА',
                      style: TextStyle(
                        color: style.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Освоенные рецепты',
                      style: TextStyle(
                        color: style.onDark,
                        fontFamily: 'serif',
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$mastered/$total',
                style: TextStyle(
                  color: style.accent,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: Colors.black.withAlpha(75),
              valueColor: AlwaysStoppedAnimation<Color>(style.accent),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatChip(
                iconAsset: 'images/ui_icon_book_theory.png',
                label: 'Освоено',
                value: '$mastered',
              ),
              _StatChip(
                iconAsset: 'images/ui_icon_term_medal.png',
                label: '3 звезды',
                value: '$threeStar',
              ),
              _StatChip(
                iconAsset: 'images/ui_icon_checklist.png',
                label: 'Прогресс',
                value: '${(pct * 100).toInt()}%',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String iconAsset;
  final String label;
  final String value;

  const _StatChip({
    required this.iconAsset,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final style = JohnRoomStyle.forRoom(JohnSchoolRoom.classicsLounge);
    return Column(
      children: [
        Image.asset(iconAsset, width: 22, height: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: style.onDark,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: style.onDark.withAlpha(145),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _ShelfBlock extends StatelessWidget {
  final String blockId;
  final List<PracticeChallenge> challenges;
  final ProgressService progress;

  const _ShelfBlock({
    required this.blockId,
    required this.challenges,
    required this.progress,
  });

  String get _blockTitle {
    return switch (blockId) {
      'A' => 'Блок A: Вкусы',
      'B' => 'Блок B: Инструменты',
      'C' => 'Блок C: Классика',
      _ => 'Блок $blockId',
    };
  }

  String get _blockArtwork {
    return switch (blockId) {
      'A' => 'images/lesson_a_01_balance.jpg',
      'B' => 'images/lesson_b_05_setup.jpg',
      'C' => 'images/lesson_c_09_mojito.jpg',
      _ => 'images/ui_icon_tool_station.png',
    };
  }

  @override
  Widget build(BuildContext context) {
    final masteredInBlock = challenges
        .where((challenge) => progress.getPracticeStars(challenge.id) > 0)
        .length;
    final room = JohnRoomStyle.roomForBlock(blockId);
    final style = JohnRoomStyle.forRoom(room);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
      child: JohnRoomSection(
        room: room,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Image.asset(
                    _blockArtwork,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _blockTitle,
                    style: TextStyle(
                      color: style.onDark,
                      fontFamily: 'serif',
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                JohnStatusBadge(
                  room: room,
                  label: '$masteredInBlock/${challenges.length}',
                  strong: masteredInBlock == challenges.length,
                ),
              ],
            ),
            const SizedBox(height: 8),
            JohnBrassDivider(room: room),
            const SizedBox(height: 4),
            _WoodenShelf(
              room: room,
              challenges: challenges,
              progress: progress,
            ),
          ],
        ),
      ),
    );
  }
}

class _WoodenShelf extends StatelessWidget {
  final JohnSchoolRoom room;
  final List<PracticeChallenge> challenges;
  final ProgressService progress;

  const _WoodenShelf({
    required this.room,
    required this.challenges,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final style = JohnRoomStyle.forRoom(room);
    const perRow = 4;
    final rows = <List<PracticeChallenge>>[];
    for (var i = 0; i < challenges.length; i += perRow) {
      final end =
          (i + perRow) > challenges.length ? challenges.length : i + perRow;
      rows.add(challenges.sublist(i, end));
    }

    return Column(
      children: [
        for (final row in rows) ...[
          _BottleRow(
            room: room,
            bottles: row,
            progress: progress,
          ),
          Container(
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  style.accentSoft.withAlpha(235),
                  style.ink.withAlpha(245),
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(110),
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _BottleRow extends StatelessWidget {
  final JohnSchoolRoom room;
  final List<PracticeChallenge> bottles;
  final ProgressService progress;

  const _BottleRow({
    required this.room,
    required this.bottles,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final challenge in bottles)
          _Bottle(
            room: room,
            challenge: challenge,
            stars: progress.getPracticeStars(challenge.id),
          ),
        for (var i = bottles.length; i < 4; i++)
          const SizedBox(width: 60, height: 88),
      ],
    );
  }
}

class _Bottle extends StatelessWidget {
  final JohnSchoolRoom room;
  final PracticeChallenge challenge;
  final int stars;

  const _Bottle({
    required this.room,
    required this.challenge,
    required this.stars,
  });

  String get _artworkAsset {
    return switch (challenge.lessonId) {
      'lesson_A_01' => 'images/lesson_a_01_balance.jpg',
      'lesson_A_02' => 'images/lesson_a_02_acid.jpg',
      'lesson_A_03' => 'images/lesson_a_03_sweetness.jpg',
      'lesson_A_04' => 'images/lesson_a_04_bitters.jpg',
      'lesson_B_05' => 'images/lesson_b_05_setup.jpg',
      'lesson_B_06' => 'images/lesson_b_06_precision.jpg',
      'lesson_B_07' => 'images/lesson_b_07_shake.jpg',
      'lesson_B_08' => 'images/lesson_b_08_ice.jpg',
      'lesson_C_09' => 'images/lesson_c_09_mojito.jpg',
      'lesson_C_10' => 'images/lesson_c_10_daiquiri.jpg',
      'lesson_C_11' => 'images/lesson_c_11_negroni.jpg',
      'lesson_C_12' => 'images/lesson_c_12_exam.jpg',
      _ => 'images/ui_icon_practice_motion.png',
    };
  }

  @override
  Widget build(BuildContext context) {
    final isMastered = stars > 0;
    final style = JohnRoomStyle.forRoom(room);

    final Color bottleColor;
    if (stars >= 3) {
      bottleColor = style.accent;
    } else if (stars == 2) {
      bottleColor = const Color(0xFF6F9A71);
    } else if (stars == 1) {
      bottleColor = const Color(0xFFAA7542);
    } else {
      bottleColor = style.onDark.withAlpha(70);
    }

    return SizedBox(
      width: 60,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 8,
            decoration: BoxDecoration(
              color: isMastered
                  ? bottleColor.withAlpha(115)
                  : style.onDark.withAlpha(35),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(3),
                topRight: Radius.circular(3),
              ),
            ),
          ),
          Container(
            width: 42,
            height: 58,
            decoration: BoxDecoration(
              color: isMastered
                  ? bottleColor.withAlpha(55)
                  : style.surface.withAlpha(185),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isMastered ? 8 : 4),
                topRight: Radius.circular(isMastered ? 8 : 4),
                bottomLeft: const Radius.circular(5),
                bottomRight: const Radius.circular(5),
              ),
              border: Border.all(
                color: isMastered
                    ? bottleColor.withAlpha(170)
                    : style.onDark.withAlpha(45),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isMastered)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.asset(
                      _artworkAsset,
                      width: 23,
                      height: 23,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Icon(
                    Icons.lock_rounded,
                    color: style.onDark.withAlpha(90),
                    size: 16,
                  ),
                if (isMastered) ...[
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      3,
                      (index) => Icon(
                        index < stars
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        size: 8,
                        color: index < stars
                            ? style.accent
                            : style.onDark.withAlpha(55),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isMastered ? challenge.cocktailName : '???',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isMastered ? style.onDark : style.onDark.withAlpha(80),
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
