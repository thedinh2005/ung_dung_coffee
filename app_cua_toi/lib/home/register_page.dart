// Import thư viện Flutter Material (cung cấp các widget UI cơ bản)
import 'package:flutter/material.dart';

// RegisterPage là một StatefulWidget (cần quản lý trạng thái: textfield input, mật khẩu...)
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

// State của RegisterPage
class _RegisterPageState extends State<RegisterPage> {
  // Controller để lấy dữ liệu nhập từ TextField
  final TextEditingController nameCtrl = TextEditingController(); // Họ tên
  final TextEditingController emailCtrl = TextEditingController(); // Email
  final TextEditingController phoneCtrl =
      TextEditingController(); // Số điện thoại
  final TextEditingController passwordCtrl =
      TextEditingController(); // Mật khẩu

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Scaffold: khung chính của trang (chứa body, appBar...)
      body: Padding(
        padding: const EdgeInsets.all(
          20,
        ), // tạo khoảng cách xung quanh nội dung
        child: Center(
          // Đặt nội dung vào giữa màn hình
          child: SingleChildScrollView(
            // Cho phép cuộn nếu màn hình nhỏ (tránh bị tràn khi bàn phím mở)
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch, // giãn full chiều ngang
              children: [
                // Tiêu đề "Đăng ký"
                const Text(
                  "Đăng ký",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30), // khoảng cách 30px
                // ====== Nhập Họ tên ======
                TextField(
                  controller: nameCtrl, // gắn controller để lấy dữ liệu nhập
                  decoration: const InputDecoration(
                    labelText: "Họ và tên", // nhãn
                    prefixIcon: Icon(Icons.person), // icon người
                    border: OutlineInputBorder(), // khung viền
                  ),
                ),
                const SizedBox(height: 16), // khoảng cách
                // ====== Nhập Email ======
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.email), // icon email
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // ====== Nhập Số điện thoại ======
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: "Số điện thoại",
                    prefixIcon: Icon(Icons.phone), // icon điện thoại
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // ====== Nhập Mật khẩu ======
                TextField(
                  controller: passwordCtrl,
                  obscureText: true, // ẩn ký tự (hiển thị dấu ●●●●)
                  decoration: const InputDecoration(
                    labelText: "Mật khẩu",
                    prefixIcon: Icon(Icons.lock), // icon ổ khóa
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),

                // ====== Nút Đăng ký ======
                ElevatedButton(
                  onPressed: () {
                    // Tạm thời chỉ hiển thị SnackBar thông báo thành công
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Đăng ký thành công!")),
                    );

                    // Sau khi đăng ký -> quay lại trang Login
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown, // màu nền nút
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                    ), // tăng chiều cao nút
                  ),
                  child: const Text(
                    "Đăng ký",
                    style: TextStyle(
                      fontSize: 18,
                      color: Color.fromARGB(255, 255, 255, 255),
                    ), // chữ to hơn
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
