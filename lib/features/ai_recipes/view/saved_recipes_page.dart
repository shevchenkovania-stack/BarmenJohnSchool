import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:coin/core/models/cocktail.dart';
import 'package:coin/core/services/saved_recipe_service.dart';
import 'package:coin/core/theme/app_theme.dart';
import 'package:coin/features/ai_recipes/models/detailed_recipe.dart';
import 'package:coin/features/ai_recipes/view/ai_recipe_viewer.dart';

/// Library of saved AI recipes.
class SavedRecipesPage extends StatelessWidget {
  const SavedRecipesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<SavedRecipeService>();
    final entries = svc.all;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Библиотека рецептов'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: entries.isEmpty
          ? _EmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: entries.length,
              itemBuilder: (ctx, idx) {
                final entry = entries[idx];
                return _RecipeCard(entry: entry);
              },
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.bookmarks_outlined,
              size: 64, color: AppColors.textSecondary.withAlpha(60)),
          const SizedBox(height: 16),
          Text(
            'Сохранённых рецептов нет',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Text(
            'Нажмите "Сохранить" в рецепте,\nчтобы добавить его в библиотеку',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────────────────────

class _RecipeCard extends StatelessWidget {
  final SavedRecipeEntry entry;
  const _RecipeCard({required this.entry});

  @override
  Widget build(BuildContext context) => Dismissible(
        key: Key('${entry.cocktailId}_${entry.mode.name}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.red.withAlpha(30),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.delete_outline, color: Colors.red, size: 28),
        ),
        confirmDismiss: (dir) async {
          final ok = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Удалить рецепт?'),
              content: Text(
                  'Вы удаляете "${entry.cocktailName}" (${entry.mode.name})'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Отмена')),
                ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Удалить')),
              ],
            ),
          );
          return ok ?? false;
        },
        onDismissed: (_) {
          final svc = context.read<SavedRecipeService>();
          svc.delete(entry.cocktailId, entry.mode);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Удалено: ${entry.cocktailName}')),
            );
          }
        },
        child: GestureDetector(
          onTap: () {
            // Open recipe viewer with forceCache = true
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => AiRecipeViewer(
                        cocktail: entry.cocktail,
                        forceCache: true,
                      )),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: entry.cocktailImage ?? '',
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    width: 60,
                    height: 60,
                    color: AppColors.surfaceLight,
                    child: const Icon(Icons.local_bar,
                        color: AppColors.textSecondary, size: 24),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    width: 60,
                    height: 60,
                    color: AppColors.surfaceLight,
                    child: const Icon(Icons.error_outline,
                        color: Colors.red, size: 24),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(entry.cocktailName,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                      'Сохранён: ${_formatDate(entry.savedAt)}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ])),
              // Mode badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: entry.mode == RecipeMode.expert
                      ? AppColors.primary
                      : Colors.blue,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  entry.mode == RecipeMode.expert ? 'EXPERT' : 'STARTER',
                  style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 9,
                      letterSpacing: 0.5),
                ),
              ),
            ]),
          ),
        ),
      );

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      if (diff.inHours == 0) return '${diff.inMinutes} мин назад';
      return '${diff.inHours} ч назад';
    }
    if (diff.inDays < 7) return '${diff.inDays} дн. назад';
    return '${dt.day}.${dt.month}.${dt.year.toString().substring(2)}';
  }
}
