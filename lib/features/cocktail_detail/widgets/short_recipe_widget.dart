import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coin/core/models/cocktail.dart';
import 'package:coin/core/services/short_recipe_service.dart';
import 'package:coin/core/theme/app_theme.dart';
import 'package:coin/core/services/measurement_service.dart';

/// Виджет короткого AI рецепта
class ShortRecipeWidget extends StatefulWidget {
  final Cocktail cocktail;

  const ShortRecipeWidget({
    super.key,
    required this.cocktail,
  });

  @override
  State<ShortRecipeWidget> createState() => _ShortRecipeWidgetState();
}

class _ShortRecipeWidgetState extends State<ShortRecipeWidget> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Provider.of<ShortRecipeService>(context, listen: false).getRecipe(
          widget.cocktail,
          measurementService: context.watch<MeasurementService>()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final recipe = snapshot.data;
        if (recipe == null || recipe.steps.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withAlpha(20),
                AppColors.primary.withAlpha(5),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withAlpha(50)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.flash_on,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Короткий рецепт',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...recipe.steps.asMap().entries.map((entry) {
                final index = entry.key;
                final step = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          step,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }
}
