import 'dart:async';

import 'package:coin/repozitories/models/cocktail.dart';
import 'package:coin/repozitories/models/cocktailapi.dart';
import 'package:coin/helper/stringparser.dart';

class CocktailRepository {
  //-------------------------------------
  //Приватные поля

  //для того чтоб узнать если строка состоит из одного символа
  final _stringParser = StringParser();

  //переменная доступа к api
  final CocktailApi _cocktailApi = CocktailApi();

  //список всех коктелей
  final List<Cocktail> _cocktails = [];

  //список ингридиентов
  List<String> ingridients = [];

  //categories, glasses, ingredients or alcoholic filters

  //список категорий
  List<String> categories = [];

  //список стаканов
  List<String> glasses = [];

  //список алкогольных фильтров
  List<String> alcoholicFilters = [];

  //получаем эту мапу по апи
  Map<String, dynamic> _cocktailsMap = Map();

  //получаем эту мапу по апи
  Map<String, dynamic> _ingredientsMap = Map();

  //---------------------------------------
  //Публичные методы

  //Получить список всех коктелей
  Future<List<Cocktail>> getAllCocktailsByAlphabet() async {
    List<Cocktail> allcocktailsList = [];

    List<String> alphabets = [
      "A",
      "B",
      "C",
      "D",
      "E",
      "F",
      "G",
      "H",
      "I",
      "J",
      "K",
      "L",
      "M",
      "N",
      "O",
      "P",
      "Q",
      "R",
      "S",
      "T",
      "U",
      "V",
      "W",
      "X",
      "Y",
      "Z"
    ];

    for (var letter in alphabets) {
      var oneLetterCocktails = await getCocktailsByFirstLetter(letter);

      allcocktailsList.addAll(oneLetterCocktails);
      oneLetterCocktails.clear();
    }

    print('count of all cocktail is: ${allcocktailsList.length} ');

    return allcocktailsList;
  }

  //Получить список всех ингредиентов
  Future<List<String>> getAllIngredients() async {
    var response = await _cocktailApi.ListAllIngredients();

    if (response.statusCode == 200) {
      _ingredientsMap = response.data;

      if (_ingredientsMap['drinks'] != null) {
        for (var drink in _ingredientsMap['drinks']) {
          ingridients.add(drink['strIngredient1']);
        }
      }
    }
    return ingridients;
  }

  //Получить список коктелей по первой букве
  Future<List<Cocktail>> getCocktailsByFirstLetter(String letter) async {
    if (_stringParser.isOneLetterString(letter)) {
      var response = await _cocktailApi.ListAllCocktailsByFirstLetter(letter);

      if (response.statusCode == 200) {
        _cocktailsMap = response.data;

        if (_cocktailsMap['drinks'] != null &&
            _cocktailsMap['drinks'].isNotEmpty) {
          //
          for (var drink in _cocktailsMap['drinks']) {
            //создаем обьект и добавляем в список обьектов
            _cocktails.add(Cocktail.fromJson(drink));
          }
        }
      }
    }

    return _cocktails;
  }
}
