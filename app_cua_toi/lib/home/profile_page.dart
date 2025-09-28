// Import thư viện Material (cung cấp widget UI chính của Flutter)
import 'package:flutter/material.dart';

// ProfilePage là một StatelessWidget (không có trạng thái thay đổi)
// Nhận vào tham số `name` và `email` để hiển thị thông tin người dùng
class ProfilePage extends StatelessWidget {
  final String name; // tên người dùng
  final String email; // email người dùng

  // Constructor (có giá trị mặc định nếu không truyền vào)
  const ProfilePage({
    super.key,
    this.name = "Nguyễn Văn A", // tên mặc định (demo)
    this.email = "nguyenvana@gmail.com", // email mặc định (demo)
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar (thanh trên cùng)
      appBar: AppBar(
        title: const Text("Profile"), // tiêu đề thanh AppBar
        backgroundColor: Colors.brown, // màu nền AppBar
      ),

      // Nội dung chính của trang
      body: Padding(
        padding: const EdgeInsets.all(20), // lề xung quanh nội dung
        child: Column(
          children: [
            // ====== Avatar người dùng ======
            const CircleAvatar(
              radius: 50, // bán kính (kích thước avatar)
              backgroundImage: AssetImage("assets/logo_coffee.png"),
              // hình ảnh trong thư mục assets (cần khai báo trong pubspec.yaml)
            ),
            const SizedBox(height: 20), // khoảng cách
            // ====== Hiển thị Tên người dùng ======
            Text(
              name, // lấy từ biến name
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold, // chữ đậm
              ),
            ),

            const SizedBox(height: 8), // khoảng cách nhỏ
            // ====== Hiển thị Email ======
            Text(
              email, // lấy từ biến email
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey, // chữ màu xám
              ),
            ),

            const SizedBox(height: 30), // khoảng cách lớn
            // ====== Nút chỉnh sửa thông tin ======
            ElevatedButton.icon(
              onPressed: () {
                // sau này bạn có thể chuyển sang trang UpdateProfile ở đây
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown, // màu nền nút
                foregroundColor: Colors.white, // màu chữ + icon
                padding: const EdgeInsets.symmetric(
                  horizontal: 24, // lề ngang trong nút
                  vertical: 12, // lề dọc trong nút
                ),
              ),
              icon: const Icon(Icons.edit), // icon bút chỉnh sửa
              label: const Text("Chỉnh sửa thông tin"), // chữ trong nút
            ),

            const Spacer(), // đẩy nội dung bên trên lên, để nút đăng xuất nằm dưới cùng
            // ====== Nút đăng xuất ======
            ElevatedButton(
              onPressed: () {
                // Quay lại LoginPage và thay thế trang hiện tại (không cho back về Profile nữa)
                Navigator.pushReplacementNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // nền đỏ
                foregroundColor: Colors.white, // chữ trắng
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text("Đăng xuất"), // chữ trong nút
            ),
          ],
        ),
      ),
    );
  }
}
