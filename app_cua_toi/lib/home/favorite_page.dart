import 'package:app_cua_toi/home/category.dart';
import 'package:flutter/material.dart';

class FavoritePage extends StatelessWidget {
  final List<Drink> favoriteList;
  final VoidCallback refresh; // thêm

  const FavoritePage({
    super.key,
    required this.favoriteList,
    required this.refresh, // thêm
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Yêu thích")),
      body: ListView.builder(
        itemCount: favoriteList.length,
        itemBuilder: (context, index) {
          final drink = favoriteList[index];
          return ListTile(
            leading: Image.asset(drink.image),
            title: Text(drink.name),
            subtitle: Text("${drink.price} VND"),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/');
              break;
            case 1:
              break; // Favorite
            case 2:
              Navigator.pushReplacementNamed(context, '/cart');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/profile');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: "Yêu thích",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: "Giỏ hàng",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
