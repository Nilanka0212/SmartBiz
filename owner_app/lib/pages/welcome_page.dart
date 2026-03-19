import 'package:flutter/material.dart';
import '../main.dart';
import '../providers/language_provider.dart';
import 'language_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = MyApp.of(context)?.language ?? AppLanguage.english;
    final s = AppStrings(lang);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.orange, width: 2),
                ),
                child: const Icon(Icons.storefront, size: 60, color: Colors.orange),
              ),
              const SizedBox(height: 20),
              const Text('ShopFlow',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87)),
              Text(s.appTagline,
                  style: const TextStyle(fontSize: 14, color: Colors.black45)),
              const SizedBox(height: 30),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  children: [
                    Text(s.welcomeTitle,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _bizIcon(Icons.restaurant, 'Food'),
                        _bizIcon(Icons.checkroom, 'Clothing'),
                        _bizIcon(Icons.shopping_basket, 'Grocery'),
                        _bizIcon(Icons.edit, 'Stationery'),
                        _bizIcon(Icons.category, 'Other'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(s.welcomeDesc,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: Colors.black54)),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LanguagePage()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(s.registerBtn,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${s.alreadyAccount}  ',
                      style: const TextStyle(color: Colors.black54, fontSize: 14)),
                  GestureDetector(
                    onTap: () {},
                    child: Text(s.loginBtn,
                        style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ],
              ),
              const Spacer(),
              const Text('ShopFlow v1.0', style: TextStyle(fontSize: 11, color: Colors.black26)),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bizIcon(IconData icon, String label) {
    return Column(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: Colors.white,
          child: Icon(icon, color: Colors.orange, size: 22),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54)),
      ],
    );
  }
}