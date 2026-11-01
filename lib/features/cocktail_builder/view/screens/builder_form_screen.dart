import 'package:flutter/material.dart';
import 'package:coin/core/theme/app_theme.dart';
import 'package:coin/features/cocktail_builder/viewmodel/cocktail_builder_viewmodel.dart';
import 'package:coin/features/cocktail_builder/view/widgets/cards.dart';
import 'package:coin/features/cocktail_builder/view/widgets/ingredient_chip.dart';
import 'package:coin/features/cocktail_builder/view/widgets/result_elements.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  BuilderForm
// ══════════════════════════════════════════════════════════════════════════════

class BuilderForm extends StatelessWidget {
  final CocktailBuilderViewModel viewModel;

  const BuilderForm({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final hasIngredients = viewModel.selectedIngredients.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        // ── Header ─────────────────────────────────────────────────────
        HeroCard(
          title: 'Конструктор коктейлей',
          subtitle: 'Выбери ингредиенты и собери коктейль',
          icon: Icons.local_bar_rounded,
          gradientColors: [
            AppColors.primary.withOpacity(0.15),
            AppColors.primary.withOpacity(0.05),
          ],
        ),
        const SizedBox(height: 16),
        // ── Ingredients ────────────────────────────────────────────────
        SectionCard(
          icon: Icons.inventory_2_rounded,
          color: AppColors.primary,
          title: 'Ингредиенты',
          subtitle: hasIngredients
              ? '${viewModel.selectedIngredients.length} выбрано — собери коктейль ниже'
              : 'Выбери ингредиенты и добавь свои',
          trailing: TextButton.icon(
            icon: const Icon(Icons.add_circle_outline, size: 18),
            label: const Text('Свой',
                style: TextStyle(fontWeight: FontWeight.w600)),
            onPressed: () => _showAddDialog(context),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasIngredients) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '✅ Выбрано:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: viewModel.selectedIngredients.map((name) {
                          return Chip(
                            label: Text(name,
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600)),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () => viewModel.toggleIngredient(name),
                            backgroundColor:
                                AppColors.primary.withOpacity(0.15),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (viewModel.availableIngredients.isEmpty)
                const EmptyState(
                  message: '📝 Добавь ингредиенты для практики',
                  subtext: 'Нажми «Свой» чтобы добавить',
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: viewModel.availableIngredients.map((name) {
                    final sel = viewModel.selectedIngredients.contains(name);
                    return IngredientChip(
                      label: name,
                      selected: sel,
                      onToggle: (_) => viewModel.toggleIngredient(name),
                      color: AppColors.primary,
                    );
                  }).toList(),
                ),
              if (viewModel.customIngredients.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                const Text('Свои ингредиенты',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: viewModel.customIngredients.map((name) {
                    final sel = viewModel.selectedIngredients.contains(name);
                    return IngredientChip(
                      label: name,
                      selected: sel,
                      onToggle: (_) => viewModel.toggleIngredient(name),
                      onRemove: () => viewModel.removeCustomIngredient(name),
                      color: AppColors.primary,
                      isCustom: true,
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        // ── Generate Button ────────────────────────────────────────────
        _BuildButton(
          isGenerating: viewModel.isGenerating,
          hasIngredients: hasIngredients,
          ingredientCount: viewModel.selectedIngredients.length,
          onPressed: () => viewModel.generateVariants(),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  void _showAddDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add_circle_rounded,
                      color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                const Text('Добавить ингредиент',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
              ]),
              const SizedBox(height: 20),
              TextField(
                controller: ctrl,
                decoration: InputDecoration(
                  hintText: 'Например: Амаретто',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: AppColors.textSecondary.withOpacity(0.3))),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: AppColors.textSecondary.withOpacity(0.3))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.primary, width: 2)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary),
                onSubmitted: (_) {
                  if (ctrl.text.trim().isNotEmpty) {
                    viewModel.addCustomIngredient(ctrl.text);
                    Navigator.pop(context);
                  }
                },
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Отмена',
                          style: TextStyle(color: AppColors.textSecondary))),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (ctrl.text.trim().isNotEmpty) {
                        viewModel.addCustomIngredient(ctrl.text);
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Добавить',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  Widgets
// ══════════════════════════════════════════════════════════════════════════════

/// The main action button — contextual label based on state.
class _BuildButton extends StatelessWidget {
  final bool isGenerating;
  final bool hasIngredients;
  final int ingredientCount;
  final VoidCallback onPressed;

  const _BuildButton({
    required this.isGenerating,
    required this.hasIngredients,
    required this.ingredientCount,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!hasIngredients)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.arrow_upward_rounded,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  'Выбери ингредиенты выше',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            icon: isGenerating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : Icon(
                    hasIngredients
                        ? Icons.check_circle_rounded
                        : Icons.local_bar_rounded,
                    size: 22,
                  ),
            label: Text(
              isGenerating
                  ? 'Ищем коктейль...'
                  : hasIngredients
                      ? 'Собрать коктейль ($ingredientCount инг.)'
                      : 'Выбери ингредиенты',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: hasIngredients
                  ? AppColors.primary
                  : AppColors.primary.withOpacity(0.3),
              foregroundColor: Colors.black,
              disabledBackgroundColor: AppColors.primary.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: hasIngredients ? 4 : 0,
            ),
            onPressed: hasIngredients && !isGenerating ? onPressed : null,
          ),
        ),
      ],
    );
  }
}
