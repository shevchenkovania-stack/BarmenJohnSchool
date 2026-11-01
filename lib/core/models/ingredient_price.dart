import 'package:hive_flutter/hive_flutter.dart';

part 'ingredient_price.g.dart';

/// Цена ингредиента — основа для расчёта себестоимости коктейля.
///
/// Логика:
///   цена за 1 ml = [bottlePrice] / [bottleSizeMl]
///
/// Пример:
///   Ron Barcelo, бутылка 700 ml, цена 25$
///   → 1 ml = 0.0357$
///   → 50 ml рома в коктейле = 1.785$
@HiveType(typeId: 4) // AppConstants.ingredientPriceTypeId
class IngredientPrice extends HiveObject {
  /// Название ингредиента (напр. "Ron Barcelo", "Lime juice")
  @HiveField(0)
  late String name;

  /// Цена бутылки / упаковки в выбранной валюте
  @HiveField(1)
  late double bottlePrice;

  /// Объём бутылки в мл (напр. 700 для стандартной бутылки)
  @HiveField(2)
  late double bottleSizeMl;

  /// Единица валюты для отображения (напр. "$", "€", "MDL")
  @HiveField(3)
  late String currency;

  IngredientPrice({
    required this.name,
    required this.bottlePrice,
    required this.bottleSizeMl,
    this.currency = '\$',
  });

  /// Цена за 1 ml этого ингредиента
  double get pricePerMl => bottleSizeMl > 0 ? bottlePrice / bottleSizeMl : 0;

  /// Стоимость [ml] миллилитров этого ингредиента
  double costFor(double ml) => ml * pricePerMl;
}
