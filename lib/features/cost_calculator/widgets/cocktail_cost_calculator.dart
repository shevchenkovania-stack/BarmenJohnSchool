import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coin/core/models/cocktail.dart';
import 'package:coin/core/theme/app_theme.dart';
import 'package:coin/core/services/cost_calculator_service.dart';

/// Виджет расчёта себестоимости коктейля с калькулятором порций
class CocktailCostCalculator extends StatefulWidget {
  final Cocktail cocktail;

  const CocktailCostCalculator({
    super.key,
    required this.cocktail,
  });

  @override
  State<CocktailCostCalculator> createState() => _CocktailCostCalculatorState();
}

class _CocktailCostCalculatorState extends State<CocktailCostCalculator> {
  int _servings = 1; // Количество порций

  @override
  Widget build(BuildContext context) {
    return Consumer<CostCalculatorService>(
      builder: (context, service, _) {
        // Проверяем есть ли цены для всех ингредиентов
        final missingIngredients =
            service.getMissingIngredients(widget.cocktail.ingredients);

        if (missingIngredients.isNotEmpty) {
          return _MissingPricesWarning(
            ingredients: missingIngredients,
            onSetPrices: () => Navigator.pushNamed(context, '/bottle-prices'),
          );
        }

        // Считаем стоимость ОДНОЙ порции
        final costPerServing = service.calculateCocktailCost(
          widget.cocktail.ingredients,
          widget.cocktail.measures,
        );

        // Считаем общую стоимость на N порций
        final totalCost = costPerServing * _servings;

        // Рекомендуемая цена за порцию (наценка 200%)
        final recommendedPricePerServing = costPerServing * 3;
        final totalRecommendedPrice = recommendedPricePerServing * _servings;

        // Прибыль
        final profitPerServing = recommendedPricePerServing - costPerServing;
        final totalProfit = profitPerServing * _servings;
        final profitMargin =
            ((profitPerServing / recommendedPricePerServing) * 100);

        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withAlpha(50)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calculate, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Калькулятор себестоимости',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Servings selector
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Порций:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: _servings > 1
                              ? () => setState(() => _servings--)
                              : null,
                          color: AppColors.primary,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(30),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$_servings',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => setState(() => _servings++),
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Ingredient breakdown
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ингредиенты на 1 порцию:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._buildIngredientList(service),

                    const Divider(height: 24),

                    // Cost per serving
                    _CostRow(
                      label: 'За 1 порцию:',
                      value: '${costPerServing.toStringAsFixed(2)} MDL',
                      isBold: true,
                      icon: Icons.local_drink,
                    ),

                    const SizedBox(height: 8),

                    // Total cost for N servings
                    if (_servings > 1) ...[
                      _CostRow(
                        label: 'За $_servings порций:',
                        value: '${totalCost.toStringAsFixed(2)} MDL',
                        isBold: true,
                        icon: Icons.set_meal,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Recommended price per serving
                    _CostRow(
                      label: 'Цена продажи (1 порция):',
                      value:
                          '${recommendedPricePerServing.toStringAsFixed(0)} MDL',
                      isBold: true,
                      color: AppColors.primary,
                      icon: Icons.price_check,
                    ),

                    if (_servings > 1) ...[
                      const SizedBox(height: 8),
                      _CostRow(
                        label: 'Цена продажи ($_servings порций):',
                        value:
                            '${totalRecommendedPrice.toStringAsFixed(0)} MDL',
                        isBold: true,
                        color: AppColors.primary,
                        icon: Icons.price_check,
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Profit
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.withAlpha(50)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.trending_up,
                                    color: Colors.green.shade700,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Прибыль с 1 порции:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${profitPerServing.toStringAsFixed(2)} MDL',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                  Text(
                                    '${profitMargin.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (_servings > 1) ...[
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Общая прибыль:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                Text(
                                  '${totalProfit.toStringAsFixed(2)} MDL',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildIngredientList(CostCalculatorService service) {
    final widgets = <Widget>[];

    for (int i = 0; i < widget.cocktail.ingredients.length; i++) {
      final ingredient = widget.cocktail.ingredients[i];
      final measure = widget.cocktail.measures[i];

      // Парсим объём
      final volume = _parseVolume(measure);
      final price = service.getPrice(ingredient.toLowerCase());
      final cost = (volume > 0 && price != null)
          ? price.calculatePortionCost(volume)
          : 0.0;

      widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$ingredient\n',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (measure.isNotEmpty)
                      TextSpan(
                        text: '$measure',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Text(
              cost > 0 ? '${cost.toStringAsFixed(2)} MDL' : '-',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cost > 0 ? AppColors.textPrimary : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ));
    }

    return widgets;
  }

  double _parseVolume(String measure) {
    if (measure.isEmpty) return 0.0;
    final numbers = measure.replaceAll(RegExp(r'[^0-9.]'), '');
    if (numbers.isEmpty) return 0.0;
    return double.tryParse(numbers) ?? 0.0;
  }
}

// ─── Missing Prices Warning ──────────────────────────────────────────────

class _MissingPricesWarning extends StatelessWidget {
  final List<String> ingredients;
  final VoidCallback onSetPrices;

  const _MissingPricesWarning({
    required this.ingredients,
    required this.onSetPrices,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Нет цен для ингредиентов',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Для ${ingredients.take(3).join(", ")}${ingredients.length > 3 ? " и др." : ""}',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onSetPrices,
            icon: const Icon(Icons.add),
            label: const Text('Указать цены'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 44),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Cost Row ────────────────────────────────────────────────────────────

class _CostRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? color;
  final IconData icon;

  const _CostRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color ?? AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: isBold ? 15 : 14,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
                color: color ?? AppColors.textPrimary,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
