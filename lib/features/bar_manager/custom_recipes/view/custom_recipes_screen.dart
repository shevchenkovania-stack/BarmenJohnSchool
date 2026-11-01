import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coin/core/repositories/custom_recipe_repository.dart';
import 'package:coin/core/models/custom_recipe.dart';
import 'package:coin/core/theme/app_theme.dart';
import 'package:coin/l10n/app_localizations.dart';
import 'package:coin/features/bar_manager/custom_recipes/view/add_edit_recipe_screen.dart';

/// Список авторских рецептов заведения.
///
/// FAB → открывает AddEditRecipeScreen для создания нового рецепта.
/// Тап на рецепт → открывает его для редактирования.
/// Свайп или кнопка удаления → подтверждение и удаление.
class CustomRecipesScreen extends StatelessWidget {
  const CustomRecipesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n.myRecipesTitle)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            // null = создаём новый рецепт (не редактируем существующий)
            builder: (_) => const AddEditRecipeScreen(recipe: null),
          ),
        ),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.black),
      ),
      body: Consumer<CustomRecipeRepository>(
        builder: (_, repo, __) {
          final recipes = repo.getAll();

          if (recipes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.menu_book_rounded,
                        color: AppColors.textSecondary, size: 56),
                    const SizedBox(height: 16),
                    Text(
                      l10n.myRecipesEmpty,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.myRecipesEmptyHint,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 80), // место для FAB
            itemCount: recipes.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) => _RecipeTile(recipe: recipes[i]),
          );
        },
      ),
    );
  }
}

// ─── Плитка рецепта ───────────────────────────────────────────────────────────

class _RecipeTile extends StatelessWidget {
  final CustomRecipe recipe;

  const _RecipeTile({required this.recipe});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repo = context.read<CustomRecipeRepository>();

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      // Иконка — первая буква названия в кружке
      leading: CircleAvatar(
        backgroundColor: AppColors.surfaceLight,
        child: Text(
          recipe.name.isNotEmpty ? recipe.name[0].toUpperCase() : '?',
          style: const TextStyle(
              color: AppColors.primary, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(
        recipe.name,
        style: const TextStyle(
            color: AppColors.textPrimary, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        // Показываем количество ингредиентов как краткое описание
        '${recipe.ingredients.length} ${l10n.recipeIngredientsSection.toLowerCase()}',
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline_rounded,
            color: AppColors.textSecondary),
        onPressed: () => _confirmDelete(context, repo, l10n),
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddEditRecipeScreen(recipe: recipe),
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    CustomRecipeRepository repo,
    AppLocalizations l10n,
  ) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(recipe.name,
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(l10n.actionConfirmDelete,
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.actionCancel)),
          TextButton(
            onPressed: () {
              repo.delete(recipe);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );
  }
}
