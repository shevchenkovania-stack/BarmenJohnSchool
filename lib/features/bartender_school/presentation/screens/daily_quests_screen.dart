/// Экран ежедневных заданий.
///
/// 4 задания в день, сбрасываются в 00:00.
/// Все 4 выполнены → бонус "День закрыт" (+50 монет).
library;

import 'package:coin/features/bartender_school/data/daily_quest_service.dart';
import 'package:coin/features/bartender_school/data/progress_service.dart';
import 'package:coin/features/bartender_school/presentation/widgets/john_school_visuals.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DailyQuestsScreen extends StatelessWidget {
  const DailyQuestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const room = JohnSchoolRoom.foyer;

    return Scaffold(
      backgroundColor: const Color(0xFF120B08),
      appBar: const JohnThemedAppBar(
        room: room,
        title: 'Задания дня',
      ),
      body: JohnRoomBackground(
        room: room,
        child: Consumer<DailyQuestService>(
          builder: (context, questService, _) {
            final quests = questService.quests;
            final completed = questService.completedCount;
            final allDone = questService.allCompleted;
            final bonusClaimed = questService.isBonusClaimed;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  _DayProgressCard(
                    completed: completed,
                    total: 4,
                    allDone: allDone,
                    bonusClaimed: bonusClaimed,
                    onClaimBonus: () async {
                      final bonus = await questService.claimBonus();
                      if (bonus > 0 && context.mounted) {
                        context.read<ProgressService>().earnCoins(bonus);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Бонус за закрытый день: +$bonus монет',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              backgroundColor: const Color(0xFF2D2218),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        for (var index = 0; index < quests.length; index++) ...[
                          _QuestTile(quest: quests[index]),
                          if (index < quests.length - 1)
                            const SizedBox(height: 10),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: JohnParchmentPanel(
                      room: room,
                      padding: const EdgeInsets.all(13),
                      child: Row(
                        children: [
                          Image.asset(
                            'images/ui_icon_tip_citrus.png',
                            width: 30,
                            height: 30,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Новая доска заданий появится в 00:00. '
                              'Закрой все четыре пункта, чтобы получить бонус.',
                              style: TextStyle(
                                color: Color(0xFF3A2717),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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

class _DayProgressCard extends StatelessWidget {
  final int completed;
  final int total;
  final bool allDone;
  final bool bonusClaimed;
  final VoidCallback onClaimBonus;

  const _DayProgressCard({
    required this.completed,
    required this.total,
    required this.allDone,
    required this.bonusClaimed,
    required this.onClaimBonus,
  });

  @override
  Widget build(BuildContext context) {
    const room = JohnSchoolRoom.foyer;
    final style = JohnRoomStyle.forRoom(room);
    final progress = completed / total;

    return JohnWoodPanel(
      room: room,
      highlighted: allDone && !bonusClaimed,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: style.accent.withAlpha(28),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: style.accent.withAlpha(125)),
                ),
                child: Image.asset('images/ui_icon_checklist.png'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ДОСКА НА СЕГОДНЯ',
                      style: TextStyle(
                        color: style.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Четыре дела за смену',
                      style: TextStyle(
                        color: style.onDark,
                        fontFamily: 'serif',
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              JohnStatusBadge(
                room: room,
                label: '$completed/$total',
                strong: allDone,
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.black.withAlpha(80),
              valueColor: AlwaysStoppedAnimation<Color>(
                allDone ? const Color(0xFF7FA46B) : style.accent,
              ),
            ),
          ),
          const SizedBox(height: 13),
          if (allDone && !bonusClaimed)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onClaimBonus,
                icon: Image.asset(
                  'images/ui_icon_term_medal.png',
                  width: 20,
                  height: 20,
                ),
                label: const Text('Забрать бонус +50'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: style.accent,
                  foregroundColor: style.ink,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            )
          else if (allDone && bonusClaimed)
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF89B779),
                  size: 18,
                ),
                SizedBox(width: 7),
                Flexible(
                  child: Text(
                    'День закрыт. Возвращайся завтра',
                    style: TextStyle(
                      color: Color(0xFF9AC58A),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Image.asset(
                  'images/ui_icon_term_medal.png',
                  width: 18,
                  height: 18,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Выполни все — получи бонус +50',
                    style: TextStyle(
                      color: style.onDark.withAlpha(180),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _QuestTile extends StatelessWidget {
  final DailyQuest quest;

  const _QuestTile({required this.quest});

  String get _iconAsset {
    return switch (quest.type) {
      DailyQuestType.openApp => 'images/ui_icon_play_card.png',
      DailyQuestType.completeLesson => 'images/ui_icon_book_theory.png',
      DailyQuestType.practiceCocktail => 'images/ui_icon_practice_motion.png',
      DailyQuestType.passQuiz => 'images/ui_icon_checklist.png',
    };
  }

  @override
  Widget build(BuildContext context) {
    const room = JohnSchoolRoom.foyer;
    final style = JohnRoomStyle.forRoom(room);
    final isDone = quest.isCompleted;

    return AnimatedOpacity(
      opacity: isDone ? .78 : 1,
      duration: const Duration(milliseconds: 180),
      child: JohnParchmentPanel(
        room: room,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDone
                    ? const Color(0xFF6D8B55).withAlpha(45)
                    : style.accent.withAlpha(35),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: isDone
                      ? const Color(0xFF6D8B55).withAlpha(120)
                      : style.accent.withAlpha(120),
                ),
              ),
              child: isDone
                  ? const Icon(
                      Icons.check_rounded,
                      color: Color(0xFF4D713E),
                      size: 23,
                    )
                  : Image.asset(_iconAsset),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quest.title,
                    style: TextStyle(
                      color: const Color(0xFF342114),
                      fontFamily: 'serif',
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isDone ? 'Выполнено' : 'Награда за задание',
                    style: TextStyle(
                      color: const Color(0xFF4B3525).withAlpha(180),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: isDone
                    ? const Color(0xFF6D8B55).withAlpha(35)
                    : style.accent.withAlpha(35),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDone
                      ? const Color(0xFF6D8B55).withAlpha(115)
                      : style.accent.withAlpha(120),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isDone)
                    const Icon(
                      Icons.check_rounded,
                      color: Color(0xFF4D713E),
                      size: 14,
                    )
                  else
                    Image.asset(
                      'images/ui_icon_term_medal.png',
                      width: 14,
                      height: 14,
                    ),
                  const SizedBox(width: 4),
                  Text(
                    '+${quest.coinReward}',
                    style: TextStyle(
                      color: isDone
                          ? const Color(0xFF4D713E)
                          : const Color(0xFF6D471E),
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
