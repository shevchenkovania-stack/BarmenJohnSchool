import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:coin/core/theme/app_theme.dart';
import 'package:coin/features/bartender_school/data/blind_tasting.dart';
import 'package:coin/features/bartender_school/data/progress_service.dart';
import 'package:coin/features/bartender_school/data/term_service.dart';
import 'package:coin/features/bartender_school/presentation/widgets/john_school_visuals.dart';

/// Слепая дегустация: один раунд в день, три подсказки по одной.
///
/// Подсказки открываются по очереди, чтобы это был не тест на удачу, а
/// работа с памятью. Разбор показывается сразу после выбора — иначе
/// ошибка не превращается в знание.
class BlindTastingScreen extends StatefulWidget {
  const BlindTastingScreen({super.key});

  @override
  State<BlindTastingScreen> createState() => _BlindTastingScreenState();
}

class _BlindTastingScreenState extends State<BlindTastingScreen> {
  BlindTastingRound? _round;
  int _revealedHints = 1;
  TermData? _picked;
  bool _played = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _build());
  }

  void _build() {
    final progress = context.read<ProgressService>();
    final learnt = <String>{};
    for (final term in TermService.allTerms) {
      if (progress.isTermLearned(term.russianName)) {
        learnt.add(term.russianName);
      }
    }
    setState(() {
      _round = buildBlindTastingRound(learntTermNames: learnt);
    });
  }

  Future<void> _pick(TermData option) async {
    if (_played || _round == null) return;
    final correct = option.russianName == _round!.answer.russianName;
    setState(() {
      _picked = option;
      _played = true;
    });
    await context.read<BlindTastingService>().registerRound(correct: correct);
  }

  @override
  Widget build(BuildContext context) {
    final tasting = context.watch<BlindTastingService>();
    final round = _round;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const JohnThemedAppBar(
        room: JohnSchoolRoom.flavorLab,
        title: 'Слепая дегустация',
      ),
      body: JohnRoomBackground(
        room: JohnSchoolRoom.flavorLab,
        child: SafeArea(
          child: round == null
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Пока не хватает изученных терминов.\n'
                      'Пройди ещё пару уроков — и Джон нальёт следующую пробу.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFFF3E7D0), height: 1.5),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        tasting.playedToday && !_played
                            ? 'Сегодняшний раунд уже сыгран. Возвращайся завтра.'
                            : 'Угадай, что в бокале.',
                        style: const TextStyle(
                          color: Color(0xFFF3E7D0),
                          fontFamily: 'serif',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Угадано ${tasting.correctCount} из ${tasting.playedCount}',
                        style: TextStyle(
                          color: const Color(0xFFF3E7D0).withAlpha(150),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 14),
                      for (var i = 0; i < _revealedHints; i++) ...[
                        _HintCard(index: i + 1, text: round.hints[i]),
                        const SizedBox(height: 8),
                      ],
                      if (_revealedHints < round.hints.length && !_played)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => setState(() => _revealedHints++),
                            icon:
                                const Icon(Icons.visibility_outlined, size: 16),
                            label: const Text('Открыть подсказку'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFD0A24C),
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                      for (final option in round.options) ...[
                        _OptionTile(
                          label: option.russianName,
                          state: _optionState(option),
                          onTap: () => _pick(option),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (_picked != null) ...[
                        const SizedBox(height: 6),
                        _RevealCard(
                          correct:
                              _picked!.russianName == round.answer.russianName,
                          answer: round.answer,
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  _OptionState _optionState(TermData option) {
    if (_picked == null) return _OptionState.idle;
    final isAnswer = option.russianName == _round!.answer.russianName;
    if (isAnswer) return _OptionState.correct;
    if (option.russianName == _picked!.russianName) return _OptionState.wrong;
    return _OptionState.idle;
  }
}

enum _OptionState { idle, correct, wrong }

class _HintCard extends StatelessWidget {
  final int index;
  final String text;

  const _HintCard({required this.index, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2114),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD0A24C).withAlpha(110)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$index',
            style: const TextStyle(
              color: Color(0xFFD0A24C),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFFF3E7D0),
                fontSize: 12.5,
                height: 1.4,
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
  final _OptionState state;
  final VoidCallback onTap;

  const _OptionTile({
    required this.label,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    late final Color border;
    late final Color fill;
    switch (state) {
      case _OptionState.correct:
        border = const Color(0xFF7FC97F);
        fill = const Color(0xFF7FC97F).withAlpha(30);
      case _OptionState.wrong:
        border = const Color(0xFFE5836B);
        fill = const Color(0xFFE5836B).withAlpha(30);
      case _OptionState.idle:
        border = const Color(0xFFD0A24C).withAlpha(90);
        fill = const Color(0xFF2A2114);
    }

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: state == _OptionState.idle ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFF3E7D0),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (state == _OptionState.correct)
              const Icon(Icons.check_circle_rounded,
                  size: 18, color: Color(0xFF7FC97F)),
            if (state == _OptionState.wrong)
              const Icon(Icons.cancel_rounded,
                  size: 18, color: Color(0xFFE5836B)),
          ],
        ),
      ),
    );
  }
}

class _RevealCard extends StatelessWidget {
  final bool correct;
  final TermData answer;

  const _RevealCard({required this.correct, required this.answer});

  @override
  Widget build(BuildContext context) {
    return JohnParchmentPanel(
      room: JohnSchoolRoom.flavorLab,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            correct
                ? 'Точно. ${answer.russianName}'
                : 'Это был ${answer.russianName}',
            style: const TextStyle(
              color: Color(0xFF3C2718),
              fontFamily: 'serif',
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            answer.definition,
            style: const TextStyle(
              color: Color(0xFF4A3524),
              fontSize: 13,
              height: 1.45,
            ),
          ),
          if (answer.example.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Пример: ${answer.example}',
              style: TextStyle(
                color: const Color(0xFF4A3524).withAlpha(200),
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
