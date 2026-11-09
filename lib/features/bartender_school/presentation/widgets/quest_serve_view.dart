import 'package:flutter/material.dart';

import 'package:coin/features/bartender_school/data/quest_flow.dart';
import 'package:coin/features/bartender_school/presentation/widgets/john_school_visuals.dart';
import 'package:coin/features/bartender_school/presentation/widgets/quest_investigation_view.dart';

/// Подача: один осмысленный выбор и, если ошибся, одна повторная попытка.
///
/// Правила спека, которые здесь важны:
/// - при первой ошибке **не показываем реакцию гостя** — сначала Джон;
/// - после реплики Джона можно вернуться к фактам и выбрать снова;
/// - третьей попытки нет;
/// - правильный ответ с первой попытки закрывает сцену сразу.
class QuestServeView extends StatefulWidget {
  final QuestFlow flow;
  final JohnSchoolRoom room;

  /// Чем кончилось: финал и выбранный вариант последней попытки.
  final void Function(QuestEnding ending, QuestServeOption option)? onFinished;

  /// Уйти дальше. `null` — дальше некуда.
  final VoidCallback? onContinue;

  const QuestServeView({
    super.key,
    required this.flow,
    this.room = JohnSchoolRoom.flavorLab,
    this.onFinished,
    this.onContinue,
  });

  @override
  State<QuestServeView> createState() => _QuestServeViewState();
}

class _QuestServeViewState extends State<QuestServeView> {
  late QuestFlowState _state = QuestFlowState(widget.flow);

  /// Открыта ли лента вопросов для пересмотра фактов.
  bool _reviewing = false;

