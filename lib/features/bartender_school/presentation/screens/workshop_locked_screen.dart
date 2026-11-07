import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:coin/core/theme/app_theme.dart';
import 'package:coin/features/bartender_school/data/progress_service.dart';
import 'package:coin/features/bartender_school/domain/entities/progress.dart';
import 'package:coin/features/bartender_school/presentation/widgets/john_school_visuals.dart';

/// Экран мастерской, пока она закрыта.
///
/// Раньше нажатие на вкладку блокировалось снизу всплывающей плашкой: человек
/// видел замок, но не понимал, что именно нужно сделать. Здесь вместо
/// пустоты — объяснение и одна кнопка, которая ведёт прямо к нужному уроку.
class WorkshopLockedScreen extends StatelessWidget {
  /// Урок, после которого открывается мастерская.
  static const String unlockLessonId = 'lesson_A_01';

  const WorkshopLockedScreen({super.key, required this.onGoToLesson});

  /// Переход к уроку; оболочка сама переключит вкладку на «Школу».
  final VoidCallback onGoToLesson;

  @override
  Widget build(BuildContext context) {
    final style = JohnRoomStyle.forRoom(JohnSchoolRoom.toolBench);
    final progress = context.watch<ProgressService>();
    final unlocked =
        progress.getLessonStatus(unlockLessonId) == LessonStatus.completed;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const JohnThemedAppBar(
        room: JohnSchoolRoom.toolBench,
        title: 'Мастерская',
      ),
      body: JohnRoomBackground(
        room: JohnSchoolRoom.toolBench,
        evening: isEveningNow(),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipOval(
                  child: Image.asset(
                    'images/barista_john_practice.png',
                    width: 132,
                    height: 132,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.local_bar_rounded,
                      size: 96,
                      color: style.accent,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Icon(
                  unlocked
                      ? Icons.lock_open_rounded
                      : Icons.lock_outline_rounded,
                  color: style.accent,
                  size: 22,
                ),
                const SizedBox(height: 10),
                Text(
                  'МАСТЕРСКАЯ ЗАКРЫТА',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: style.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'За стойку пускают не сразу. Сначала — первый урок: там ты '
                  'узнаешь, из чего вообще собирается вкус.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: style.onDark,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: style.surface.withAlpha(205),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: style.accent.withAlpha(70)),
                  ),
                  child: Row(
                    children: [
                      Text('📖', style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Урок A1 «5 вкусов — твой пульт управления»',
                          style: TextStyle(
                            color: style.onDark,
                            fontSize: 13.5,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onGoToLesson,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: style.accent,
                      foregroundColor: style.ink,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'К первому уроку',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'После урока откроется и практика: три коктейля, звёзды, '
                  'таймер — как за настоящей стойкой.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: style.onDark.withAlpha(170),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
