import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:coin/core/models/cocktail.dart';
import 'package:coin/core/theme/app_theme.dart';
import 'package:coin/features/bar_manager/can_make/models/cocktail_with_availability.dart';

/// Плитка коктейля с отображением доступных/отсутствующих ингредиентов.
///
/// Формат:
/// ```
/// ┌─────────────────────────────────────┐
/// │  🍸 Margarita                       │
/// │  [Картинка]                         │
/// │                                     │
/// │  Ингредиенты:                       │
/// │  ✅ Tequila 50ml                    │
/// │  ❌ Lime juice (нет в наличии)      │
/// └─────────────────────────────────────┘
/// ```
class CocktailWithIngredientsTile extends StatelessWidget {
  final CocktailWithAvailability cocktailWithAvailability;
  final VoidCallback? onTap;

  const CocktailWithIngredientsTile({
    super.key,
    required this.cocktailWithAvailability,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cwa = cocktailWithAvailability;
    final cocktail = cwa.cocktail;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок с картинкой
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Картинка коктейля
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: cocktail.strDrinkThumb,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        width: 60,
                        height: 60,
                        color: AppColors.shimmerBase,
                        child: const Icon(Icons.local_bar,
                            color: AppColors.primary),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 60,
                        height: 60,
                        color: AppColors.shimmerBase,
                        child: const Icon(Icons.local_bar,
                            color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Название и статус
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cocktail.strDrink,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Статус
                        _buildStatusChip(cwa),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Ингредиенты
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ингредиенты:',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Список ингредиентов
                  ..._buildIngredientRows(cwa),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Построить строки ингредиентов
  List<Widget> _buildIngredientRows(CocktailWithAvailability cwa) {
    final widgets = <Widget>[];

    // Сначала доступные (зелёные)
    for (int i = 0; i < cwa.availableIngredients.length; i++) {
      final ingredient = cwa.availableIngredients[i];
      final measure =
          cwa.cocktail.measures.isNotEmpty && i < cwa.cocktail.measures.length
              ? cwa.cocktail.measures[i]
              : '';

      widgets.add(_IngredientRow(
        name: ingredient,
        measure: measure,
        isAvailable: true,
      ));
    }

    // Затем отсутствующие (красные/серые)
    for (int i = 0; i < cwa.missingIngredients.length; i++) {
      final ingredient = cwa.missingIngredients[i];

      widgets.add(_IngredientRow(
        name: ingredient,
        measure: '',
        isAvailable: false,
      ));
    }

    return widgets;
  }

  /// Чип статуса
  Widget _buildStatusChip(CocktailWithAvailability cwa) {
    if (cwa.canMakeNow) {
      return Chip(
        avatar: const Icon(Icons.check_circle, size: 14, color: Colors.green),
        label: const Text(
          'Можно сделать',
          style: TextStyle(fontSize: 11, color: Colors.green),
        ),
        backgroundColor: Colors.green.withAlpha(20),
        padding: EdgeInsets.zero,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );
    } else {
      return Chip(
        avatar: const Icon(Icons.warning, size: 14, color: Colors.orange),
        label: Text(
          'Нет ${cwa.missingCount} шт.',
          style: const TextStyle(fontSize: 11, color: Colors.orange),
        ),
        backgroundColor: Colors.orange.withAlpha(20),
        padding: EdgeInsets.zero,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );
    }
  }
}

/// Строка одного ингредиента
class _IngredientRow extends StatelessWidget {
  final String name;
  final String measure;
  final bool isAvailable;

  const _IngredientRow({
    required this.name,
    this.measure = '',
    required this.isAvailable,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          // Иконка статуса
          Icon(
            isAvailable ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 14,
            color: isAvailable ? Colors.green : Colors.grey.shade400,
          ),
          const SizedBox(width: 8),
          // Название
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 14, // Увеличено с 13 до 14 для читабельности
                color: isAvailable
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                decoration: isAvailable ? null : TextDecoration.lineThrough,
              ),
            ),
          ),
          // Объём (если есть)
          if (measure.isNotEmpty)
            Text(
              measure,
              style: TextStyle(
                fontSize: 11,
                color: isAvailable
                    ? AppColors.textSecondary
                    : Colors.grey.shade500,
              ),
            ),
        ],
      ),
    );
  }
}
