import 'package:flutter/material.dart';

import 'package:coin/features/bartender_school/data/quest_scene.dart';
import 'package:coin/features/bartender_school/presentation/widgets/john_school_visuals.dart';
import 'package:coin/features/bartender_school/presentation/widgets/typewriter_text.dart';

/// Сцена-квест: титры, гость и выбор, который закрывает разговор.
///
/// Не аккордеон: вопрос задаётся один раз, финальное действие отменяет
/// остальные варианты и не даёт выбрать второй раз.
class QuestSceneView extends StatefulWidget {
  final QuestScene scene;
  final JohnSchoolRoom room;

  /// Что произошло после финала. Вызывается один раз на выбор.
  final void Function(QuestOption option)? onFinished;

  /// Можно ли уйти дальше. Сцена сама решает, когда разговор закрыт.
  final VoidCallback? onContinue;

  const QuestSceneView({
    super.key,
    required this.scene,
    this.room = JohnSchoolRoom.flavorLab,
    this.onFinished,
    this.onContinue,
  });

  @override
  State<QuestSceneView> createState() => _QuestSceneViewState();
}

class _QuestSceneViewState extends State<QuestSceneView> {
  late QuestSceneState _state = QuestSceneState(widget.scene);

  /// Реплики показываются по одной: каждое новое сообщение — шаг сцены.
  int _beatsShown = 0;
  bool _typingDone = false;

  @override
  void initState() {
    super.initState();
    _beatsShown = widget.scene.beats.isEmpty ? 0 : 1;
  }

