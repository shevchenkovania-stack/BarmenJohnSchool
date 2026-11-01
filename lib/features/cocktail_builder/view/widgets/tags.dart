import 'package:flutter/material.dart';
import 'package:coin/core/theme/app_theme.dart';

class Tag extends StatelessWidget {
  final String label;
  final String emoji;
  final Color color;

  const Tag({required this.label, required this.emoji, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class IngChip extends StatelessWidget {
  final String name;
  final Color color;
  final bool isMuted;

  const IngChip({
    required this.name,
    required this.color,
    this.isMuted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isMuted
            ? AppColors.textSecondary.withOpacity(0.08)
            : color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isMuted
              ? AppColors.textSecondary.withOpacity(0.2)
              : color.withOpacity(0.25),
        ),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isMuted ? AppColors.textSecondary : AppColors.textPrimary,
        ),
      ),
    );
  }
}