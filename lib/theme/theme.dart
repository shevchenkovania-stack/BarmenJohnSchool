import 'package:flutter/material.dart';

final dartTheme = ThemeData(

        //настройка темы апп бара
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(255, 73, 79, 117),
          titleTextStyle: TextStyle(
            color:Colors.white24,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        
        // основной фон скафлда                
        scaffoldBackgroundColor: Color.fromARGB(255, 73, 79, 117),
        
        //Разделитель в листе продуктов
        dividerColor:            Colors.white24,     

        listTileTheme: ListTileThemeData(iconColor: Colors.white),              
        
        textTheme: const TextTheme(
          
          //Настройки основного тектса
          bodyMedium:               
              TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w200,
              fontSize :20             
              ),

          labelSmall:  TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w200,
              fontSize :12              
              ),

        ),

        colorScheme: ColorScheme.fromSeed(

          seedColor:  Colors.yellow,

          primary: Colors.yellow, // Установите основной цвет явно

        ),

        useMaterial3: true,

      );