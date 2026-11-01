import 'package:dio/dio.dart';

/// Низкоуровневый HTTP-клиент для TheCocktailDB API (бесплатный ключ '1').
/// Только делает сетевые запросы — никакой бизнес-логики здесь нет.
/// Документация: https://www.thecocktaildb.com/api.php
class CocktailApi {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://www.thecocktaildb.com/api/json/v1/1',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  /// Поиск по названию: /search.php?s=margarita
  Future<Response> searchByName(String name) =>
      _dio.get('/search.php', queryParameters: {'s': name});

  /// Список коктейлей по первой букве: /search.php?f=a
  Future<Response> listByFirstLetter(String letter) =>
      _dio.get('/search.php', queryParameters: {'f': letter});

  /// Случайный коктейль: /random.php
  Future<Response> getRandom() => _dio.get('/random.php');

  /// Детали коктейля по ID: /lookup.php?i=11007
  Future<Response> lookupById(String id) =>
      _dio.get('/lookup.php', queryParameters: {'i': id});

  /// Фильтр по алкоголю: /filter.php?a=Alcoholic или Non_Alcoholic
  Future<Response> filterByAlcoholic(String alcoholic) =>
      _dio.get('/filter.php', queryParameters: {'a': alcoholic});

  /// Фильтр по категории: /filter.php?c=Cocktail
  Future<Response> filterByCategory(String category) =>
      _dio.get('/filter.php', queryParameters: {'c': category});

  /// Фильтр по бокалу: /filter.php?g=Highball_glass
  Future<Response> filterByGlass(String glass) =>
      _dio.get('/filter.php', queryParameters: {'g': glass});

  /// Получить список категорий: /list.php?c=list
  Future<Response> listCategories() =>
      _dio.get('/list.php', queryParameters: {'c': 'list'});

  /// Получить список бокалов: /list.php?g=list
  Future<Response> listGlasses() =>
      _dio.get('/list.php', queryParameters: {'g': 'list'});

  /// Получить список алкоголя: /list.php?a=list
  Future<Response> listAlcoholic() =>
      _dio.get('/list.php', queryParameters: {'a': 'list'});
}