  @override
  void didUpdateWidget(QuestSceneView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scene.id != widget.scene.id) {
      setState(() {
        _state = QuestSceneState(widget.scene);
        _beatsShown = widget.scene.beats.isEmpty ? 0 : 1;
        _typingDone = false;
      });
    }
  }

  bool get _hasMoreBeats => _beatsShown < widget.scene.beats.length;

  void _nextBeat() {
    if (!_hasMoreBeats) return;
    setState(() {
      _beatsShown++;
      _typingDone = false;
    });
  }

  void _ask(QuestProbe probe) {
    setState(() {
      _state.ask(probe.id);
      _typingDone = false;
    });
  }

  void _choose(QuestOption option) {
    final picked = _state.choose(option.id);
    if (picked == null) return;
    setState(() => _typingDone = false);
    widget.onFinished?.call(picked);
  }

  @override
  Widget build(BuildContext context) {
    final style = JohnRoomStyle.forRoom(widget.room);
    final ink = style.onDark;
    final muted = style.onDark.withAlpha(185);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: JohnWoodPanel(
        room: widget.room,
        highlighted: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TitleBlock(
              scene: widget.scene,
              accent: style.accent,
              ink: ink,
              muted: muted,
            ),
            const SizedBox(height: 18),
            ..._buildBeats(style),
            if (_hasMoreBeats) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  key: const Key('quest_next_beat'),
                  onPressed: _nextBeat,
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('Дальше'),
                  style: TextButton.styleFrom(foregroundColor: style.accent),
                ),
              ),
            ] else ...[
              const SizedBox(height: 16),
              ..._buildDialogue(style),
              const SizedBox(height: 16),
              ..._buildAnswers(style),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBeats(JohnRoomStyle style) {
    final beats = widget.scene.beats.take(_beatsShown).toList();
    return [
      for (var i = 0; i < beats.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _BeatBubble(
            // Ключ по индексу: иначе вторая реплика переиспользует
            // State первой и появляется сразу целиком, без печати.
            key: ValueKey('beat_$i'),
            beat: beats[i],
            style: style,
            animate: i == beats.length - 1 && !_typingDone,
            onTyped: () {
              if (mounted) setState(() => _typingDone = true);
            },
          ),
        ),
    ];
  }

  List<Widget> _buildDialogue(JohnRoomStyle style) {
    final asked = _state.askedProbes;
    return [
      for (var i = 0; i < asked.length; i++) ...[
        _PlayerLine(text: asked[i].label, style: style),
        const SizedBox(height: 6),
        _BeatBubble(
          key: ValueKey('reply_${asked[i].id}'),
          beat: QuestBeat(speaker: _guestName, text: asked[i].response),
          style: style,
          animate: i == asked.length - 1 && !_typingDone,
          onTyped: () {
            if (mounted) setState(() => _typingDone = true);
          },
        ),
        // Что игрок понял из этого ответа. Без этой строки вопросы
        // читаются как кнопки «дай подсказку»: ответ есть, а вывода нет.
        if (asked[i].insight.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _InsightLine(text: asked[i].insight, style: style),
          ),
        const SizedBox(height: 10),
      ],
    ];
  }

  String get _guestName {
    for (final beat in widget.scene.beats) {
      if (beat.speaker != null && beat.speaker!.isNotEmpty) {
        return beat.speaker!;
      }
    }
    return 'Гость';
  }

  List<Widget> _buildAnswers(JohnRoomStyle style) {
    final picked = _state.picked;

    if (picked != null) {
      return [
        _ResultBlock(
          // Текст реакции решает сцена, а не вариант: за пустой стол
          // и за расспрос гость отвечает по-разному.
          guestReaction: _state.guestReaction,
          johnLesson: _state.johnLesson,
          outcome: _state.outcome,
          style: style,
        ),
        if (widget.onContinue != null) ...[
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: const Key('quest_continue'),
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
      ];
    }

    final probe = _state.availableProbe;
    if (probe != null) {
      return [
        _SectionLabel(
          text: _state.askedProbes.isEmpty
              ? 'Спроси его. Один вопрос — и он ответит.'
              : 'Можно спросить ещё',
          style: style,
        ),
        const SizedBox(height: 10),
        _ProbeButton(
          key: Key('quest_probe_${probe.id}'),
          probe: probe,
          style: style,
          onTap: () => _ask(probe),
        ),
        if (_state.hasQuestionsLeft) ...[
          const SizedBox(height: 10),
          Text(
            'Вопросов осталось: '
            '${widget.scene.probes.length - _state.askedProbes.length}',
            style: TextStyle(fontSize: 12, color: style.onDark.withAlpha(140)),
          ),
        ],
        const SizedBox(height: 20),
        // Сводка того, что игрок уже понял: перед выбором видно, на что
        // он опирается — или что ещё не спросил.
        _InsightSummary(
          insights: _state.insights,
          asked: _state.askedProbes.length,
          total: widget.scene.probes.length,
          style: style,
        ),
        const SizedBox(height: 16),
        _SectionLabel(text: 'Что нальёшь?', style: style),
        const SizedBox(height: 10),
        // Действие доступно сразу: решить можно и вслепую, но тогда гость
        // ответит иначе, а Джон скажет, что осталось неслыханным.
        for (final option in widget.scene.answers)
          _AnswerButton(
            key: Key('quest_answer_${option.id}'),
            option: option,
            style: style,
            onTap: () => _choose(option),
          ),
      ];
    }

    // Вопросы заданы все, но выбора ещё нет.
    return [
      _InsightSummary(
        insights: _state.insights,
        asked: _state.askedProbes.length,
        total: widget.scene.probes.length,
        style: style,
      ),
      const SizedBox(height: 16),
      _SectionLabel(text: 'Ты услышал достаточно. Что нальёшь?', style: style),
      const SizedBox(height: 10),
      for (final option in widget.scene.answers)
        _AnswerButton(
          key: Key('quest_answer_${option.id}'),
          option: option,
          style: style,
          onTap: () => _choose(option),
        ),
    ];
  }
}

// ── Внутренние виджеты ──────────────────────────────────────────────────────

class _TitleBlock extends StatelessWidget {
  final QuestScene scene;
  final Color accent;
  final Color ink;
  final Color muted;

  const _TitleBlock({
    required this.scene,
    required this.accent,
    required this.ink,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 16,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                scene.timeStamp,
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          scene.title,
          style: TextStyle(
            fontSize: 24,
            height: 1.2,
            fontWeight: FontWeight.w900,
            fontFamily: 'serif',
            color: ink,
          ),
        ),
        const SizedBox(height: 6),
        Container(height: 1, color: muted.withAlpha(45)),
      ],
    );
  }
}

/// Реплика: авторский текст без рамки, слова гостя — в рамке.
class _BeatBubble extends StatelessWidget {
  final QuestBeat beat;
  final JohnRoomStyle style;
  final bool animate;
  final VoidCallback onTyped;

  const _BeatBubble({
    super.key,
    required this.beat,
    required this.style,
    required this.animate,
    required this.onTyped,
  });

