import 'package:flutter/material.dart';
import 'category.dart'; // chứa class Drink và Option
// import 'cart_item.dart'; // chứa class CartItem

// 📌 Trang chi tiết sản phẩm
class ProductDetailPage extends StatefulWidget {
  final Drink drink; // Sản phẩm được chọn
  final List<CartItem> cartList; // Danh sách giỏ hàng (đổi thành CartItem)
  final List<Drink> favoriteList; // Danh sách yêu thích
  final VoidCallback refresh; // Hàm gọi lại để cập nhật UI

  const ProductDetailPage({
    super.key,
    required this.drink,
    required this.cartList,
    required this.favoriteList,
    required this.refresh,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int quantity = 0; // số lượng mặc định = 0
  Option? selectedOption; // tuỳ chọn size / topping

  @override
  void initState() {
    super.initState();
    // Nếu có option thì mặc định chọn option đầu tiên
    if (widget.drink.options.isNotEmpty) {
      selectedOption = widget.drink.options.first;
    }
  }

  // ✅ Hàm thêm vào giỏ hàng
  void addToCart() {
    if (quantity > 0) {
      // tìm xem trong giỏ đã có item này chưa (cùng drink + option)
      final existingItem = widget.cartList.firstWhere(
        (item) => item.drink == widget.drink && item.option == selectedOption,
        orElse: () => CartItem(drink: widget.drink, option: selectedOption),
      );

      if (widget.cartList.contains(existingItem)) {
        existingItem.quantity += quantity;
      } else {
        widget.cartList.add(
          CartItem(
            drink: widget.drink,
            option: selectedOption,
            quantity: quantity,
          ),
        );
      }

      widget.refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã thêm sản phẩm vào giỏ hàng")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // nền tổng thể
      body: SafeArea(
        child: Column(
          children: [
            // 🔹 Nội dung có thể cuộn
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 📌 Ảnh sản phẩm
                    Stack(
                      children: [
                        Container(
                          color: Colors.white,
                          width: double.infinity,
                          child: Image.asset(
                            widget.drink.image, // ảnh lấy từ Drink
                            height: 280,
                            fit: BoxFit.contain,
                          ),
                        ),
                        // nút back (góc trên trái)
                        Positioned(
                          top: 10,
                          left: 10,
                          child: CircleAvatar(
                            backgroundColor: Colors.black54,
                            child: IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // 📌 Giá + tên + rating
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.drink.name, // tên sản phẩm
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "${widget.drink.price} VND", // giá sản phẩm
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.orange,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "${widget.drink.rating} | Đã bán 1.2k",
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // 📌 Tuỳ chọn size (nếu có)
                    if (widget.drink.options.isNotEmpty)
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Chọn tuỳ chọn:",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            DropdownButton<Option>(
                              value: selectedOption,
                              isExpanded: true,
                              items: widget.drink.options
                                  .map(
                                    (opt) => DropdownMenuItem<Option>(
                                      value: opt,
                                      child: Text(
                                        "${opt.name} ${opt.extraPrice > 0 ? "(+${opt.extraPrice} VND)" : ""}",
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() => selectedOption = value);
                              },
                            ),
                          ],
                        ),
                      ),

                    // 📌 Chọn số lượng
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Số lượng:",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Row(
                            children: [
                              // nút giảm
                              IconButton(
                                icon: const Icon(
                                  Icons.remove_circle,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  if (quantity > 0) {
                                    setState(() => quantity--);
                                  }
                                },
                              ),
                              // hiển thị số lượng
                              Text(
                                "$quantity",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              // nút tăng
                              IconButton(
                                icon: const Icon(
                                  Icons.add_circle,
                                  color: Colors.green,
                                ),
                                onPressed: () {
                                  setState(() => quantity++);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // 📌 Mô tả sản phẩm
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Mô tả sản phẩm",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const Divider(), // gạch ngang
                          Text(
                            widget.drink.description,
                            style: const TextStyle(fontSize: 15, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 🔹 Thanh dưới cùng
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Row(
                children: [
                  // ❤️ Nút yêu thích
                  IconButton(
                    icon: Icon(
                      widget.favoriteList.contains(widget.drink)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: Colors.pink,
                      size: 32,
                    ),
                    onPressed: () {
                      setState(() {
                        if (widget.favoriteList.contains(widget.drink)) {
                          widget.favoriteList.remove(widget.drink);
                        } else {
                          widget.favoriteList.add(widget.drink);
                        }
                        widget.refresh(); // refresh UI
                      });
                    },
                  ),
                  const SizedBox(width: 10),

                  // 🛒 Nút thêm giỏ hàng
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: addToCart,
                      child: const Text(
                        "Thêm vào giỏ hàng",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
