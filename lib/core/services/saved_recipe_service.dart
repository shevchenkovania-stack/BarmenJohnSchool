import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:coin/core/constants/app_constants.dart';
import 'package:coin/core/db/hive_service.dart';
import 'package:coin/core/models/cocktail.dart';
import 'package:coin/features/ai_recipes/models/detailed_recipe.dart';

/// A single entry in the saved recipes library.
class SavedRecipeEntry {
  final String cocktailId;
  final String cocktailName;
  final String? cocktailImage;
  final RecipeMode mode;
  final DateTime savedAt;
  final DetailedRecipe recipe;
  final Cocktail cocktail;

  const SavedRecipeEntry({
    required this.cocktailId,
    required this.cocktailName,
    this.cocktailImage,
    required this.mode,
    required this.savedAt,
    required this.recipe,
    required this.cocktail,
  });
}

/// Manages saving, loading, and deleting AI-generated recipes in local Hive storage.
///
/// Storage format: Box<String> with key = "{cocktailId}_{mode}"
/// Value = JSON wrapper containing metadata + recipe JSON.
class SavedRecipeService extends ChangeNotifier {
  static String _key(String cocktailId, RecipeMode mode) =>
      '${cocktailId}_${mode.name}';

  // ─── Public API ──────────────────────────────────────────────────────────────

  /// Save a recipe to local storage.
  Future<void> save(
    Cocktail cocktail,
    RecipeMode mode,
    DetailedRecipe recipe,
  ) async {
    final key = _key(cocktail.idDrink, mode);
    final wrapper = {
      'saved_at': DateTime.now().toIso8601String(),
      'cocktail_name': cocktail.strDrink,
      'cocktail_image': cocktail.strDrinkThumb,
      'cocktail_id': cocktail.idDrink,
      'mode': mode.name,
      'cocktail': cocktail.toJson(),
      'recipe': recipe.toJson(),
    };
    await HiveService.savedRecipes.put(key, jsonEncode(wrapper));
    notifyListeners();
    print('💾 Recipe saved: ${cocktail.strDrink} (${mode.name})');
  }

  /// Load a saved recipe. Returns null if not in cache.
  DetailedRecipe? load(String cocktailId, RecipeMode mode) {
    final key = _key(cocktailId, mode);
    final raw = HiveService.savedRecipes.get(key);
    if (raw == null) return null;

    try {
      final wrapper = jsonDecode(raw) as Map<String, dynamic>;
      final recipe = DetailedRecipe.fromJson(
        wrapper['recipe'] as Map<String, dynamic>,
      );
      // Restore cocktail reference
      if (wrapper['cocktail'] != null) {
        recipe.baseCocktail = Cocktail.fromJson(
          wrapper['cocktail'] as Map<String, dynamic>,
        );
      }
      print('📂 Recipe loaded from cache: $cocktailId (${mode.name})');
      return recipe;
    } catch (e) {
      print('❌ Failed to load cached recipe: $e');
      return null;
    }
  }

  /// Check if a recipe is saved.
  bool isSaved(String cocktailId, RecipeMode mode) {
    return HiveService.savedRecipes.containsKey(_key(cocktailId, mode));
  }

  /// Delete a saved recipe.
  Future<void> delete(String cocktailId, RecipeMode mode) async {
    await HiveService.savedRecipes.delete(_key(cocktailId, mode));
    notifyListeners();
    print('🗑️ Recipe deleted: $cocktailId (${mode.name})');
  }

  /// All saved entries, sorted newest first.
  List<SavedRecipeEntry> get all {
    final entries = <SavedRecipeEntry>[];

    for (final key in HiveService.savedRecipes.keys) {
      final raw = HiveService.savedRecipes.get(key as String);
      if (raw == null) continue;

      try {
        final wrapper = jsonDecode(raw) as Map<String, dynamic>;
        final cocktail = Cocktail.fromJson(
          wrapper['cocktail'] as Map<String, dynamic>,
        );
        final recipe = DetailedRecipe.fromJson(
          wrapper['recipe'] as Map<String, dynamic>,
        )..baseCocktail = cocktail;

        final modeStr = wrapper['mode'] as String? ?? 'starter';
        final mode =
            modeStr == 'expert' ? RecipeMode.expert : RecipeMode.starter;

        entries.add(SavedRecipeEntry(
          cocktailId: wrapper['cocktail_id'] as String? ?? '',
          cocktailName: wrapper['cocktail_name'] as String? ?? '',
          cocktailImage: wrapper['cocktail_image'] as String?,
          mode: mode,
          savedAt: DateTime.tryParse(wrapper['saved_at'] as String? ?? '') ??
              DateTime.now(),
          recipe: recipe,
          cocktail: cocktail,
        ));
      } catch (e) {
        print('❌ Failed to parse saved entry: $e');
      }
    }

    // Sort newest first
    entries.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return entries;
  }

  /// Total count of saved recipes.
  int get count => HiveService.savedRecipes.length;
}
