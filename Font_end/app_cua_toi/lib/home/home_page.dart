import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../admin/category.dart';
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
  String? token;

  List<Drink> products = [];
  bool isLoading = true;

  // ✅ Thêm Set để lưu ID các sản phẩm yêu thích
  Set<String> favoriteIds = {};

  @override
  void initState() {
    super.initState();
    _loadToken();
    fetchProducts();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString("token");
    });
    if (token == null) {
      print("⚠️ Token chưa có, người dùng chưa đăng nhập!");
    } else {
      print("✅ Token đã tải: $token");
      fetchFavoriteIds(); // ✅ Load favorites sau khi có token
    }
  }

  // ✅ Lấy danh sách ID yêu thích từ server
  Future<void> fetchFavoriteIds() async {
    if (token == null) return;

    final url = Uri.parse("http://10.0.2.2:5000/api/favorites");

    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> favoritesJson = jsonDecode(response.body);
        setState(() {
          favoriteIds = favoritesJson
              .map((json) => json['_id']?.toString() ?? '')
              .where((id) => id.isNotEmpty)
              .toSet();
        });
        print("✅ Đã tải ${favoriteIds.length} ID yêu thích");
      }
    } catch (e) {
      print("⚠️ Lỗi tải favorites: $e");
    }
  }

  // 🟤 Hàm tải sản phẩm từ server
  Future<void> fetchProducts() async {
    try {
      final url = Uri.parse("http://10.0.2.2:5000/api/products/");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          products = data.map((e) => Drink.fromJson(e)).toList();
          isLoading = false;
        });
        print("✅ Đã tải ${products.length} sản phẩm từ server");
      } else {
        print("❌ Lỗi tải sản phẩm: ${response.statusCode} - ${response.body}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("⚠️ Lỗi kết nối server khi tải sản phẩm: $e");
      setState(() => isLoading = false);
    }
  }

  // 🟤 Hàm toggle yêu thích
  Future<void> toggleFavoriteOnServer(String productId) async {
    if (token == null) {
      print("⚠️ Không có token, không thể gửi yêu cầu!");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Vui lòng đăng nhập để sử dụng tính năng này"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final url = Uri.parse("http://10.0.2.2:5000/api/favorites/toggle");

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"productId": productId}),
      );

      if (response.statusCode == 200) {
        print("✅ Cập nhật yêu thích thành công: $productId");
      } else {
        print("❌ Lỗi đồng bộ: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("⚠️ Lỗi kết nối server: $e");
    }
  }

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
            onPressed: widget.goToCart,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : buildHome(filteredProducts),
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
                // ✅ Kiểm tra yêu thích bằng ID
                final isFavorite =
                    drink.id != null && favoriteIds.contains(drink.id);

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        transitionDuration: const Duration(milliseconds: 600),
                        pageBuilder: (_, animation, __) => SlideTransition(
                          position:
                              Tween<Offset>(
                                begin: const Offset(0, 1),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutCubic,
                                ),
                              ),
                          child: ProductDetailPage(
                            drink: drink,
                            cartList: widget.cartList,
                            favoriteList: widget.favoriteList,
                            favoriteIds: favoriteIds,
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
                            child: Image.network(
                              getImageUrl(drink.image),
                              fit: BoxFit.contain,
                              width: double.infinity,
                              height: 120,
                              errorBuilder: (context, error, stackTrace) {
                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.broken_image,
                                      size: 60,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Lỗi tải ảnh',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                );
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value:
                                            loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                            : null,
                                      ),
                                    );
                                  },
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
                                      // ✅ Dùng isFavorite thay vì contains
                                      isFavorite
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    onPressed: () async {
                                      if (drink.id == null ||
                                          drink.id!.length != 24) {
                                        print("⚠️ Sản phẩm chưa có ID hợp lệ");
                                        return;
                                      }

                                      // ✅ Toggle trên UI ngay lập tức (optimistic update)
                                      setState(() {
                                        if (isFavorite) {
                                          favoriteIds.remove(drink.id);
                                          widget.favoriteList.removeWhere(
                                            (d) => d.id == drink.id,
                                          );
                                        } else {
                                          favoriteIds.add(drink.id!);
                                          // Kiểm tra xem đã có trong list chưa
                                          if (!widget.favoriteList.any(
                                            (d) => d.id == drink.id,
                                          )) {
                                            widget.favoriteList.add(drink);
                                          }
                                        }
                                      });

                                      // ✅ Đồng bộ với server
                                      await toggleFavoriteOnServer(drink.id!);
                                      widget.refresh();
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
