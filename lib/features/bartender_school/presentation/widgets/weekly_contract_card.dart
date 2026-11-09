import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:coin/features/bartender_school/data/weekly_contract.dart';
import 'package:coin/features/bartender_school/presentation/widgets/john_school_visuals.dart';

/// Недельный договор с Джоном на главной.
///
/// Три условия на календарную неделю. Награда — история из жизни бара,
/// а не XP: смысл в том, чтобы ученик дошёл до конца недели ритмично.
class WeeklyContractCard extends StatelessWidget {
  const WeeklyContractCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WeeklyContractService>(
      builder: (context, contract, _) {
        final items = contract.items;
        final doneCount = items.where((i) => i.isComplete).length;

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2B2416), Color(0xFF3C3120)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFC8A45C).withAlpha(170)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.handshake_outlined,
                    size: 16,
                    color: Color(0xFFC8A45C),
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'ДОГОВОР НА НЕДЕЛЮ',
                      style: TextStyle(
                        color: Color(0xFFC8A45C),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  Text(
                    '$doneCount/${items.length}',
                    style: const TextStyle(
                      color: Color(0xFFC8A45C),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              for (final item in items) ...[
                _ContractRow(item: item),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 2),
              if (contract.isClaimed)
                _ClaimedBlock(story: contract.claimedStory)
              else if (contract.isComplete)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final story = await contract.claim();
                      if (!context.mounted || story == null) return;
                      await showDialog<void>(
                        context: context,
                        builder: (_) => _StoryDialog(story: story),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC8A45C),
                      foregroundColor: const Color(0xFF241A0A),
                    ),
                    child: const Text(
                      'Забрать историю',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                )
              else
                Text(
                  'Награда — история из жизни бара. Не про XP.',
                  style: TextStyle(
                    color: const Color(0xFFF3E7D0).withAlpha(150),
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ContractRow extends StatelessWidget {
  final ContractItem item;

  const _ContractRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final done = item.isComplete;
    return Row(
      children: [
        Icon(
          done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
          size: 15,
          color: done ? const Color(0xFF7FC97F) : const Color(0xFFC8A45C),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            item.title,
            style: TextStyle(
              color: const Color(0xFFF3E7D0).withAlpha(done ? 160 : 235),
              fontSize: 12,
              height: 1.3,
              decoration: done ? TextDecoration.lineThrough : null,
              decorationColor: const Color(0xFFF3E7D0).withAlpha(120),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${item.done}/${item.target}',
          style: TextStyle(
            color: done
                ? const Color(0xFF7FC97F)
                : const Color(0xFFC8A45C).withAlpha(220),
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ClaimedBlock extends StatelessWidget {
  final ContractStory? story;

  const _ClaimedBlock({this.story});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF7FC97F).withAlpha(24),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF7FC97F).withAlpha(90)),
      ),
      child: Text(
        story == null
            ? 'Договор закрыт. Новая неделя — новые условия.'
            : 'История открыта: «${story!.title}». Забрать дважды нельзя.',
        style: const TextStyle(
          color: Color(0xFFBFE8BF),
          fontSize: 11,
          height: 1.3,
        ),
      ),
    );
  }
}

class _StoryDialog extends StatelessWidget {
  final ContractStory story;

  const _StoryDialog({required this.story});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: JohnParchmentPanel(
        room: JohnSchoolRoom.classicsLounge,
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                story.title,
                style: const TextStyle(
                  color: Color(0xFF3C2718),
                  fontFamily: 'serif',
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                story.text,
                style: const TextStyle(
                  color: Color(0xFF4A3524),
                  fontSize: 13.5,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9D6B2C),
                    foregroundColor: const Color(0xFFFFF3D8),
                  ),
                  child: const Text('Спасибо, Джон'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
