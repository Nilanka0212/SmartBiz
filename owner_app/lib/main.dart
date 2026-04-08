import 'package:flutter/material.dart';
import 'pages/welcome_page.dart';
import 'providers/language_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<MyAppState>();

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  AppLanguage _language = AppLanguage.english;

  void setLanguage(AppLanguage lang) {
    setState(() => _language = lang);
  }

  AppLanguage get language => _language;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShopFlow',
      
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
        
      ),
      home: const WelcomePage(),
    );
  }
}
