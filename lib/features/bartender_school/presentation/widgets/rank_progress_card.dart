import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:coin/features/bartender_school/data/lesson_repository.dart';
import 'package:coin/features/bartender_school/data/progress_service.dart';
import 'package:coin/features/bartender_school/presentation/widgets/john_school_visuals.dart';

/// Пороги ранга по XP внутри одного звания.
///
/// Ранг привязан к закрытым блокам (стажёр → бармен → миксолог), а полоса
/// внутри звания показывает, сколько осталось до следующего. Так «+50 XP»
/// перестаёт быть числом в вакууме: у него есть адрес.
const List<int> _rankXpSteps = [0, 250, 600, 1000, 1500];

/// Звание и его прогресс.
class RankInfo {
  final String title;
  final String emoji;
  final int levelInRank;
  final int xpInRank;
  final int xpToNext;
  final bool isMaxed;

  const RankInfo({
    required this.title,
    required this.emoji,
    required this.levelInRank,
    required this.xpInRank,
    required this.xpToNext,
    required this.isMaxed,
  });

  double get progress =>
      xpToNext <= 0 ? 1.0 : (xpInRank / xpToNext).clamp(0.0, 1.0);
}

/// Считает ранг из звания и общего XP.
///
/// Вынесено из виджета, чтобы числа проверялись тестом без сборки экрана.
RankInfo rankInfoFor({
  required ({String title, String emoji})? rank,
  required int totalXP,
}) {
  final title = rank?.title ?? 'Новичок';
  final emoji = rank?.emoji ?? '🥃';

  // Внутри звания шаги общие: это «уровень внутри ранга», а не глобальный.
  var level = 1;
  for (var i = 0; i < _rankXpSteps.length; i++) {
    if (totalXP >= _rankXpSteps[i]) level = i + 1;
  }
  final index = (level - 1).clamp(0, _rankXpSteps.length - 1);
  final floor = _rankXpSteps[index];
  final isMaxed = index >= _rankXpSteps.length - 1;
  final ceiling = isMaxed ? floor : _rankXpSteps[index + 1];

  return RankInfo(
    title: title,
    emoji: emoji,
    levelInRank: level,
    xpInRank: (totalXP - floor).clamp(0, 1 << 30),
    xpToNext: isMaxed ? 0 : ceiling - floor,
    isMaxed: isMaxed,
  );
}

/// Компактный блок «ранг + XP до следующего + серия».
///
/// Заменяет сухую строку с цифрами: тот же смысл, но видно, куда идём.
class RankProgressCard extends StatelessWidget {
  const RankProgressCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ProgressService, LessonRepository>(
      builder: (context, progress, lessonRepo, _) {
        final info = rankInfoFor(
          rank: progress.currentRank,
          totalXP: progress.totalXP,
        );
        // Карточка живёт на главной, а главная — это комната школы:
        // раньше здесь стояли фиолетовые литералы из старого проекта.
        final style = JohnRoomStyle.forRoom(JohnSchoolRoom.foyer);

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: style.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: style.accent.withAlpha(110)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(info.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${info.title} · уровень ${info.levelInRank}',
                      style: TextStyle(
                        color: style.onDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (progress.streak > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: style.accent.withAlpha(35),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: style.accent.withAlpha(80),
                        ),
                      ),
                      child: Text(
                        '🔥 ${progress.streak}',
                        style: TextStyle(
                          color: style.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: info.progress,
                  minHeight: 7,
                  backgroundColor: style.accent.withAlpha(45),
                  valueColor: AlwaysStoppedAnimation<Color>(style.accent),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                info.isMaxed
                    ? 'Максимум внутри звания · ${progress.totalXP} XP всего'
                    : '${info.xpInRank} / ${info.xpToNext} XP до следующего · '
                        '${progress.totalXP} XP всего',
                style: TextStyle(
                  color: style.onDark.withAlpha(170),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
