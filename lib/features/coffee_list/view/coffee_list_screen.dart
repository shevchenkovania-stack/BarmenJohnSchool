import 'package:flutter/material.dart';
import 'package:coin/repozitories/cocktail_repozitory.dart';
import 'package:coin/repozitories/models/cocktail.dart';

  class coffeeListScreen extends StatefulWidget {
  
  const coffeeListScreen({super.key, required this.title});

  final String title;

  @override
  State<coffeeListScreen> createState() => _coffeeListScreenState();
}

class _coffeeListScreenState extends State<coffeeListScreen> {

  List<Cocktail> cocktails =List.empty();
  
  List<String> ingredients = List.empty();




  CocktailRepository coctailRepository = CocktailRepository();

  final TextEditingController  _searchController = TextEditingController();
  final ScrollController       _scrollController     = ScrollController(); 
  
  //метод скролит к выбранной позиции
  void _scrollToCocktail() {
    final query = _searchController.text.toLowerCase();

    // Найти индекс первого элемента, который соответствует введенной букве
    final index = cocktails.indexWhere(
      (cocktail) => cocktail.strDrink.toLowerCase().startsWith(query),
    );

    if (index != -1) {

        WidgetsBinding.instance.addPostFrameCallback((_) {
      // Прокрутить к этому элементу
      _scrollController.animateTo(
        index * 88.0, // Примерная высота элемента
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
    } 
    else {
      // Если элемент не найден, показать сообщение
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No cocktail found starting with "$query"'),
        ),
      );
    }
  }


  @override
  void initState() 
  {              
     _searchController.addListener(_scrollToCocktail);
   
    //получаем список всех коктелей
    getAllCocktails()
    .then((result) 
    {            
      //перерисовываем виджет
      setState(() {});    
    }); 

    getAllIngredients().then((result)
    {
      setState(() {});
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
  final theme = Theme.of(context);
  final coffeeName ='americano';

  

  return Scaffold
  (  
      body:  CustomScrollView(

        controller: _scrollController,
        slivers: [
          
         // App Bar
         SliverAppBar(
            backgroundColor: theme.primaryColor,
            pinned: true,
            snap: true,
            floating: true,
            centerTitle: true,
            title: const Text('JR Коктэйль',
             style: TextStyle(
             color: Color.fromARGB(255, 73, 79, 117),
            ),),

            elevation: 0,
            toolbarHeight: 30,
            surfaceTintColor: Colors.transparent,
            
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(88),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [

                    Expanded(

                      child: Container(
                        height: 48,
                        padding: EdgeInsets.all(7),
                        decoration: BoxDecoration(
                        color: theme.hintColor.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        ),

                                child:TextField(                         
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                  labelText: "Поиск коктейля",
                                  border: OutlineInputBorder(),
                                  suffixIcon: IconButton(
                                  icon: Icon(Icons.search), onPressed: () {  },                              
                                )
                                ),
                                ),

                      ),
                    ),
                   
                  ],
                ),
              ),
            ),
          ),
           
           
          SliverList.separated(
        
                        itemCount: cocktails.length,
                        
                        itemBuilder: (context,i)=>  ListTile(                                                                         
        
                            trailing: Icon(Icons.arrow_forward_ios),
                                    
                            leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0), // Указываем радиус закругления
                            child: Image.network(
                              cocktails[i].strDrinkThumb,
                              width: 60,
                              height: 70,
                              fit: BoxFit.cover,
                            ),
                          ),
        
                            title: Text(                          
                                cocktails[i].strDrink,                            
                                style:  Theme.of(context).textTheme.bodyMedium,        
                            ),
        
                            subtitle: Text(
                              cocktails[i].strAlcoholic,                             
                              style: Theme.of(context).textTheme.labelSmall,
                              ),
        
                               //щелакаем на айтаме
                               onTap:() => {
                                  Navigator.of(context).pushNamed(
                                     '/coffee',
                                     
                                     //передаем в качестве аргумента 
                                     arguments: cocktails[i],
                                  )
                            },
                        
                        ), separatorBuilder: (BuildContext context, int index) => Divider(color: Colors.white10,)),
        ],
        
      ),            
      
      );             
  }

  Future<void> getAllCocktails() async {
          
    cocktails = await coctailRepository.getAllCocktailsByAlphabet();
  }
  
  Future<void> getAllIngredients() async {

    ingredients = await coctailRepository.getAllIngredients();
  }

}

