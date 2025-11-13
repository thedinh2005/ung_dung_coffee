import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:shared_preferences/shared_preferences.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailPhoneCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();

  bool isLoading = false;
  bool isPasswordVisible = false;

  /// 🔧 Xác định URL server (theo nền tảng)
  String getBaseUrl() {
    const endpoint = '/api/users/login';

    if (kIsWeb) {
      return 'http://localhost:5000$endpoint'; // Web
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000$endpoint'; // Android Emulator
    } else {
      return 'http://localhost:5000$endpoint'; // Windows / iOS / macOS
    }
  }

  /// 🟤 Hàm đăng nhập người dùng
  Future<void> loginUser() async {
    final input = emailPhoneCtrl.text.trim();
    final password = passwordCtrl.text.trim();

    if (input.isEmpty || password.isEmpty) {
      showSnack('⚠️ Vui lòng nhập đầy đủ thông tin');
      return;
    }

    setState(() => isLoading = true);

    try {
      final url = Uri.parse(getBaseUrl());
      final isEmail = input.contains('@');

      final body = isEmail
          ? {'email': input, 'password': password}
          : {'phone_number': input, 'password': password};

      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        await saveUserData(data);
        showSnack('✅ Đăng nhập thành công!');

        final role = data['user']['role'] ?? 'buyer';
        if (role == 'admin') {
          Navigator.pushReplacementNamed(context, '/admin');
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        showSnack(data['message'] ?? '❌ Sai tài khoản hoặc mật khẩu');
      }
    } catch (e) {
      showSnack('🚫 Không thể kết nối tới server.\nLỗi: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// 💾 Lưu dữ liệu người dùng vào SharedPreferences
  Future<void> saveUserData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final user = data['user'];

    await prefs.setString('token', data['token'] ?? '');
    await prefs.setString('userId', user['id'] ?? '');
    await prefs.setString('username', user['username'] ?? '');
    await prefs.setString('email', user['email'] ?? '');
    await prefs.setString('phone_number', user['phone_number'] ?? '');
    await prefs.setString('role', user['role'] ?? 'buyer');
    await prefs.setDouble(
      'walletBalance',
      (user['walletBalance'] ?? 0).toDouble(),
    );
  }

  /// 🟢 Hiển thị SnackBar
  void showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 100, color: Colors.brown),
              const SizedBox(height: 20),
              const Text(
                'Đăng nhập',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
              const SizedBox(height: 30),

              // 🟤 Email / SĐT
              TextField(
                controller: emailPhoneCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email hoặc Số điện thoại',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              // 🟤 Mật khẩu
              TextField(
                controller: passwordCtrl,
                obscureText: !isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() => isPasswordVisible = !isPasswordVisible);
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              // 🟤 Nút đăng nhập
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : loginUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Đăng nhập',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // 🟤 Link đăng ký
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Chưa có tài khoản? "),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterPage()),
                      );
                    },
                    child: const Text(
                      "Đăng ký ngay",
                      style: TextStyle(color: Colors.brown),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
