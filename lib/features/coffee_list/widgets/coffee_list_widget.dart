import 'package:flutter/material.dart';

class coffeeList extends StatelessWidget {
  const coffeeList({
    super.key,
    required this.coffeeName,
  });

  final String coffeeName;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: 20,
      
      itemBuilder: (context,i)=>  ListTile(                                                                         
          trailing: Icon(Icons.arrow_forward_ios),
          leading: Image.asset("images/1.png"),
          title: Text(                          
              coffeeName,                            
              style:  Theme.of(context).textTheme.bodyMedium,        
          ),
    
          subtitle: Text(
            '1000',                    
            style: Theme.of(context).textTheme.labelSmall,
            ),
    
             //щелакаем на айтаме
             onTap:() => {
                Navigator.of(context).pushNamed(
                   '/coffee',
                   arguments: coffeeName,
                )
          },
      
      ), separatorBuilder: (BuildContext context, int index) => Divider(color: const Color.fromARGB(26, 240, 238, 238),));
  }
}