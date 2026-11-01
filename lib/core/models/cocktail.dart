import 'dart:convert';

/// Модель коктейля.
/// API TheCocktailDB возвращает до 15 ингредиентов (strIngredient1…15)
/// и 15 мер (strMeasure1…15). Мы собираем только непустые пары.
class Cocktail {
  final String idDrink;
  final String strDrink; // Название коктейля
  final String strCategory; // Категория (Cocktail, Shot, Punch, ...)
  final String
      strAlcoholic; // "Alcoholic" / "Non alcoholic" / "Optional alcohol"
  final String strGlass; // Тип стакана (Martini Glass, ...)
  final String strInstructions; // Инструкция приготовления
  final String strDrinkThumb; // URL главной картинки

  // Список ингредиентов — только непустые, уже отфильтрованные
  final List<String> ingredients;
  // Список мер в том же порядке, что ingredients
  final List<String> measures;

  const Cocktail({
    required this.idDrink,
    required this.strDrink,
    required this.strCategory,
    required this.strAlcoholic,
    required this.strGlass,
    required this.strInstructions,
    required this.strDrinkThumb,
    required this.ingredients,
    required this.measures,
  });

  // ─── Парсинг JSON (приходит с API) ───────────────────────────────────────

  factory Cocktail.fromJson(Map<String, dynamic> json) {
    final ingredients = <String>[];
    final measures = <String>[];

    // API даёт до 15 ингредиентов; пропускаем пустые
    for (int i = 1; i <= 15; i++) {
      final ingredient = (json['strIngredient$i'] ?? '').toString().trim();
      final measure = (json['strMeasure$i'] ?? '').toString().trim();
      if (ingredient.isNotEmpty) {
        ingredients.add(ingredient);
        measures.add(measure); // мера может быть пустой — это ок
      }
    }

    return Cocktail(
      idDrink: json['idDrink'] ?? '',
      strDrink: json['strDrink'] ?? '',
      strCategory: json['strCategory'] ?? '',
      strAlcoholic: json['strAlcoholic'] ?? '',
      strGlass: json['strGlass'] ?? '',
      strInstructions: json['strInstructions'] ?? '',
      strDrinkThumb: json['strDrinkThumb'] ?? '',
      ingredients: ingredients,
      measures: measures,
    );
  }

  // ─── Сериализация в JSON (нужна для хранения избранного) ─────────────────

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'idDrink': idDrink,
      'strDrink': strDrink,
      'strCategory': strCategory,
      'strAlcoholic': strAlcoholic,
      'strGlass': strGlass,
      'strInstructions': strInstructions,
      'strDrinkThumb': strDrinkThumb,
    };
    // Записываем в том же формате, что ожидает fromJson
    for (int i = 0; i < ingredients.length; i++) {
      map['strIngredient${i + 1}'] = ingredients[i];
      map['strMeasure${i + 1}'] = measures[i];
    }
    return map;
  }

  // ─── Вспомогательные методы ───────────────────────────────────────────────

  /// URL миниатюры ингредиента с API (100×100 px)
  static String ingredientThumbUrl(String name) {
    final encoded = Uri.encodeComponent(name);
    return 'https://www.thecocktaildb.com/images/ingredients/$encoded-Small.png';
  }

  /// URL маленькой превью-картинки коктейля (100×100 px)
  String get thumbPreviewUrl => '$strDrinkThumb/preview';
}
