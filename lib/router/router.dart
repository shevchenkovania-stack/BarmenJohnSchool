import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coin/features/coffee_list/view/coffee_list_screen.dart';
import 'package:coin/features/coffee_single/view/coffee_single_screen.dart';
import 'package:coin/features/cost_calculator/view/bottle_prices_screen.dart';
import 'package:coin/core/services/cost_calculator_service.dart';

final routes = {
        
        '/coffee-list' : (context) => coffeeListScreen(title: 'coffee'),

        '/coffee' : (context) => coffeeSingle(),
        
        '/bottle-prices' : (context) => ChangeNotifierProvider.value(
          value: Provider.of<CostCalculatorService>(context, listen: false),
          child: const BottlePricesScreen(),
        ),
      };