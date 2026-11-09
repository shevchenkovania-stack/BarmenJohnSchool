import 'package:flutter/material.dart';

import 'package:coin/features/bartender_school/data/quest_flow.dart';
import 'package:coin/features/bartender_school/presentation/widgets/john_school_visuals.dart';

/// Расследование: три вопроса гостю и факты, которые из них следуют.
///
/// Ключевое отличие от простого списка кнопок: факт появляется **под**
/// вопросом, который его открыл, и остаётся там. Игрок видит, откуда он
/// знает то, что знает. Отдельного экрана журнала нет — он не нужен.
///
/// Вопрос можно задать один раз: повтор не добавляет факт.
class QuestInvestigationView extends StatefulWidget {
  final QuestInvestigation investigation;
  final JohnSchoolRoom room;

  /// Вызывается, когда задан новый вопрос: счётчик и лента читаются сверху.
  final void Function(int evidenceCount)? onProgress;

  /// Ушёл ли игрок дальше. `null` — сцена листает сама.
  final VoidCallback? onContinue;

  const QuestInvestigationView({
    super.key,
    required this.investigation,
    this.room = JohnSchoolRoom.flavorLab,
    this.onProgress,
    this.onContinue,
  });

  @override
  State<QuestInvestigationView> createState() => _QuestInvestigationViewState();
}

class _QuestInvestigationViewState extends State<QuestInvestigationView> {
  final Set<String> _asked = <String>{};

  int get _count => _asked.length;
  int get _total => widget.investigation.items.length;
  bool get _done => _count >= _total;

  void _ask(QuestEvidenceItem item) {
    if (_asked.contains(item.id)) return;
    setState(() => _asked.add(item.id));
    widget.onProgress?.call(_count);
  }

  @override
  Widget build(BuildContext context) {
    final style = JohnRoomStyle.forRoom(widget.room);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: JohnWoodPanel(
        room: widget.room,
        highlighted: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.investigation.instruction,
              style: TextStyle(
                fontSize: 15,
                height: 1.55,
                fontFamily: 'serif',
                color: style.onDark.withAlpha(215),
              ),
            ),
            const SizedBox(height: 14),
            _EvidenceCounter(count: _count, total: _total, style: style),
            const SizedBox(height: 18),
            for (final item in widget.investigation.items) ...[
              _QuestionTile(
                key: Key('quest_ask_${item.id}'),
                item: item,
                isAsked: _asked.contains(item.id),
                style: style,
                onTap: () => _ask(item),
              ),
              const SizedBox(height: 10),
            ],
            if (_count > 0 && _count < widget.investigation.hintBelow) ...[
              const SizedBox(height: 6),
              _Hint(
                text: widget.investigation.hintText,
                style: style,
              ),
            ],
            if (widget.onContinue != null) ...[
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  key: const Key('quest_investigation_continue'),
                  onPressed: widget.onContinue,
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(_done ? 'Всё выяснено' : 'Хватит вопросов'),
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
          ],
        ),
      ),
    );
  }
}

/// Счётчик фактов: «1 из 3».
class _EvidenceCounter extends StatelessWidget {
  final int count;
  final int total;
  final JohnRoomStyle style;

  const _EvidenceCounter({
    required this.count,
    required this.total,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const Key('quest_evidence_counter'),
      children: [
        Icon(Icons.fact_check_outlined, size: 15, color: style.accent),
        const SizedBox(width: 8),
        Text(
          'Фактов: $count из $total',
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 0.6,
            fontWeight: FontWeight.w800,
            color: style.accent.withAlpha(220),
          ),
        ),
      ],
    );
  }
}

/// Один вопрос. Пока не задан — кнопка; после — ответ гостя и факт.
class _QuestionTile extends StatelessWidget {
  final QuestEvidenceItem item;
  final bool isAsked;
  final JohnRoomStyle style;
  final VoidCallback onTap;

  const _QuestionTile({
    super.key,
    required this.item,
    required this.isAsked,
    required this.style,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!isAsked) {
      return Material(
        color: style.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: style.accent.withAlpha(110)),
            ),
            child: Row(
              children: [
                Icon(Icons.help_outline, size: 17, color: style.accent),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 14.5,
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
      );
    }

    // Заданный вопрос остаётся в ленте: ответ и факт видны сразу.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: style.surface.withAlpha(190),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: style.accent.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.label,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.35,
              fontStyle: FontStyle.italic,
              color: style.onDark.withAlpha(150),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '— ${item.response}',
            style: TextStyle(
              fontSize: 15,
              height: 1.45,
              color: style.onDark,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            key: Key('quest_evidence_${item.id}'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.check_circle_outline,
                  size: 14, color: style.accent.withAlpha(200)),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  item.evidenceText,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: style.onDark.withAlpha(185),
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

/// Подсказка: рано делать вывод.
class _Hint extends StatelessWidget {
  final String text;
  final JohnRoomStyle style;

  const _Hint({required this.text, required this.style});

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    return Container(
      key: const Key('quest_evidence_hint'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: style.accent.withAlpha(24),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: style.accent.withAlpha(80)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, size: 15, color: style.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: style.onDark.withAlpha(200),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
