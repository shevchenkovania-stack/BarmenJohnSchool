import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:coin/core/theme/app_theme.dart';
import 'package:coin/features/bartender_school/data/blind_tasting.dart';
import 'package:coin/features/bartender_school/data/lesson_repository.dart';
import 'package:coin/features/bartender_school/data/progress_service.dart';
import 'package:coin/features/bartender_school/domain/entities/progress.dart';
import 'package:coin/features/bartender_school/presentation/widgets/john_school_visuals.dart';

/// Слепая дегустация: угадать терм по трём подсказкам.
///
/// Один раунд в день, без таймера и без наказаний. Подсказки открываются
/// по одной — так игрок сам выбирает, сколько ему нужно.
class BlindTastingScreen extends StatefulWidget {
  const BlindTastingScreen({super.key});

  @override
  State<BlindTastingScreen> createState() => _BlindTastingScreenState();
}

class _BlindTastingScreenState extends State<BlindTastingScreen> {
  BlindTastingRound? _round;
  int _hintsOpen = 1;
  String? _pickedName;
  bool _alreadyPlayed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  void _start() {
    final progress = context.read<ProgressService>();
    final lessons = context.read<LessonRepository>();
    final service = context.read<BlindTastingService>();

    // Термы из завершённых уроков: игра не должна опережать обучение.
    final learnt = <String>{};
    for (final lesson in lessons.lessons) {
      if (progress.getLessonStatus(lesson.id) != LessonStatus.completed) {
        continue;
      }
      learnt.addAll(lesson.terms);
    }

    setState(() {
      _round = buildBlindTastingRound(learntTermNames: learnt);
      _alreadyPlayed = service.playedToday;
    });
  }

  bool get _answered => _pickedName != null;

  Future<void> _pick(String name) async {
    if (_answered) return;
    final round = _round;
    if (round == null) return;

    final correct = name == round.answer.russianName;
    setState(() => _pickedName = name);
    await context.read<BlindTastingService>().registerRound(correct: correct);
  }

  @override
  Widget build(BuildContext context) {
    final style = JohnRoomStyle.forRoom(JohnSchoolRoom.flavorLab);
    final round = _round;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const JohnThemedAppBar(
        room: JohnSchoolRoom.flavorLab,
        title: 'Слепая дегустация',
      ),
      body: JohnRoomBackground(
        room: JohnSchoolRoom.flavorLab,
        evening: isEveningNow(),
        child: round == null
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Пока не из чего собирать раунд.\n'
                    'Пройди первый урок — и возвращайся.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _alreadyPlayed
                          ? 'Сегодняшний раунд уже сыгран'
                          : 'Гость ставит бокал и молчит. Угадай, о чём речь',
                      style: TextStyle(
                        color: style.onDark.withAlpha(210),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 14),
                    for (var i = 0; i < _hintsOpen; i++) ...[
                      _HintCard(
                        index: i + 1,
                        text: round.hints[i],
                        style: style,
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (_hintsOpen < round.hints.length && !_answered)
                      TextButton.icon(
                        onPressed: () => setState(() => _hintsOpen++),
                        icon: const Icon(Icons.remove_red_eye_outlined,
                            size: 18, color: AppColors.primary),
                        label: Text(
                          'Ещё подсказка (${round.hints.length - _hintsOpen})',
                          style: const TextStyle(color: AppColors.primary),
                        ),
                      ),
                    const SizedBox(height: 18),
                    for (final option in round.options)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _OptionTile(
                          label: option.russianName,
                          isPicked: _pickedName == option.russianName,
                          isAnswer:
                              option.russianName == round.answer.russianName,
                          answered: _answered,
                          style: style,
                          onTap: () => _pick(option.russianName),
                        ),
                      ),
                    if (_answered) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: style.surface.withAlpha(210),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: style.accent.withAlpha(80)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _pickedName == round.answer.russianName
                                  ? 'Точно. Это ${round.answer.russianName}.'
                                  : 'Это ${round.answer.russianName}. '
                                      'Запомни по одной детали — так надёжнее.',
                              style: TextStyle(
                                color: style.accent,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              round.answer.definition,
                              style: TextStyle(
                                color: style.onDark,
                                fontSize: 13,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  final int index;
  final String text;
  final JohnRoomStyle style;

  const _HintCard({
    required this.index,
    required this.text,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: style.surface.withAlpha(190),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: style.accent.withAlpha(60)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$index',
            style: TextStyle(
              color: style.accent,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: style.onDark,
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String label;
  final bool isPicked;
  final bool isAnswer;
  final bool answered;
  final JohnRoomStyle style;
  final VoidCallback onTap;

  const _OptionTile({
    required this.label,
    required this.isPicked,
    required this.isAnswer,
    required this.answered,
    required this.style,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color border = style.accent.withAlpha(55);
    Color text = style.onDark;

    if (answered) {
      if (isAnswer) {
        border = const Color(0xFF6FB07A);
        text = const Color(0xFFBFE6C6);
      } else if (isPicked) {
        border = const Color(0xFFD0824A);
        text = const Color(0xFFF0C9A8);
      } else {
        border = style.accent.withAlpha(35);
        text = style.onDark.withAlpha(140);
      }
    }

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: answered ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: style.surface.withAlpha(answered ? 150 : 200),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: border, width: answered && isAnswer ? 2 : 1),
        ),
        child: Text(
          label,
          style:
              TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: text),
        ),
      ),
    );
  }
}
