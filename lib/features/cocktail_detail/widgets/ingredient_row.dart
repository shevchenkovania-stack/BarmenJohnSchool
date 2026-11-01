import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coin/core/models/cocktail.dart';
import 'package:coin/core/theme/app_theme.dart';
import 'package:coin/core/utils/serving_calculator.dart';
import 'package:coin/core/services/measurement_service.dart';

/// Горизонтальная строка ингредиентов с крупными карточками и анимацией.
class IngredientRow extends StatelessWidget {
  final Cocktail cocktail;
  final int servings;

  const IngredientRow({super.key, required this.cocktail, this.servings = 1});

  @override
  Widget build(BuildContext context) {
    final scaledMeasures = ServingCalculator.scaleAll(cocktail.measures, servings);
    final measurementService = context.watch<MeasurementService>();

    final screenHeight = MediaQuery.of(context).size.height;
    final cardHeight = screenHeight < 600 ? 110.0 : 130.0;

    return SizedBox(
      height: cardHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cocktail.ingredients.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => _IngredientCard(
          name: cocktail.ingredients[i],
          measure: scaledMeasures[i],
          measurementService: measurementService,
        ),
      ),
    );
  }
}

/// Карточка ингредиента с анимацией при нажатии.
class _IngredientCard extends StatefulWidget {
  final String name;
  final String measure;
  final MeasurementService measurementService;

  const _IngredientCard({
    required this.name,
    required this.measure,
    required this.measurementService,
  });

  @override
  State<_IngredientCard> createState() => _IngredientCardState();
}

class _IngredientCardState extends State<_IngredientCard> {
  bool _isPressed = false;

  String get _displayMeasure {
    final measure = widget.measure;
    if (measure.isEmpty) return '';

    final match = RegExp(r'^([\d.]+)\s*(oz|ml)?').firstMatch(measure.trim());
    if (match == null) return measure;

    final value = double.tryParse(match.group(1) ?? '0') ?? 0;
    final unit = match.group(2) ?? 'oz';

    if (unit == 'oz' && value > 0) {
      return widget.measurementService.formatVolume(value * 29.5735);
    }
    return measure;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 1.1 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 90,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 50,
                height: 50,
                child: CachedNetworkImage(
                  imageUrl: Cocktail.ingredientThumbUrl(widget.name),
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const Icon(
                    Icons.local_bar_outlined,
                    color: AppColors.primary,
                    size: 28,
                  ),
                  errorWidget: (_, __, ___) => const Icon(
                    Icons.local_bar_outlined,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Flexible(
                child: Text(
                  widget.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (_displayMeasure.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  _displayMeasure,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}