import 'package:flutter/material.dart';
import 'package:coin/core/theme/app_theme.dart';
import 'package:coin/features/cocktail_builder/viewmodel/cocktail_builder_viewmodel.dart';
import 'package:coin/features/cocktail_builder/models/generated_cocktail.dart';
import 'package:coin/features/cocktail_builder/models/cocktail_types.dart';
import 'package:coin/features/cocktail_builder/view/widgets/tags.dart';

class VariantSelectionScreen extends StatelessWidget {
  final CocktailBuilderViewModel viewModel;

  const VariantSelectionScreen({required this.viewModel});

  static const List<Color> _cardAccents = [
    Color(0xFFE8A838),
    Color(0xFF6BCB77),
    Color(0xFF4D96FF),
    Color(0xFFFF6B6B),
    Color(0xFF9B59B6),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 20, 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Выбери свой коктейль',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '${viewModel.variants.length} варианта из твоих ингредиентов',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            itemCount: viewModel.variants.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final cocktail = viewModel.variants[i];
              final accent = _cardAccents[i % _cardAccents.length];
              return VariantCard(
                cocktail: cocktail,
                accent: accent,
                index: i + 1,
                onTap: () => viewModel.selectVariant(cocktail),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.shuffle_rounded, size: 20),
                  label: const Text(
                    'Создать другие варианты',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: viewModel.isGenerating
                      ? null
                      : () => viewModel.generateVariants(),
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

class VariantCard extends StatelessWidget {
  final GeneratedCocktail cocktail;
  final Color accent;
  final int index;
  final VoidCallback onTap;

  const VariantCard({
    required this.cocktail,
    required this.accent,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final typeLabel = cocktail.cocktailType.name == 'classic'
        ? 'Классический'
        : cocktail.cocktailType.name == 'signature'
            ? 'Авторский'
            : 'Эксперимент';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withOpacity(0.35), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.12),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.1),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(19)),
                border: Border(
                  bottom: BorderSide(color: accent.withOpacity(0.2)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$index',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cocktail.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          typeLabel,
                          style: TextStyle(
                            fontSize: 11,
                            color: accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (cocktail.matchScore > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${(cocktail.matchScore * 100).toInt()}% совпадение',
                        style: TextStyle(
                          fontSize: 11,
                          color: accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: accent,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cocktail.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Tag(
                        label: cocktail.method.label,
                        emoji: cocktail.method.emoji,
                        color: accent,
                      ),
                      const SizedBox(width: 8),
                      Tag(
                        label: cocktail.glass.label,
                        emoji: cocktail.glass.emoji,
                        color: accent,
                      ),
                    ],
                  ),
                  if (cocktail.usedIngredients.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      '✅ Использовано:',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: cocktail.usedIngredients
                          .map((ing) => IngChip(
                                name: ing,
                                color: accent,
                              ))
                          .toList(),
                    ),
                  ],
                  if (cocktail.skippedIngredients.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      '❌ Пропущено:',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...cocktail.skippedIngredients.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final ing = entry.value;
                      final reason = cocktail.skippedReasons.length > idx
                          ? cocktail.skippedReasons[idx]
                          : 'не подходит';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(Icons.close,
                                size: 12, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              '$ing — $reason',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  if (cocktail.missingForClassic != null &&
                      cocktail.missingForClassic!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lightbulb_outline,
                              size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              cocktail.missingForClassic!,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (cocktail.suggestedReplacements.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      '💡 Предложенные замены:',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...cocktail.suggestedReplacements
                        .map((replacement) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  Icon(Icons.swap_horiz,
                                      size: 12, color: AppColors.primary),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      replacement,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}