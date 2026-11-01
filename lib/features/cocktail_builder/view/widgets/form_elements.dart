import 'package:flutter/material.dart';
import 'package:coin/core/theme/app_theme.dart';
import 'package:coin/features/cocktail_builder/models/cocktail_types.dart';

class CategoryButton extends StatelessWidget {
  final CocktailCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryButton({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? category.accentColor.withOpacity(0.2)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? category.accentColor : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              category.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color:
                    isSelected ? category.accentColor : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              category.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: isSelected
                    ? AppColors.textSecondary
                    : AppColors.textSecondary.withAlpha(150),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DropdownTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const DropdownTile({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  String get _safeValue => items.contains(value) ? value : items.first;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.textSecondary.withOpacity(0.15)),
      ),
      child: DropdownButtonFormField<String>(
        value: _safeValue,
        decoration: InputDecoration(
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        ),
        dropdownColor: AppColors.background,
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        icon: Icon(Icons.arrow_drop_down_rounded,
            color: AppColors.textSecondary.withOpacity(0.7)),
        items: items
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(item, style: const TextStyle(fontSize: 14)),
                  ),
                ))
            .toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}