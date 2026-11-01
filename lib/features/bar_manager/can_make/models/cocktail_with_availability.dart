import 'package:coin/core/models/cocktail.dart';

/// Коктейль с информацией о доступности ингредиентов.
/// 
/// Используется в Can Make Now для отображения:
/// - каких ингредиентов не хватает
/// - можно ли сделать коктейль прямо сейчас
class CocktailWithAvailability {
  final Cocktail cocktail;
  final List<String> availableIngredients;    // ✅ Есть в наличии
  final List<String> missingIngredients;      // ❌ Нет в наличии
  final bool canMakeNow;                       // Все ингредиенты есть

  const CocktailWithAvailability({
    required this.cocktail,
    required this.availableIngredients,
    required this.missingIngredients,
    required this.canMakeNow,
  });

  /// Создать из коктейля и инвентаря
  factory CocktailWithAvailability.check(
    Cocktail cocktail,
    Set<String> inventory,
    Set<String> stopList,
  ) {
    final available = <String>[];
    final missing = <String>[];

    for (final ingredient in cocktail.ingredients) {
      final lower = ingredient.toLowerCase();
      
      if (stopList.contains(lower)) {
        // В стоп-листе = отсутствует
        missing.add(ingredient);
      } else if (inventory.contains(lower)) {
        // Есть в инвентаре
        available.add(ingredient);
      } else {
        // Нет в инвентаре
        missing.add(ingredient);
      }
    }

    return CocktailWithAvailability(
      cocktail: cocktail,
      availableIngredients: available,
      missingIngredients: missing,
      canMakeNow: missing.isEmpty,
    );
  }

  /// Количество недостающих ингредиентов
  int get missingCount => missingIngredients.length;
}
