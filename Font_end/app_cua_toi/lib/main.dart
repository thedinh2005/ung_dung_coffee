// Import thư viện Flutter Material (chứa các widget cơ bản như Scaffold, AppBar, Button...)

import 'package:flutter/material.dart';

// Import các file trang trong project
import 'home/home_page.dart'; // Trang chính (HomePage)
import 'home/favorite_page.dart'; // Trang Yêu thích
import 'home/cart_page.dart'; // Trang Giỏ hàng
import 'home/profile_page.dart'; // Trang Profile (thông tin cá nhân)
import 'admin/category.dart'; // File chứa class Drink và danh sách sản phẩm (products)
import 'home/login_page.dart'; // Trang Đăng nhập
import 'home/register_page.dart'; // Trang Đăng ký

// Import CartItem
// import 'home/cart_item.dart'; // file chứa class CartItem

// Hàm main() là điểm bắt đầu của ứng dụng
void main() {
  runApp(const MyApp()); // chạy widget MyApp làm root của ứng dụng
}

// Widget MyApp là StatelessWidget (không thay đổi trạng thái)
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner:
          false, // ẩn banner "debug" trên góc phải màn hình
      home:
          const LoginPage(), // 👇 mặc định mở trang Login đầu tiên khi chạy app
      routes: {
        '/login': (_) => const LoginPage(),
        '/register': (_) => const RegisterPage(),
        '/home': (_) => const CafeShopApp(),
      },
    );
  }
}

// CafeShopApp là StatefulWidget (có thể thay đổi trạng thái bên trong)
class CafeShopApp extends StatefulWidget {
  const CafeShopApp({super.key});

  @override
  State<CafeShopApp> createState() => _CafeShopAppState();
}

// State của CafeShopApp
class _CafeShopAppState extends State<CafeShopApp> {
  int _selectedIndex = 0; // lưu index tab hiện tại trong BottomNavigationBar

  // Danh sách Yêu thích và Giỏ hàng
  List<Drink> favoriteList = [];
  List<CartItem> cartList = []; // 👈 đổi từ Drink -> CartItem

  @override
  void initState() {
    super.initState();
    //muốn thêm thì vô đây
    // Future.microtask(() => syncProductsToServer(products));
  }

  void refresh() => setState(() {});

  void goToCart() {
    setState(() {
      _selectedIndex = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      CafeHomePage(
        favoriteList: favoriteList,
        cartList: cartList,
        refresh: refresh,
        goToCart: goToCart,
      ),
      FavoritePage(favoriteList: favoriteList, refresh: refresh),
      CartPage(cartList: cartList, refresh: refresh),
      const ProfilePage(),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.brown,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _selectedIndex = index),
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
