import 'package:flutter/material.dart';
import 'package:coin/features/bartender_school/presentation/widgets/john_school_visuals.dart';

/// Section header for lesson blocks (A, B, C).
class BlockHeader extends StatelessWidget {
  final String blockId;
  final String title;
  final String lessonRange;

  const BlockHeader({
    super.key,
    required this.blockId,
    required this.title,
    required this.lessonRange,
  });

  @override
  Widget build(BuildContext context) {
    final room = JohnRoomStyle.roomForBlock(blockId);
    final style = JohnRoomStyle.forRoom(room);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          // Block letter badge
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [style.accent, style.accentSoft],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: style.onDark.withAlpha(130)),
              boxShadow: [
                BoxShadow(
                  color: style.accent.withAlpha(125),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                blockId,
                style: TextStyle(
                  color: style.ink,
                  fontFamily: 'serif',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Title and range
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: style.onDark,
                    fontFamily: 'serif',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Уроки $lessonRange',
                  style: TextStyle(
                    color: style.onDark.withAlpha(180),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
