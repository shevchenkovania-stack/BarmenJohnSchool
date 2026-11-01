import 'package:flutter/material.dart';
import 'package:coin/core/theme/app_theme.dart';

class IngredientChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onRemove;
  final Color color;
  final bool isCustom;

  const IngredientChip({
    required this.label,
    required this.selected,
    required this.onToggle,
    this.onRemove,
    required this.color,
    this.isCustom = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? color : color.withOpacity(0.3),
          width: selected ? 2 : 1,
        ),
        color: selected ? color.withOpacity(0.12) : Colors.transparent,
        boxShadow: selected
            ? [
                BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ]
            : null,
      ),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? color : AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis),
            ),
            if (isCustom && onRemove != null) ...[
              const SizedBox(width: 4),
              InkWell(
                onTap: onRemove,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(Icons.close_rounded,
                      size: 14,
                      color: AppColors.textSecondary.withOpacity(0.7)),
                ),
              ),
            ],
          ],
        ),
        selected: selected,
        onSelected: onToggle,
        backgroundColor: Colors.transparent,
        selectedColor: Colors.transparent,
        checkmarkColor: color,
        elevation: 0,
        pressElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
