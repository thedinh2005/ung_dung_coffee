import 'package:flutter/material.dart';
import 'category.dart';
import 'product_detail_page.dart';

class CafeHomePage extends StatefulWidget {
  final List<Drink> favoriteList;
  final List<CartItem> cartList;
  final VoidCallback refresh;
  final VoidCallback goToCart;

  const CafeHomePage({
    super.key,
    required this.favoriteList,
    required this.cartList,
    required this.refresh,
    required this.goToCart,
  });

  @override
  State<CafeHomePage> createState() => _CafeHomePageState();
}

class _CafeHomePageState extends State<CafeHomePage> {
  String selectedCategory = "Coffee";

  @override
  Widget build(BuildContext context) {
    List<Drink> filteredProducts = products
        .where((p) => p.category == selectedCategory)
        .toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Image.asset(
          "assets/logo_coffee_preview_rev_1.png",
          height: 160,
          width: 90,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: Colors.black),
            onPressed: widget.goToCart, // 👈 gọi hàm đổi sang tab giỏ hàng
          ),
        ],
      ),
      body: buildHome(filteredProducts),
    );
  }

  Widget buildHome(List<Drink> filteredProducts) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thanh tìm kiếm
            TextField(
              decoration: InputDecoration(
                hintText: "Tìm cafe, trà, smoothie...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            const SizedBox(height: 16),

            // Banner
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset("assets/bia_coffe.jpg"),
            ),
            const SizedBox(height: 16),

            // Menu danh mục
            SizedBox(
              height: 90,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: ["Coffee", "Tea", "Chocolate", "Milk Tea"].map((cat) {
                  bool isSelected = cat == selectedCategory;
                  return GestureDetector(
                    onTap: () => setState(() => selectedCategory = cat),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.brown[100] : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(2, 2),
                          ),
                        ],
                        border: Border.all(
                          color: isSelected ? Colors.brown : Colors.grey,
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            cat == "Coffee"
                                ? Icons.coffee
                                : cat == "Tea"
                                ? Icons.local_cafe
                                : cat == "Chocolate"
                                ? Icons.coffee_outlined
                                : Icons.emoji_food_beverage,
                            color: isSelected ? Colors.brown : Colors.grey,
                            size: 28,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            cat,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? Colors.brown[800]
                                  : Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              selectedCategory,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Grid sản phẩm
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.7,
              children: filteredProducts.map((drink) {
                return GestureDetector(
                  onTap: () {
                    //khi ấn mỗi sản phẩm thì trang chi tiết sẽ hiện
                    Navigator.push(
                      context,
                      //cách hiển thị thông thường
                      //   MaterialPageRoute(
                      //     builder: (_) => ProductDetailPage(
                      //       drink: drink,
                      //       cartList: widget.cartList,
                      //       favoriteList: widget.favoriteList,
                      //       refresh: widget.refresh,
                      //     ),
                      //   ),
                      // );
                      //animation kéo lên
                      PageRouteBuilder(
                        transitionDuration: const Duration(milliseconds: 600),
                        pageBuilder: (_, animation, __) => SlideTransition(
                          position:
                              Tween<Offset>(
                                begin: const Offset(0, 1), // từ dưới lên
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutCubic,
                                ),
                              ),
                          child: ProductDetailPage(
                            // lấy từ trang chi tiết sản phẩm
                            drink: drink,
                            cartList: widget.cartList,
                            favoriteList: widget.favoriteList,
                            refresh: widget.refresh,
                          ),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(3, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ảnh sản phẩm
                        Expanded(
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(8),
                            child: Image.asset(
                              drink.image,
                              fit: BoxFit.contain,
                              width: double.infinity,
                              height: 120,
                            ),
                          ),
                        ),

                        // thông tin sản phẩm
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                drink.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${drink.price} VND",
                                style: const TextStyle(
                                  color: Colors.brown,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    size: 16,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    drink.rating.toString(),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: Icon(
                                      widget.favoriteList.contains(drink)
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        if (widget.favoriteList.contains(
                                          drink,
                                        )) {
                                          widget.favoriteList.remove(drink);
                                        } else {
                                          widget.favoriteList.add(drink);
                                        }
                                        widget.refresh();
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
