// lib/features/cocktail_builder/models/generated_cocktail.dart

class CocktailIngredient {
  final String name;
  final int amountMl;

  const CocktailIngredient({required this.name, required this.amountMl});

  factory CocktailIngredient.fromJson(Map<String, dynamic> json) =>
      CocktailIngredient(
        name: json['name'] as String,
        amountMl: json['amountMl'] as int,
      );
}

/// Метод приготовления
enum CocktailMethod { shake, stir, build }

extension CocktailMethodX on CocktailMethod {
  String get label {
    switch (this) {
      case CocktailMethod.shake: return 'Shake (шейкер)';
      case CocktailMethod.stir:  return 'Stir (перемешать)';
      case CocktailMethod.build: return 'Build (в стакане)';
    }
  }

  String get emoji {
    switch (this) {
      case CocktailMethod.shake: return '🍸';
      case CocktailMethod.stir:  return '🥄';
      case CocktailMethod.build: return '🥃';
    }
  }

  String get reason {
    switch (this) {
      case CocktailMethod.shake:
        return 'Смешиваем сок/кислоту с алкоголем — шейк делает текстуру мягче и «собирает» вкус';
      case CocktailMethod.stir:
        return 'Только алкоголь — стир охлаждает без лишнего воздуха, сохраняет чистоту вкуса';
      case CocktailMethod.build:
        return 'Газированный компонент — строим прямо в бокале чтобы не потерять пузырьки';
    }
  }
}

/// Тип бокала
enum CocktailGlass { coupe, rocks, highball, martini, flute }

extension CocktailGlassX on CocktailGlass {
  String get label {
    switch (this) {
      case CocktailGlass.coupe:    return 'Coupe / Martini';
      case CocktailGlass.rocks:    return 'Rocks (старомодный)';
      case CocktailGlass.highball: return 'Highball';
      case CocktailGlass.martini:  return 'Martini';
      case CocktailGlass.flute:    return 'Флюте';
    }
  }

  String get emoji {
    switch (this) {
      case CocktailGlass.coupe:
      case CocktailGlass.martini:  return '🍸';
      case CocktailGlass.rocks:    return '🥃';
      case CocktailGlass.highball: return '🥤';
      case CocktailGlass.flute:    return '🥂';
    }
  }
}

class GeneratedCocktail {
  final String name;
  final String description;
  final List<CocktailIngredient> ingredients;
  final List<String> steps;
  final CocktailMethod method;
  final CocktailGlass glass;
  final String wowEffect;      // "выжать цедру апельсина над бокалом"
  final String whyItWorks;     // "вишня = глубина, мартини = аромат..."
  final String? proTip;
  final String? fact;
  final String? secret;

  const GeneratedCocktail({
    required this.name,
    required this.description,
    required this.ingredients,
    required this.steps,
    required this.method,
    required this.glass,
    required this.wowEffect,
    required this.whyItWorks,
    this.proTip,
    this.fact,
    this.secret,
  });

  factory GeneratedCocktail.fromJson(Map<String, dynamic> json) {
    // Парсим метод
    CocktailMethod method;
    switch ((json['method'] as String? ?? '').toLowerCase()) {
      case 'stir':  method = CocktailMethod.stir;  break;
      case 'build': method = CocktailMethod.build; break;
      default:      method = CocktailMethod.shake;
    }

    // Парсим бокал
    CocktailGlass glass;
    switch ((json['glass'] as String? ?? '').toLowerCase()) {
      case 'rocks':    glass = CocktailGlass.rocks;    break;
      case 'highball': glass = CocktailGlass.highball; break;
      case 'martini':  glass = CocktailGlass.martini;  break;
      case 'flute':    glass = CocktailGlass.flute;    break;
      default:         glass = CocktailGlass.coupe;
    }

    return GeneratedCocktail(
      name:        json['name'] as String,
      description: json['description'] as String,
      ingredients: (json['ingredients'] as List)
          .map((e) => CocktailIngredient.fromJson(e as Map<String, dynamic>))
          .toList(),
      steps:      List<String>.from(json['steps'] as List),
      method:     method,
      glass:      glass,
      wowEffect:  json['wowEffect']  as String? ?? '',
      whyItWorks: json['whyItWorks'] as String? ?? '',
      proTip:     json['proTip']     as String?,
      fact:       json['fact']       as String?,
      secret:     json['secret']     as String?,
    );
  }
}
