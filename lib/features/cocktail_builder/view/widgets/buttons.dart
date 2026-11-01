import 'package:flutter/material.dart';
import 'package:coin/core/theme/app_theme.dart';

enum ActionButtonStyle { filled, outlined }

class GenerateButton extends StatelessWidget {
  final bool isGenerating;
  final VoidCallback? onPressed;

  const GenerateButton({required this.isGenerating, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton.icon(
          icon: isGenerating
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                )
              : const Icon(Icons.auto_awesome_rounded, size: 24),
          label: Text(
            isGenerating ? 'Проверяю сборку...' : '✨ ПРОВЕРИТЬ СБОРКУ',
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.5),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24),
          ),
          onPressed: onPressed,
        ),
      ),
    );
  }
}

class ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final ActionButtonStyle style;
  final Color color;
  final VoidCallback onPressed;

  const ActionButton({
    required this.icon,
    required this.label,
    required this.style,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isFilled = style == ActionButtonStyle.filled;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: isFilled
          ? ElevatedButton.icon(
              icon: Icon(icon, size: 22),
              label: Text(label,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: color.withOpacity(0.4),
              ),
              onPressed: onPressed,
            )
          : OutlinedButton.icon(
              icon: Icon(icon, size: 22),
              label: Text(label,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ),
              onPressed: onPressed,
            ),
    );
  }
}
