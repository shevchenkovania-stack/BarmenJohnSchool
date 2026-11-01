import 'package:flutter/material.dart';
import 'package:coin/core/theme/app_theme.dart';

/// Универсальный виджет фильтров для коктейлей.
///
/// Используется в:
/// - Поиске
/// - Главном меню
/// - Гостевом режиме
///
/// Фильтры:
/// - Category (Ordinary/Shot/Coffee etc.)
/// - Alcoholic (Alcoholic/Non alcoholic)
/// - Glass (Highball/Cocktail glass etc.)
class FilterBar extends StatelessWidget {
  final String? selectedCategory;
  final String? selectedAlcoholic;
  final String? selectedGlass;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onAlcoholicChanged;
  final ValueChanged<String?> onGlassChanged;
  final Set<String> categories;
  final Set<String> alcoholicTypes;
  final Set<String> glassTypes;

  const FilterBar({
    super.key,
    this.selectedCategory,
    this.selectedAlcoholic,
    this.selectedGlass,
    required this.onCategoryChanged,
    required this.onAlcoholicChanged,
    required this.onGlassChanged,
    required this.categories,
    required this.alcoholicTypes,
    required this.glassTypes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          // Row 1: Category
          _FilterRow(
            label: 'Категория',
            options: categories.toList()..sort(),
            selected: selectedCategory,
            onSelected: onCategoryChanged,
          ),
          const SizedBox(height: 8),

          // Row 2: Alcoholic
          _FilterRow(
            label: 'Тип',
            options: alcoholicTypes.toList()..sort(),
            selected: selectedAlcoholic,
            onSelected: onAlcoholicChanged,
          ),
          const SizedBox(height: 8),

          // Row 3: Glass
          _FilterRow(
            label: 'Бокал',
            options: glassTypes.toList()..sort(),
            selected: selectedGlass,
            onSelected: onGlassChanged,
          ),
        ],
      ),
    );
  }
}

// ─── Одна строка фильтров ─────────────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  final String label;
  final List<String> options;
  final String? selected;
  final ValueChanged<String?> onSelected;

  const _FilterRow({
    required this.label,
    required this.options,
    this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Label
          Text(
            '$label:',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),

          // "All" option
          _FilterChip(
            label: 'Все',
            isSelected: selected == null,
            onSelected: () => onSelected(null),
          ),

          // Options
          ...options.map((opt) => Padding(
                padding: const EdgeInsets.only(left: 4),
                child: _FilterChip(
                  label: opt,
                  isSelected: selected == opt,
                  onSelected: () => onSelected(opt),
                ),
              )),
        ],
      ),
    );
  }
}

// ─── Чип фильтра ──────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
