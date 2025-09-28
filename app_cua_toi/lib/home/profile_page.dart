import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  final String name;
  final String email;
  final double walletBalance;

  const ProfilePage({
    super.key,
    this.name = "Nguyễn Văn A",
    this.email = "nguyenvana@gmail.com",
    this.walletBalance = 150000,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Tài khoản",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.brown,
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ====== Header (Avatar + Info) ======
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.brown,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 60, color: Colors.brown),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    email,
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ====== Wallet Card ======
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet,
                      size: 40,
                      color: Colors.brown,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        "Số dư ví: ${walletBalance.toStringAsFixed(0)} đ",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Nạp tiền"),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ====== Menu Options ======
            _buildMenuItem(
              icon: Icons.history,
              title: "Lịch sử giao dịch",
              color: Colors.blueGrey,
              onTap: () {},
            ),
            _buildMenuItem(
              icon: Icons.local_shipping,
              title: "Đơn hàng gần đây",
              subtitle: "Đã giao, đang giao",
              color: Colors.orange,
              onTap: () {},
            ),
            _buildMenuItem(
              icon: Icons.settings,
              title: "Cài đặt tài khoản",
              color: Colors.grey,
              onTap: () {},
            ),

            const SizedBox(height: 30),

            // ====== Logout Button ======
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                icon: const Icon(Icons.logout),
                label: const Text("Đăng xuất"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget tái sử dụng cho menu
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: color, size: 30),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
