import 'package:coin/repozitories/models/cocktail.dart';
import 'package:flutter/material.dart';

class coffeeSingle extends StatefulWidget {
  const coffeeSingle({super.key});

 
  @override
  State<coffeeSingle> createState() => _coffeeSingleState();
}

class _coffeeSingleState extends State<coffeeSingle> {
  
  Cocktail cocktail = Cocktail(
    idDrink: "11007",
    strDrink: "Margarita",
    strCategory: "Ordinary Drink",
    strAlcoholic: "Alcoholic",
    strGlass: "Cocktail glass",
    strInstructions: "Rub the rim of the glass with lime and dip into salt. Shake all ingredients with ice, strain into the glass.",
    strDrinkThumb: "https://www.thecocktaildb.com/images/media/drink/5noda61589575158.jpg",
    strIngredient1: "Tequila",
    strIngredient2: "Triple sec",
    strIngredient3: "Lime juice",
    strIngredient4: "Salt",
    strIngredient5: "",
    strIngredient6: "",
    strIngredient7: "",
    strIngredient8: "",
    strIngredient9:"",
    strMeasure1: "1 1/2 oz",
  );
  

      @override
      void didChangeDependencies() {

      //получаем переданный аргументы
      final args = ModalRoute.of(context)?.settings.arguments;     

      if(args == null)
      {
        print('you must provide args');
        return;
      }
      
      cocktail = args as Cocktail;
     

      setState(() {});

        super.didChangeDependencies();
      }
      
  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text(cocktail.strDrink ?? '...'),
    ),
    body: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0), // Rounded corners
              child: Image.network(
                cocktail.strDrinkThumb,
                fit: BoxFit.cover,
                width: double.infinity, // Makes the image stretch to full width
                height: 250, // Set a fixed height for the image
              ),
            ),
            const SizedBox(height: 16), // Adds spacing between widgets
            Text('Название: ${cocktail.strDrink}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Категория: ${cocktail.strCategory}', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Алкогольный: ${cocktail.strAlcoholic}', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Стакан: ${cocktail.strGlass}', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            const Text('Ингредиенты:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (cocktail.strIngredient1.isNotEmpty) Text(cocktail.strIngredient1, style: TextStyle(fontSize: 16)),
            if (cocktail.strIngredient2.isNotEmpty) Text(cocktail.strIngredient2, style: TextStyle(fontSize: 16)),
            if (cocktail.strIngredient3.isNotEmpty) Text(cocktail.strIngredient3, style: TextStyle(fontSize: 16)),
            if (cocktail.strIngredient4.isNotEmpty) Text(cocktail.strIngredient4, style: TextStyle(fontSize: 16)),
            if (cocktail.strIngredient5.isNotEmpty) Text(cocktail.strIngredient5, style: TextStyle(fontSize: 16)),
            if (cocktail.strIngredient6.isNotEmpty) Text(cocktail.strIngredient6, style: TextStyle(fontSize: 16)),
            if (cocktail.strIngredient7.isNotEmpty) Text(cocktail.strIngredient7, style: TextStyle(fontSize: 16)),
            if (cocktail.strIngredient8.isNotEmpty) Text(cocktail.strIngredient8, style: TextStyle(fontSize: 16)),
            if (cocktail.strIngredient9.isNotEmpty) Text(cocktail.strIngredient9, style: TextStyle(fontSize: 16)),
            
            const SizedBox(height: 16),
            Text('Инструкция: ${cocktail.strInstructions}', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Мера: ${cocktail.strMeasure1}', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    ),
  );
}

}