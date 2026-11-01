class Cocktail {
  // Основные поля
  final String idDrink;
  final String strDrink;
  final String strCategory;
  final String strAlcoholic;
  final String strGlass;
  final String strInstructions;
  final String strDrinkThumb;
  final String strIngredient1;
  final String strIngredient2;
  final String strIngredient3;
  final String strIngredient4;
  final String strIngredient5;
  final String strIngredient6;
  final String strIngredient7;
  final String strIngredient8;
  final String strIngredient9;
  final String strMeasure1;


  // Конструктор
  Cocktail({
    required this.idDrink,
    required this.strDrink,
    required this.strCategory,
    required this.strAlcoholic,
    required this.strGlass,
    required this.strInstructions,
    required this.strDrinkThumb,
    required this.strIngredient1,
    required this.strIngredient2,
    required this.strIngredient3,
    required this.strIngredient4,
    required this.strIngredient5,
    required this.strIngredient6,
    required this.strIngredient7,
    required this.strIngredient8,
    required this.strIngredient9,
    required this.strMeasure1,
  });
  

  // Фабричный метод для создания объекта из JSON
  factory Cocktail.fromJson(Map<String, dynamic> json) {
    return Cocktail(
      idDrink: json['idDrink'],
      strDrink: json['strDrink'],
      strCategory: json['strCategory'],
      strAlcoholic: json['strAlcoholic'],
      strGlass: json['strGlass'],
      strInstructions: json['strInstructions'],
      strDrinkThumb: json['strDrinkThumb'],
      strIngredient1: json['strIngredient1'] ?? '',
      strIngredient2: json['strIngredient2'] ?? '',
      strIngredient3: json['strIngredient3'] ?? '',
      strIngredient4: json['strIngredient4'] ?? '',
      strIngredient5: json['strIngredient5'] ?? '',
      strIngredient6: json['strIngredient6'] ?? '',
      strIngredient7: json['strIngredient7'] ?? '',
      strIngredient8: json['strIngredient8'] ?? '',
      strIngredient9: json['strIngredient9'] ?? '',
      strMeasure1: json['strMeasure1'] ?? '',

    );
  }
}


