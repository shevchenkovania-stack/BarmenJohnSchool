import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:coin/features/bartender_school/data/practice_challenges.dart';
import 'package:coin/features/bartender_school/data/progress_service.dart';
import 'package:coin/features/bartender_school/domain/entities/progress.dart';
import 'package:coin/features/bartender_school/presentation/screens/practice_flow_screen.dart';
import 'package:coin/features/bartender_school/presentation/widgets/john_school_visuals.dart';

/// Мостик из урока в Мастерскую.
///
/// Слайд `practice` раньше был обычным текстом: «возьми стакан, налей
/// 30 мл». В метро это не выполнить. Мастерская уже умеет проверять
/// состав, пропорции и метод — уроку остаётся привести туда.
///
/// Задание открывается после урока: до этого кнопка отвечает словами,
/// а не ведёт в запертую дверь. Молчаливая кнопка хуже закрытой двери.
class WorkshopBridge extends StatelessWidget {
  final String lessonId;
  final JohnSchoolRoom? schoolRoom;

  const WorkshopBridge({required this.lessonId, this.schoolRoom});

  List<PracticeChallenge> get _challenges =>
      allPracticeChallenges.where((c) => c.lessonId == lessonId).toList();

  void _open(BuildContext context, PracticeChallenge challenge) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PracticeFlowScreen(challenge: challenge),
      ),
    );
  }

  void _explainLock(BuildContext context, JohnRoomStyle style) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: style.surfaceLight,
        content: Text(
          'Сначала закрой урок. Мастерская откроется после квиза — '
          'чтобы ты собирал коктейль, уже понимая зачем.',
          style: TextStyle(color: style.onDark, height: 1.4),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = JohnRoomStyle.forRoom(schoolRoom ?? JohnSchoolRoom.workshop);
    final progress = context.watch<ProgressService>();
    final isDone = progress.getLessonStatus(lessonId) == LessonStatus.completed;
    final challenges = _challenges;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: JohnWoodPanel(
        room: schoolRoom ?? JohnSchoolRoom.workshop,
        highlighted: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Дверь. Пока без картинки: рама и табличка.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              decoration: BoxDecoration(
                color: style.surface.withAlpha(170),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: style.accent.withAlpha(120)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.door_front_door_outlined,
                          size: 20, color: style.accent),
                      const SizedBox(width: 10),
                      Text(
                        'МАСТЕРСКАЯ ДЖОНА',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.w900,
                          color: style.accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isDone
                        ? 'Дверь открыта. Выбери, что соберёшь.'
                        : 'Дверь пока прикрыта: она откроется, когда закроешь урок.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      fontFamily: 'serif',
                      color: style.onDark.withAlpha(200),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (challenges.isEmpty)
              Text(
                'У этого урока пока нет заданий в Мастерской.',
                style: TextStyle(color: style.onDark.withAlpha(170)),
              )
            else
              for (final challenge in challenges) ...[
                _WorkshopDoorCard(
                  challenge: challenge,
                  style: style,
                  isOpen: isDone,
                  onTap: () => isDone
                      ? _open(context, challenge)
                      : _explainLock(context, style),
                ),
                const SizedBox(height: 10),
              ],
          ],
        ),
      ),
    );
  }
}

/// Один коктейль на двери Мастерской.
class _WorkshopDoorCard extends StatelessWidget {
  final PracticeChallenge challenge;
  final JohnRoomStyle style;
  final bool isOpen;
  final VoidCallback onTap;

  const _WorkshopDoorCard({
    required this.challenge,
    required this.style,
    required this.isOpen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isOpen ? style.surfaceLight : style.surface.withAlpha(150),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: Key('workshop_door_${challenge.id}'),
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: style.accent.withAlpha(isOpen ? 115 : 45),
              width: isOpen ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Text(challenge.cocktailEmoji,
                  style: TextStyle(
                      fontSize: 20,
                      color: isOpen ? null : style.onDark.withAlpha(110))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.cocktailName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color:
                            isOpen ? style.onDark : style.onDark.withAlpha(120),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isOpen ? 'Собрать' : 'Откроется после урока',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isOpen ? style.accent : style.onDark.withAlpha(105),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isOpen ? Icons.arrow_forward : Icons.lock_outline,
                size: 17,
                color: style.accent.withAlpha(isOpen ? 220 : 110),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
