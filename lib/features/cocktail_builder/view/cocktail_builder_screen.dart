import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coin/core/theme/app_theme.dart';
import 'package:coin/features/cocktail_builder/viewmodel/cocktail_builder_viewmodel.dart';
import 'package:coin/features/cocktail_builder/view/screens/builder_form_screen.dart';
import 'package:coin/features/cocktail_builder/view/screens/variant_selection_screen.dart';
import 'package:coin/features/cocktail_builder/view/screens/result_screen.dart';

class CocktailBuilderScreen extends StatelessWidget {
  const CocktailBuilderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Конструктор',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.3),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                context.read<CocktailBuilderViewModel>().createNew(),
            tooltip: 'Начать заново',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary.withOpacity(0.12),
              foregroundColor: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<CocktailBuilderViewModel>(
        builder: (_, vm, __) {
          if (vm.selectedVariant != null) {
            return ResultScreen(
              cocktail: vm.selectedVariant!,
              onBack: () =>
                  vm.clearSelectedVariant(), // Просто назад к вариантам
            );
          }

          if (vm.variants.isNotEmpty) {
            return VariantSelectionScreen(viewModel: vm);
          }

          return BuilderForm(viewModel: vm);
        },
      ),
    );
  }
}