  @override
  void didUpdateWidget(QuestServeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.flow.id != widget.flow.id) {
      setState(() {
        _state = QuestFlowState(widget.flow);
        _reviewing = false;
      });
    }
  }

  void _pick(QuestServeOption option) {
    final picked = _state.serve(option.id);
    if (picked == null) return;
    setState(() => _reviewing = false);
    // Финал считается только когда попытки кончились или ответ верный.
    final done = picked.isCorrect || !_state.canCorrect;
    if (done) {
      widget.onFinished?.call(_state.ending!, picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = JohnRoomStyle.forRoom(widget.room);
    final last = _state.lastOption;
    final isClosed = last != null && (last.isCorrect || !_state.canCorrect);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: JohnWoodPanel(
        room: widget.room,
        highlighted: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _EvidenceSummary(state: _state, style: style),
            const SizedBox(height: 16),

            // ── Сцена закрыта: реакция гостя и вывод Джона ────────────────
            if (isClosed) ...[
              _GuestReaction(option: last, style: style),
              const SizedBox(height: 14),
              _JohnComment(text: last.johnComment, style: style),
              const SizedBox(height: 12),
              _EndingBadge(ending: _state.ending!, style: style),
              if (widget.onContinue != null) ...[
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    key: const Key('quest_serve_continue'),
                    onPressed: widget.onContinue,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Дальше'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: style.accent,
                      foregroundColor: style.ink,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ]

            // ── Первая ошибка: Джон вместо гостя ─────────────────────────
            else if (last != null) ...[
              _JohnComment(text: widget.flow.serve.johnPrompt, style: style),
              const SizedBox(height: 14),
              if (_reviewing) ...[
                QuestInvestigationView(
                  investigation: widget.flow.investigation,
                  room: widget.room,
                ),
                const SizedBox(height: 14),
              ] else
                OutlinedButton.icon(
                  key: const Key('quest_review_evidence'),
                  onPressed: () => setState(() => _reviewing = true),
                  icon: const Icon(Icons.fact_check_outlined, size: 17),
                  label: const Text('Пересмотреть факты'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: style.accent,
                    side: BorderSide(color: style.accent.withAlpha(120)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              const SizedBox(height: 18),
              _ServeButtons(
                options: widget.flow.serve.options,
                pickedId: last.id,
                style: style,
                onPick: _pick,
              ),
            ]

            // ── Первый выбор ─────────────────────────────────────────────
            else ...[
              Text(
                widget.flow.serve.instruction,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.55,
                  fontFamily: 'serif',
                  color: style.onDark.withAlpha(215),
                ),
              ),
              const SizedBox(height: 16),
              _ServeButtons(
                options: widget.flow.serve.options,
                pickedId: null,
                style: style,
                onPick: _pick,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Что известно: сколько фактов собрано и о чём они.
class _EvidenceSummary extends StatelessWidget {
  final QuestFlowState state;
  final JohnRoomStyle style;

  const _EvidenceSummary({required this.state, required this.style});

  @override
  Widget build(BuildContext context) {
    final asked = state.askedItems;
    if (asked.isEmpty) {
      return Container(
        key: const Key('quest_evidence_summary'),
        width: double.infinity,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: style.accent.withAlpha(22),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: style.accent.withAlpha(75)),
        ),
        child: Text(
          'Ты не спросил ни слова. Решать можно и так — но тогда решение '
          'будет на догадке, а не на словах гостя.',
          style: TextStyle(
            fontSize: 13.5,
            height: 1.5,
            color: style.onDark.withAlpha(200),
          ),
        ),
      );
    }

    return Container(
      key: const Key('quest_evidence_summary'),
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: style.surface.withAlpha(180),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: style.accent.withAlpha(70)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ты знаешь ${asked.length} из ${state.flow.investigation.items.length}',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w800,
              color: style.accent,
            ),
          ),
          const SizedBox(height: 8),
          for (final item in asked)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text(
                '· ${item.evidenceText}',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: style.onDark.withAlpha(190),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Кнопки вариантов подачи.
class _ServeButtons extends StatelessWidget {
  final List<QuestServeOption> options;

  /// Уже выбранный вариант — его помечаем, остальные гасим.
  final String? pickedId;
  final JohnRoomStyle style;
  final void Function(QuestServeOption) onPick;

  const _ServeButtons({
    required this.options,
    required this.pickedId,
    required this.style,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final o in options)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: pickedId == o.id
                  ? style.surface.withAlpha(120)
                  : style.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                key: Key('quest_serve_${o.id}'),
                borderRadius: BorderRadius.circular(12),
                onTap: pickedId == o.id ? null : () => onPick(o),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: style.accent
                          .withAlpha(pickedId != null && pickedId != o.id ? 40 : 115),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        pickedId == o.id
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        size: 18,
                        color: style.accent
                            .withAlpha(pickedId != null && pickedId != o.id ? 70 : 200),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          o.text,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                            color: pickedId != null && pickedId != o.id
                                ? style.onDark.withAlpha(110)
                                : style.onDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Реакция гостя. Не похвала: он может допить и промолчать.
class _GuestReaction extends StatelessWidget {
  final QuestServeOption option;
  final JohnRoomStyle style;

  const _GuestReaction({required this.option, required this.style});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('quest_guest_reaction'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: style.surfaceLight,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(14),
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(14),
        ),
        border: Border.all(color: style.accent.withAlpha(95)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ГОСТЬ',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w800,
              color: style.accent,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            option.guestReaction,
            style: TextStyle(
              fontSize: 15.5,
              height: 1.55,
              color: style.onDark,
            ),
          ),
        ],
      ),
    );
  }
}

/// Слова Джона.
class _JohnComment extends StatelessWidget {
  final String text;
  final JohnRoomStyle style;

  const _JohnComment({required this.text, required this.style});

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    return Container(
      key: const Key('quest_john_comment'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: style.accent.withAlpha(26),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: style.accent.withAlpha(90)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ДЖОН',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w900,
              color: style.accent,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 14.5,
              height: 1.55,
              fontFamily: 'serif',
              color: style.onDark,
            ),
          ),
        ],
      ),
    );
  }
}

/// Чем кончился квест — короткой меткой.
class _EndingBadge extends StatelessWidget {
  final QuestEnding ending;
  final JohnRoomStyle style;

  const _EndingBadge({required this.ending, required this.style});

  @override
  Widget build(BuildContext context) {
    final (label, icon) = switch (ending) {
      QuestEnding.complete => ('Ты услышал гостя', Icons.nightlight_round),
      QuestEnding.partial => ('Ты почти всё понял', Icons.wb_twilight),
      QuestEnding.recovered => ('Ты исправил ошибку', Icons.replay),
      QuestEnding.incomplete => ('История осталась неразгаданной', Icons.help_outline),
    };
    return Row(
      key: const Key('quest_ending'),
      children: [
        Icon(icon, size: 15, color: style.accent.withAlpha(210)),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w800,
            color: style.accent.withAlpha(220),
          ),
        ),
      ],
    );
  }
}
