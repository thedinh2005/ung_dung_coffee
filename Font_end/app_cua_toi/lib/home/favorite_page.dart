import 'package:app_cua_toi/admin/category.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritePage extends StatefulWidget {
  final List<Drink> favoriteList;
  final VoidCallback refresh;

  const FavoritePage({
    super.key,
    required this.favoriteList,
    required this.refresh,
  });

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  List<Drink> serverFavorites = [];
  bool isLoading = true;
  String? token;

  @override
  void initState() {
    super.initState();
    _loadTokenAndFavorites();
  }

  Future<void> _loadTokenAndFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("token");

    if (token != null) {
      await fetchFavoritesFromServer();
    } else {
      setState(() => isLoading = false);
      print("⚠️ Chưa đăng nhập!");
    }
  }

  // 📥 Lấy danh sách yêu thích từ server
  Future<void> fetchFavoritesFromServer() async {
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

        // ✅ Log để debug
        print("📦 Raw favorites response: ${response.body}");
        print("📦 Số lượng favorites: ${favoritesJson.length}");

        setState(() {
          serverFavorites = favoritesJson
              .map((json) {
                try {
                  return Drink.fromJson(json);
                } catch (e) {
                  print("❌ Lỗi parse item: $json");
                  print("❌ Chi tiết lỗi: $e");
                  return null;
                }
              })
              .where((drink) => drink != null)
              .cast<Drink>()
              .toList();
          isLoading = false;
        });

        print("✅ Đã tải ${serverFavorites.length} sản phẩm yêu thích");
      } else {
        print("❌ Lỗi: ${response.statusCode} - ${response.body}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("⚠️ Lỗi kết nối: $e");
      setState(() => isLoading = false);
    }
  }

  // 🗑️ Xóa khỏi yêu thích
  Future<void> removeFavorite(Drink drink) async {
    if (token == null || drink.id == null) return;

    final url = Uri.parse("http://10.0.2.2:5000/api/favorites/toggle");

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"productId": drink.id}),
      );

      if (response.statusCode == 200) {
        // ✅ Xóa bằng ID thay vì object
        setState(() {
          serverFavorites.removeWhere((d) => d.id == drink.id);
          widget.favoriteList.removeWhere((d) => d.id == drink.id);
        });
        widget.refresh();
        print("✅ Đã xóa khỏi yêu thích: ${drink.id}");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Đã xóa ${drink.name} khỏi yêu thích"),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        print("❌ Lỗi xóa: ${response.statusCode} - ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi xóa sản phẩm"),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print("⚠️ Lỗi: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Lỗi kết nối server"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Yêu thích"),
        backgroundColor: Colors.brown[300],
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() => isLoading = true);
              fetchFavoritesFromServer();
            },
            tooltip: "Làm mới",
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : serverFavorites.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 100,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Chưa có sản phẩm yêu thích",
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text("Khám phá ngay"),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: fetchFavoritesFromServer,
              child: ListView.builder(
                itemCount: serverFavorites.length,
                padding: EdgeInsets.all(12),
                itemBuilder: (context, index) {
                  final drink = serverFavorites[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: 12),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(12),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          getImageUrl(drink.image),
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 70,
                              height: 70,
                              color: Colors.grey[300],
                              child: Icon(
                                Icons.image_not_supported,
                                color: Colors.grey[600],
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: 70,
                              height: 70,
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      title: Text(
                        drink.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 4),
                          Text(
                            "${drink.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} đ",
                            style: TextStyle(
                              color: Colors.brown,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.star, size: 16, color: Colors.orange),
                              SizedBox(width: 4),
                              Text(
                                drink.rating.toString(),
                                style: TextStyle(fontSize: 13),
                              ),
                              SizedBox(width: 12),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.brown[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  drink.category,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.brown[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.favorite, color: Colors.red, size: 28),
                        onPressed: () => removeFavorite(drink),
                        tooltip: "Xóa khỏi yêu thích",
                      ),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/product-detail',
                          arguments: drink,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }
}
