import 'package:flutter/material.dart';
import '../../main.dart';
import '../../providers/language_provider.dart';
import '../register_page.dart';

class LanguagePage extends StatefulWidget {
  const LanguagePage({super.key});

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  AppLanguage? _selected;

  final List<Map<String, dynamic>> _languages = [
    {
      'lang': AppLanguage.english,
      'name': 'English',
      'sub': 'Continue in English',
      'flag': '🇬🇧',
    },
    {
      'lang': AppLanguage.sinhala,
      'name': 'සිංහල',
      'sub': 'සිංහලෙන් ඉදිරියට යන්න',
      'flag': '🇱🇰',
    },
    {
      'lang': AppLanguage.tamil,
      'name': 'தமிழ்',
      'sub': 'தமிழில் தொடரவும்',
      'flag': '🇱🇰',
    },
  ];

  void _continue() {
    if (_selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a language'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    MyApp.of(context)?.setLanguage(_selected!);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RegisterPage(strings: AppStrings(_selected!)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        title: const Text('Select Language',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.orange, width: 2),
              ),
              child: const Icon(Icons.language, size: 40, color: Colors.orange),
            ),
            const SizedBox(height: 16),
            const Text('Choose Your Language',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
            const Text('ඔබගේ භාෂාව තෝරන්න  /  உங்கள் மொழியை தேர்ந்தெடுங்கள்',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.black45)),

            const SizedBox(height: 40),

            // Language cards
            ..._languages.map((item) => _languageCard(
                  item['lang'] as AppLanguage,
                  item['flag'] as String,
                  item['name'] as String,
                  item['sub'] as String,
                )),

            const Spacer(),

            // Continue button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _continue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selected != null ? Colors.orange : Colors.grey.shade300,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  _selected != null
                      ? AppStrings(_selected!).continueBtn
                      : 'Select a language first',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _languageCard(AppLanguage lang, String flag, String name, String sub) {
    final isSelected = _selected == lang;
    return GestureDetector(
      onTap: () => setState(() => _selected = lang),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.orange.shade100, blurRadius: 8, offset: const Offset(0, 3))]
              : [],
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.orange : Colors.black87,
                      )),
                  Text(sub,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.orange.shade400 : Colors.black45,
                      )),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.orange : Colors.transparent,
                border: Border.all(
                  color: isSelected ? Colors.orange : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}