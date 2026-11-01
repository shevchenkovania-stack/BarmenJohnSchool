import 'package:flutter/material.dart';
import 'package:coin/core/theme/app_theme.dart';
import 'package:coin/features/cocktail_builder/models/generated_cocktail.dart';

class MetricsPanel extends StatelessWidget {
  final GeneratedCocktail cocktail;

  const MetricsPanel({required this.cocktail});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.analytics_rounded,
                    color: AppColors.primary, size: 16),
              ),
              const SizedBox(width: 10),
              const Text(
                'Профиль коктейля',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MetricItem(
                  icon: Icons.local_bar_rounded,
                  label: 'ABV',
                  value: '${cocktail.abv.toStringAsFixed(1)}%',
                  sublabel: cocktail.strengthCategory,
                  color: cocktail.abv > 20
                      ? Colors.redAccent
                      : cocktail.abv > 10
                          ? Colors.orangeAccent
                          : Colors.green,
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: AppColors.textSecondary.withOpacity(0.15),
              ),
              Expanded(
                child: _MetricItem(
                  icon: Icons.cake_rounded,
                  label: 'Сахар',
                  value: '${cocktail.sugarGrams.toStringAsFixed(1)}г',
                  sublabel: cocktail.sweetnessCategory,
                  color: cocktail.sugarGrams > 20
                      ? Colors.pinkAccent
                      : cocktail.sugarGrams > 10
                          ? Colors.amber
                          : Colors.teal,
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: AppColors.textSecondary.withOpacity(0.15),
              ),
              Expanded(
                child: _MetricItem(
                  icon: Icons.local_fire_department_rounded,
                  label: 'Калории',
                  value: cocktail.calories > 0 ? '~${cocktail.calories}' : '-',
                  sublabel: 'ккал',
                  color: Colors.deepOrangeAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Общий объём: ${cocktail.totalVolumeMl.round()} мл',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (cocktail.abv > 0)
                  Text(
                    '~${cocktail.standardDrinks.toStringAsFixed(1)} стандартных порций',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
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

class _MetricItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String sublabel;
  final Color color;

  const _MetricItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.sublabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          sublabel,
          style: TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class AllergenWarning extends StatelessWidget {
  final List<String> allergens;

  const AllergenWarning({required this.allergens});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orangeAccent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orangeAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: Colors.orangeAccent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '⚠️ Содержит аллергены:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.orangeAccent,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: allergens
                      .map((a) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orangeAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.orangeAccent.withOpacity(0.25)),
                            ),
                            child: Text(
                              a,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.orangeAccent,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}