import 'package:flutter/material.dart';
import '../services/auth_services.dart';
import 'welcome_page.dart';

class DashboardPage extends StatelessWidget {
  final Map<String, dynamic> owner;
  const DashboardPage({super.key, required this.owner});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Text('Welcome, ${owner['name'] ?? 'Owner'}!'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.clearLogin();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (_) => const WelcomePage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.storefront,
                size: 80, color: Colors.orange),
            const SizedBox(height: 20),
            Text(
              'Hello, ${owner['name'] ?? 'Owner'}!',
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              owner['shop_name'] ?? 'Your Shop',
              style: const TextStyle(
                  fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 30),
            const Text('Dashboard coming soon...',
                style: TextStyle(color: Colors.black45)),
          ],
        ),
      ),
    );
  }
}