import 'package:app_cua_toi/home/category.dart';
import 'package:flutter/material.dart';
// import 'cart_item.dart'; // file chứa class CartItem

class CartPage extends StatefulWidget {
  final List<CartItem> cartList;
  final VoidCallback refresh;

  const CartPage({super.key, required this.cartList, required this.refresh});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late Map<CartItem, int> cartMap;

  @override
  void initState() {
    super.initState();
    _buildCartMap();
  }

  @override
  void didUpdateWidget(CartPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _buildCartMap();
  }

  void _buildCartMap() {
    cartMap = {};
    for (var item in widget.cartList) {
      cartMap[item] = (cartMap[item] ?? 0) + item.quantity;
    }
  }

  void increaseQuantity(CartItem item) {
    setState(() {
      item.quantity++;
    });
    widget.refresh();
  }

  void decreaseQuantity(CartItem item) {
    setState(() {
      if (item.quantity > 1) {
        item.quantity--;
      } else {
        widget.cartList.remove(item);
      }
    });
    widget.refresh();
  }

  int get totalPrice {
    int sum = 0;
    for (var item in widget.cartList) {
      int optionPrice = item.option?.extraPrice ?? 0; // 👈 cộng thêm giá option
      sum += (item.drink.price + optionPrice) * item.quantity;
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.cartList;

    return Scaffold(
      appBar: AppBar(title: const Text("Giỏ hàng")),
      body: items.isEmpty
          ? const Center(child: Text("Giỏ hàng trống"))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      int optionPrice = item.option?.extraPrice ?? 0;
                      int unitPrice = item.drink.price + optionPrice;

                      return ListTile(
                        leading: Image.asset(item.drink.image, width: 50),
                        title: Text(item.drink.name),
                        subtitle: Text(
                          "$unitPrice VND x ${item.quantity} = ${unitPrice * item.quantity} VND",
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () => decreaseQuantity(item),
                            ),
                            Text("${item.quantity}"),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => increaseQuantity(item),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.centerRight,
                  child: Text(
                    "Tổng cộng: $totalPrice VND",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/favorite');
              break;
            case 2:
              break; // Cart
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