  @override
  Widget build(BuildContext context) {
    final isAuthor = beat.speaker == null || beat.speaker!.isEmpty;
    final textStyle = TextStyle(
      fontSize: isAuthor ? 15 : 16,
      height: 1.55,
      fontStyle: isAuthor ? FontStyle.italic : FontStyle.normal,
      color: isAuthor ? style.onDark.withAlpha(205) : style.onDark,
    );

    final body = animate
        ? TypewriterText(
            beat.text,
            style: textStyle,
            // Гость не отвечает мгновенно: пауза перед репликой даёт
            // ощущение живого разговора, а не печати готового текста.
            delay: isAuthor ? Duration.zero : const Duration(milliseconds: 420),
            onDone: onTyped,
          )
        : Text(beat.text, style: textStyle);

    if (isAuthor) return body;

    return Container(
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
            beat.speaker ?? 'Гость',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w800,
              color: style.accent,
            ),
          ),
          const SizedBox(height: 6),
          body,
        ],
      ),
    );
  }
}

class _PlayerLine extends StatelessWidget {
  final String text;
  final JohnRoomStyle style;

  const _PlayerLine({required this.text, required this.style});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: style.accent.withAlpha(38),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(14),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(14),
            bottomRight: Radius.circular(14),
          ),
          border: Border.all(color: style.accent.withAlpha(110)),
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 14, height: 1.4, color: style.onDark),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final JohnRoomStyle style;

  const _SectionLabel({required this.text, required this.style});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        letterSpacing: 0.8,
        fontWeight: FontWeight.w800,
        color: style.onDark.withAlpha(160),
      ),
    );
  }
}

class _ProbeButton extends StatelessWidget {
  final QuestProbe probe;
  final JohnRoomStyle style;
  final VoidCallback onTap;

  const _ProbeButton({
    super.key,
    required this.probe,
    required this.style,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: style.surfaceLight,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: style.accent.withAlpha(120)),
          ),
          child: Row(
            children: [
              Icon(Icons.chat_bubble_outline, size: 16, color: style.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  probe.label,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.35,
                    color: style.onDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Вывод игрока из ответа гостя. Отдельная строка с галочкой: это
/// не речь персонажа, а то, что игрок понял сам.
class _InsightLine extends StatelessWidget {
  final String text;
  final JohnRoomStyle style;

  const _InsightLine({required this.text, required this.style});

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const Key('quest_insight'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_circle_outline,
            size: 14, color: style.accent.withAlpha(200)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              fontStyle: FontStyle.italic,
              color: style.onDark.withAlpha(175),
            ),
          ),
        ),
      ],
    );
  }
}

/// Сводка: сколько игрок услышал и что именно.
class _InsightSummary extends StatelessWidget {
  final List<String> insights;
  final int asked;
  final int total;
  final JohnRoomStyle style;

  const _InsightSummary({
    required this.insights,
    required this.asked,
    required this.total,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) return const SizedBox.shrink();
    return Container(
      key: const Key('quest_insight_summary'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: style.surface.withAlpha(150),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: style.accent.withAlpha(70)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ты услышал $asked из $total',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w800,
              color: style.accent,
            ),
          ),
          const SizedBox(height: 8),
          for (final insight in insights)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '· $insight',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: style.onDark.withAlpha(195),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AnswerButton extends StatelessWidget {
  final QuestOption option;
  final JohnRoomStyle style;
  final VoidCallback onTap;

  const _AnswerButton({
    super.key,
    required this.option,
    required this.style,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: style.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: style.accent.withAlpha(115), width: 1.4),
            ),
            child: Row(
              children: [
                Icon(Icons.local_bar_outlined, size: 18, color: style.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    option.text,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                      color: style.onDark,
                    ),
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

/// Реакция гостя + вывод Джона. Не «неверно», а «вот что было».
class _ResultBlock extends StatelessWidget {
  final String guestReaction;
  final String johnLesson;
  final QuestOutcome? outcome;
  final JohnRoomStyle style;

  const _ResultBlock({
    required this.guestReaction,
    required this.johnLesson,
    this.outcome,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('quest_result'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Куда ушла сцена. Это и есть видимое ветвление: разный конец
        // разговора, а не разная оценка.
        if (outcome != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              key: const Key('quest_outcome'),
              children: [
                Icon(
                  outcome == QuestOutcome.stayed
                      ? Icons.nightlight_round
                      : Icons.logout,
                  size: 14,
                  color: style.accent.withAlpha(200),
                ),
                const SizedBox(width: 8),
                Text(
                  outcome!.label,
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w800,
                    color: style.accent.withAlpha(210),
                  ),
                ),
              ],
            ),
          ),
        _BeatBubble(
          beat: QuestBeat(speaker: 'Гость', text: guestReaction),
          style: style,
          animate: false,
          onTyped: () {},
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: style.accent.withAlpha(28),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: style.accent.withAlpha(95)),
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
                johnLesson,
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.55,
                  fontFamily: 'serif',
                  color: style.onDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
