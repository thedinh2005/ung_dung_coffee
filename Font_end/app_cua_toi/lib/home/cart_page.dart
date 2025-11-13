import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../admin/category.dart';

class CartPage extends StatefulWidget {
  final List<CartItem> cartList;
  final VoidCallback refresh;

  const CartPage({super.key, required this.cartList, required this.refresh});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool isLoading = false;
  String? token;
  int serverTotalAmount = 0;
  int serverItemCount = 0;

  // ✅ Base URL - thay đổi theo môi trường của bạn
  final String baseUrl = 'http://10.0.2.2:5000/api';

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchCart();
  }

  // ✅ Tải token và lấy giỏ hàng từ server
  Future<void> _loadTokenAndFetchCart() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("token");

    if (token != null) {
      await fetchCartFromServer();
    } else {
      print("⚠️ Không tìm thấy token");
    }
  }

  // 📥 Lấy giỏ hàng từ server
  Future<void> fetchCartFromServer() async {
    if (token == null) return;

    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cart'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          serverTotalAmount = data['totalAmount'] ?? 0;
          serverItemCount = data['itemCount'] ?? 0;
        });

        // Đồng bộ dữ liệu từ server vào cartList local
        if (data['items'] != null && data['items'].isNotEmpty) {
          _syncCartFromServer(data['items']);
        } else {
          // Giỏ hàng trống
          widget.cartList.clear();
          widget.refresh();
        }

        print(
          "✅ Đã tải giỏ hàng: $serverItemCount items, ${serverTotalAmount} VND",
        );
      } else {
        print("❌ Lỗi lấy giỏ hàng: ${response.statusCode}");
        _showErrorSnackBar("Không thể tải giỏ hàng");
      }
    } catch (e) {
      print("⚠️ Lỗi kết nối server: $e");
      _showErrorSnackBar("Lỗi kết nối server");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // 🔄 Đồng bộ dữ liệu từ server vào local cartList
  void _syncCartFromServer(List<dynamic> serverItems) {
    widget.cartList.clear();

    print("🔄 Bắt đầu đồng bộ ${serverItems.length} items từ server");

    for (var item in serverItems) {
      try {
        print("📦 Processing item: $item");

        // Lấy productId - có thể là String hoặc Object
        String? productId;
        if (item['productId'] is String) {
          productId = item['productId'];
        } else if (item['productId'] is Map) {
          productId = item['productId']['_id'];
        }

        final drink = Drink(
          id: productId ?? '',
          name: item['productName'] ?? '',
          image: item['productImage'] ?? '',
          price: (item['basePrice'] is int)
              ? item['basePrice']
              : int.tryParse(item['basePrice'].toString()) ?? 0,
          rating: 0.0,
          category: '',
          description: '',
        );

        Option? option;
        if (item['selectedOption'] != null &&
            item['selectedOption']['name'] != null &&
            item['selectedOption']['name'].toString().isNotEmpty) {
          option = Option(
            name: item['selectedOption']['name'].toString(),
            extraPrice: (item['selectedOption']['extraPrice'] is int)
                ? item['selectedOption']['extraPrice']
                : int.tryParse(
                        item['selectedOption']['extraPrice'].toString(),
                      ) ??
                      0,
          );
        }

        final cartItem = CartItem(
          drink: drink,
          option: option,
          quantity: (item['quantity'] is int)
              ? item['quantity']
              : int.tryParse(item['quantity'].toString()) ?? 1,
        );

        widget.cartList.add(cartItem);
        print("✅ Đã thêm: ${drink.name} x ${cartItem.quantity}");
      } catch (e) {
        print("❌ Lỗi khi parse item: $e");
        print("❌ Item data: $item");
      }
    }

    print("✅ Đồng bộ xong! Tổng: ${widget.cartList.length} items");
    widget.refresh();
  }

  // ➕ Tăng số lượng
  Future<void> increaseQuantity(CartItem item) async {
    final oldQuantity = item.quantity;

    setState(() {
      item.quantity++;
    });
    widget.refresh();

    final success = await updateCartOnServer(item);

    if (!success) {
      setState(() {
        item.quantity = oldQuantity;
      });
      widget.refresh();
    }
  }

  // ➖ Giảm số lượng
  Future<void> decreaseQuantity(CartItem item) async {
    if (item.quantity > 1) {
      final oldQuantity = item.quantity;

      setState(() {
        item.quantity--;
      });
      widget.refresh();

      final success = await updateCartOnServer(item);

      if (!success) {
        setState(() {
          item.quantity = oldQuantity;
        });
        widget.refresh();
      }
    } else {
      await removeFromCart(item);
    }
  }

  // 🔄 Cập nhật số lượng trên server
  Future<bool> updateCartOnServer(CartItem item) async {
    if (token == null || item.drink.id == null) {
      _showErrorSnackBar("Thiếu thông tin xác thực");
      return false;
    }

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/cart/update'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'productId': item.drink.id,
          'optionName': item.option?.name ?? '',
          'quantity': item.quantity,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          serverTotalAmount = data['cart']['totalAmount'] ?? 0;
          serverItemCount = data['cart']['itemCount'] ?? 0;
        });
        print("✅ Đã cập nhật số lượng: ${item.quantity}");
        return true;
      } else {
        print("❌ Lỗi cập nhật: ${response.statusCode}");
        _showErrorSnackBar("Không thể cập nhật số lượng");
        return false;
      }
    } catch (e) {
      print("⚠️ Lỗi kết nối: $e");
      _showErrorSnackBar("Lỗi kết nối server");
      return false;
    }
  }

  // 🗑️ Xóa sản phẩm khỏi giỏ hàng
  Future<void> removeFromCart(CartItem item) async {
    if (token == null || item.drink.id == null) {
      _showErrorSnackBar("Thiếu thông tin xác thực");
      return;
    }

    final itemIndex = widget.cartList.indexOf(item);
    final removedItem = item;

    setState(() {
      widget.cartList.remove(item);
    });
    widget.refresh();

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/cart/remove'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'productId': item.drink.id,
          'optionName': item.option?.name ?? '',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          serverTotalAmount = data['cart']['totalAmount'] ?? 0;
          serverItemCount = data['cart']['itemCount'] ?? 0;
        });

        print("✅ Đã xóa sản phẩm: ${item.drink.name}");
        _showSuccessSnackBar("Đã xóa sản phẩm khỏi giỏ hàng");
      } else {
        print("❌ Lỗi xóa: ${response.statusCode}");
        setState(() {
          widget.cartList.insert(itemIndex, removedItem);
        });
        widget.refresh();
        _showErrorSnackBar("Không thể xóa sản phẩm");
      }
    } catch (e) {
      print("⚠️ Lỗi kết nối: $e");
      setState(() {
        widget.cartList.insert(itemIndex, removedItem);
      });
      widget.refresh();
      _showErrorSnackBar("Lỗi kết nối server");
    }
  }

  // 🗑️ Xóa toàn bộ giỏ hàng
  Future<void> clearCart() async {
    if (token == null) {
      _showErrorSnackBar("Thiếu thông tin xác thực");
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận"),
        content: const Text("Bạn có chắc muốn xóa toàn bộ giỏ hàng?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Xóa",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final oldCartList = List<CartItem>.from(widget.cartList);
    final oldTotalAmount = serverTotalAmount;
    final oldItemCount = serverItemCount;

    setState(() {
      widget.cartList.clear();
      serverTotalAmount = 0;
      serverItemCount = 0;
    });
    widget.refresh();

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/cart/clear'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        print("✅ Đã xóa toàn bộ giỏ hàng");
        _showSuccessSnackBar("Đã xóa toàn bộ giỏ hàng");
      } else {
        print("❌ Lỗi xóa: ${response.statusCode}");
        setState(() {
          widget.cartList.addAll(oldCartList);
          serverTotalAmount = oldTotalAmount;
          serverItemCount = oldItemCount;
        });
        widget.refresh();
        _showErrorSnackBar("Không thể xóa giỏ hàng");
      }
    } catch (e) {
      print("⚠️ Lỗi kết nối: $e");
      setState(() {
        widget.cartList.addAll(oldCartList);
        serverTotalAmount = oldTotalAmount;
        serverItemCount = oldItemCount;
      });
      widget.refresh();
      _showErrorSnackBar("Lỗi kết nối server");
    }
  }

  // 📦 Xử lý checkout
  Future<void> _handleCheckout(Map<String, dynamic> checkoutData) async {
    if (token == null) {
      Navigator.pop(context);
      _showErrorSnackBar("Thiếu thông tin xác thực");
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'customerName': checkoutData['name'],
          'customerPhone': checkoutData['phone'],
          'deliveryAddress': checkoutData['address'],
          'note': checkoutData['note'],
          'paymentMethod': checkoutData['paymentMethod'],
          'totalAmount': checkoutData['totalAmount'],
        }),
      );

      Navigator.pop(context);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        widget.cartList.clear();
        setState(() {
          serverTotalAmount = 0;
          serverItemCount = 0;
        });
        widget.refresh();

        if (!mounted) return;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 30),
                SizedBox(width: 10),
                Text("Đặt hàng thành công!"),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Mã đơn hàng: ${data['order']?['orderNumber'] ?? 'N/A'}"),
                const SizedBox(height: 8),
                Text(
                  "Tổng tiền: ${checkoutData['totalAmount']} VND",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Cảm ơn bạn đã đặt hàng! Chúng tôi sẽ liên hệ với bạn sớm nhất.",
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Chỉ đóng dialog thông báo
                },
                child: const Text("Đóng"),
              ),
            ],
          ),
        );

        print("✅ Đặt hàng thành công");
      } else {
        print("❌ Lỗi đặt hàng: ${response.statusCode}");
        print("Response: ${response.body}");
        _showErrorSnackBar("Không thể đặt hàng. Vui lòng thử lại!");
      }
    } catch (e) {
      Navigator.pop(context);
      print("⚠️ Lỗi kết nối: $e");
      _showErrorSnackBar("Lỗi kết nối server");
    }
  }

  // 🛒 Hiển thị Checkout Bottom Sheet
  void _showCheckoutBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CheckoutBottomSheet(
        totalAmount: serverTotalAmount > 0
            ? serverTotalAmount
            : localTotalPrice,
        onCheckout: _handleCheckout,
      ),
    );
  }

  // 💰 Tính tổng tiền local (fallback)
  int get localTotalPrice {
    int sum = 0;
    for (var item in widget.cartList) {
      int optionPrice = item.option?.extraPrice ?? 0;
      sum += (item.drink.price + optionPrice) * item.quantity;
    }
    return sum;
  }

  // 🎨 Helper methods cho SnackBar
  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.cartList;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Giỏ hàng (${items.length})",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_forever),
              onPressed: clearCart,
              tooltip: "Xóa toàn bộ",
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchCartFromServer,
            tooltip: "Làm mới",
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.shopping_cart_outlined,
                    size: 100,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Giỏ hàng trống",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.shopping_bag),
                    onPressed: () => Navigator.pop(context),
                    label: const Text("Tiếp tục mua sắm"),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.blue.shade50,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Tổng sản phẩm: $serverItemCount",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        "Tổng tiền: ${serverTotalAmount > 0 ? serverTotalAmount : localTotalPrice} VND",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      int optionPrice = item.option?.extraPrice ?? 0;
                      int unitPrice = item.drink.price + optionPrice;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        elevation: 2,
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child:
                                item.drink.image.startsWith('http') ||
                                    item.drink.image.startsWith('/uploads')
                                ? Image.network(
                                    item.drink.image.startsWith('http')
                                        ? item.drink.image
                                        : 'http://10.0.2.2:5000${item.drink.image}',
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.image_not_supported),
                                  )
                                : Image.asset(
                                    item.drink.image,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          title: Text(
                            item.drink.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (item.option != null &&
                                  item.option!.name.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    item.option!.name,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Text(
                                "${unitPrice} VND",
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                "Tổng: ${unitPrice * item.quantity} VND",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.remove_circle,
                                  color: Colors.red,
                                  size: 28,
                                ),
                                onPressed: () => decreaseQuantity(item),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "${item.quantity}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.add_circle,
                                  color: Colors.green,
                                  size: 28,
                                ),
                                onPressed: () => increaseQuantity(item),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 5,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Tổng cộng:",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "${serverTotalAmount > 0 ? serverTotalAmount : localTotalPrice} VND",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 3,
                          ),
                          onPressed: items.isEmpty
                              ? null
                              : _showCheckoutBottomSheet,
                          child: const Text(
                            "Thanh toán",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// 🛒 Checkout Bottom Sheet Widget
class _CheckoutBottomSheet extends StatefulWidget {
  final int totalAmount;
  final Function(Map<String, dynamic>) onCheckout;

  const _CheckoutBottomSheet({
    required this.totalAmount,
    required this.onCheckout,
  });

  @override
  State<_CheckoutBottomSheet> createState() => _CheckoutBottomSheetState();
}

class _CheckoutBottomSheetState extends State<_CheckoutBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();

  String _paymentMethod = 'cash';
  bool _isProcessing = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _handleCheckout() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isProcessing = true);

      final checkoutData = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'note': _noteController.text.trim(),
        'paymentMethod': _paymentMethod,
        'totalAmount': widget.totalAmount,
      };

      widget.onCheckout(checkoutData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text(
                    "Thông tin thanh toán",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: "Họ và tên *",
                      hintText: "Nhập họ và tên của bạn",
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Vui lòng nhập họ tên";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: "Số điện thoại *",
                      hintText: "Nhập số điện thoại",
                      prefixIcon: const Icon(Icons.phone),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Vui lòng nhập số điện thoại";
                      }
                      if (value.trim().length < 10) {
                        return "Số điện thoại không hợp lệ";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: "Địa chỉ giao hàng *",
                      hintText: "Nhập địa chỉ chi tiết",
                      prefixIcon: const Icon(Icons.location_on),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignLabelWithHint: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Vui lòng nhập địa chỉ";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _noteController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: "Ghi chú (tuỳ chọn)",
                      hintText: "Thêm ghi chú cho đơn hàng",
                      prefixIcon: const Icon(Icons.note),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Phương thức thanh toán",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildPaymentOption(
                    value: 'cash',
                    title: 'Tiền mặt',
                    subtitle: 'Thanh toán khi nhận hàng',
                    icon: Icons.money,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 8),
                  _buildPaymentOption(
                    value: 'momo',
                    title: 'Ví MoMo',
                    subtitle: 'Thanh toán qua ví điện tử MoMo',
                    icon: Icons.account_balance_wallet,
                    color: Colors.pink,
                  ),
                  const SizedBox(height: 8),
                  _buildPaymentOption(
                    value: 'banking',
                    title: 'Chuyển khoản',
                    subtitle: 'Chuyển khoản ngân hàng',
                    icon: Icons.account_balance,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Tổng thanh toán:",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          "${widget.totalAmount} VND",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                      ),
                      onPressed: _isProcessing ? null : _handleCheckout,
                      child: _isProcessing
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Xác nhận đặt hàng",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaymentOption({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _paymentMethod == value;

    return InkWell(
      onTap: () {
        setState(() {
          _paymentMethod = value;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _paymentMethod,
              onChanged: (val) {
                setState(() {
                  _paymentMethod = val!;
                });
              },
              activeColor: color,
            ),
          ],
        ),
      ),
    );
  }
}
