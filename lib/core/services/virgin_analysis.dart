import 'package:coin/core/models/cocktail.dart';
import 'package:coin/core/services/virgin_cocktail_service.dart';

/// Тест для анализа всей базы коктейлей на virgin capability
void analyzeVirginCapability(List<Cocktail> allCocktails) {
  final virginService = VirginCocktailService();

  print('\n' + '=' * 60);
  print('🍹 VIRGIN COCKTAIL ANALYSIS');
  print('=' * 60);

  int total = allCocktails.length;
  int virginCapable = 0;
  int notCapable = 0;

  final capableExamples = <String>[];
  final notCapableExamples = <String>[];
  final brokenInstructions = <String>[];

  // Анализируем каждый коктейль
  for (final cocktail in allCocktails) {
    final virgin = virginService.createVirginFromCocktail(cocktail);

    if (virgin != null) {
      virginCapable++;
      if (capableExamples.length < 10) {
        capableExamples
            .add('${cocktail.strDrink} → ${virgin.ingredients.length} ing');
      }

      // Проверяем инструкцию
      if (virgin.strInstructions.contains('Текила') ||
          virgin.strInstructions.contains('Vodka') ||
          virgin.strInstructions.contains('Rum') ||
          virgin.strInstructions.contains('Gin')) {
        brokenInstructions
            .add('${cocktail.strDrink}: ${virgin.strInstructions}');
      }
    } else {
      notCapable++;
      if (notCapableExamples.length < 10) {
        final ingCount = cocktail.ingredients.length;
        notCapableExamples.add('${cocktail.strDrink} ($ingCount ing)');
      }
    }
  }

  // Выводим статистику
  print('\n📊 СТАТИСТИКА:');
  print('Всего коктейлей: $total');
  print(
      '✅ Можно сделать virgin: $virginCapable (${(virginCapable / total * 100).round()}%)');
  print(
      '❌ Нельзя сделать virgin: $notCapable (${(notCapable / total * 100).round()}%)');

  print('\n✅ ПРИМЕРЫ УСПЕШНЫХ VIRGIN:');
  for (final example in capableExamples) {
    print('  • $example');
  }

  print('\n❌ ПРИМЕРЫ НЕВОЗМОЖНЫХ:');
  for (final example in notCapableExamples) {
    print('  • $example');
  }

  if (brokenInstructions.isNotEmpty) {
    print(
        '\n⚠️ ИНСТРУКЦИИ С ОСТАТКАМИ АЛКОГОЛЯ (${brokenInstructions.length}):');
    for (final broken in brokenInstructions.take(5)) {
      print('  • $broken');
    }
  }

  // Анализируем по категориям
  print('\n📋 АНАЛИЗ ПО КАТЕГОРИЯМ:');
  final categories = <String, List<Cocktail>>{};

  for (final cocktail in allCocktails) {
    categories.putIfAbsent(cocktail.strCategory, () => []).add(cocktail);
  }

  for (final category in categories.entries) {
    int catVirgin = 0;
    for (final c in category.value) {
      if (virginService.createVirginFromCocktail(c) != null) {
        catVirgin++;
      }
    }
    final pct = (catVirgin / category.value.length * 100).round();
    print('  ${category.key}: $catVirgin/${category.value.length} ($pct%)');
  }

  print('\n' + '=' * 60);
}
