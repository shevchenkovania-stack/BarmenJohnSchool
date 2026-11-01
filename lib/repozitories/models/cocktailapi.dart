import 'package:dio/dio.dart';

class CocktailApi 
{
    final http = Dio();

    // List all cocktails by first letter
    //получаем список всех коктелей на определенную букву  https://www.thecocktaildb.com/api/json/v1/1/search.php?f=a'
    Future <Response<dynamic>> ListAllCocktailsByFirstLetter(var letter) async
    {     
      return await http.get('https://www.thecocktaildb.com/api/json/v1/1/search.php?f=$letter');                  
    }
    
    Future <Response<dynamic>> ListAllIngredients () async
    {
      return await http.get('https://www.thecocktaildb.com/api/json/v1/1/list.php?i=list');
    }

    

  //   // Search ingredient by name www.thecocktaildb.com/api/json/v1/1/search.php?i=coffee
  //   Future <Response<dynamic>> SearchIngredientByName(var name) async
  //   {
  //    return await http.get('https://www.thecocktaildb.com/api/json/v1/1/search.php?i=$name');
  //   }
 
  // // Lookup full cocktail details by id
  // // www.thecocktaildb.com/api/json/v1/1/lookup.php?i=11007
  // Future <Response<dynamic>> LookupFullCocktailDetailsById(var id) async
  // {
  //   return await http.get('https://www.thecocktaildb.com/api/json/v1/1/lookup.php?i=$id');
  // }

  // // Lookup ingredient by ID
  // // www.thecocktaildb.com/api/json/v1/1/lookup.php?iid=552
  // Future <Response<dynamic>> LookupIngredientByID(var id) async
  // {
  //   return await http.get('www.thecocktaildb.com/api/json/v1/1/lookup.php?iid=$id');
  // }

  // Lookup a random cocktail
  // www.thecocktaildb.com/api/json/v1/1/random.php

  // Lookup a selection of 10 random cocktails *Premium API only
  // www.thecocktaildb.com/api/json/v1/1/randomselection.php
  
  // Search by ingredient
  // www.thecocktaildb.com/api/json/v1/1/filter.php?i=Gin
  // www.thecocktaildb.com/api/json/v1/1/filter.php?i=Vodka

  // Filter by alcoholic
  // www.thecocktaildb.com/api/json/v1/1/filter.php?a=Alcoholic
  // www.thecocktaildb.com/api/json/v1/1/filter.php?a=Non_Alcoholic

  // Filter by Category
  // www.thecocktaildb.com/api/json/v1/1/filter.php?c=Ordinary_Drink
  // www.thecocktaildb.com/api/json/v1/1/filter.php?c=Cocktail

  // Filter by Glass
  // www.thecocktaildb.com/api/json/v1/1/filter.php?g=Cocktail_glass
  // www.thecocktaildb.com/api/json/v1/1/filter.php?g=Champagne_flute

 // List the categories, glasses, ingredients or alcoholic filters
 // www.thecocktaildb.com/api/json/v1/1/list.php?c=list
 // www.thecocktaildb.com/api/json/v1/1/list.php?g=list
 // www.thecocktaildb.com/api/json/v1/1/list.php?i=list
 // www.thecocktaildb.com/api/json/v1/1/list.php?a=list



}