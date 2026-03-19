import 'package:flutter/material.dart';

enum AppLanguage { english, sinhala, tamil }

class AppStrings {
  final AppLanguage language;
  const AppStrings(this.language);

  // ── Welcome Page ──
  String get appTagline => {
    AppLanguage.english: 'Your business in your hand',
    AppLanguage.sinhala: 'ඔබගේ ව්‍යාපාරය අතේ',
    AppLanguage.tamil:   'உங்கள் வணிகம் உங்கள் கையில்',
  }[language]!;

  String get welcomeTitle => {
    AppLanguage.english: 'Welcome!',
    AppLanguage.sinhala: 'ආයුබෝවන්!',
    AppLanguage.tamil:   'வரவேற்கிறோம்!',
  }[language]!;

  String get welcomeDesc => {
    AppLanguage.english: 'One app for all small business owners.',
    AppLanguage.sinhala: 'සියලුම කුඩා ව්‍යාපාරිකයන් සඳහා.',
    AppLanguage.tamil:   'அனைத்து சிறு வணிகர்களுக்கும் ஒரு செயலி.',
  }[language]!;

  String get registerBtn => {
    AppLanguage.english: 'Register',
    AppLanguage.sinhala: 'ලියාපදිංචි වන්න',
    AppLanguage.tamil:   'பதிவு செய்யுங்கள்',
  }[language]!;

  String get alreadyAccount => {
    AppLanguage.english: 'Already have an account?',
    AppLanguage.sinhala: 'දැනටමත් ගිණුමක් තිබේද?',
    AppLanguage.tamil:   'ஏற்கனவே கணக்கு உள்ளதா?',
  }[language]!;

  String get loginBtn => {
    AppLanguage.english: 'Login',
    AppLanguage.sinhala: 'පිවිසෙන්න',
    AppLanguage.tamil:   'உள்நுழைக',
  }[language]!;

  // ── Language Page ──
  String get chooseLanguage => {
    AppLanguage.english: 'Choose Your Language',
    AppLanguage.sinhala: 'ඔබගේ භාෂාව තෝරන්න',
    AppLanguage.tamil:   'உங்கள் மொழியை தேர்ந்தெடுங்கள்',
  }[language]!;

  String get continueBtn => {
    AppLanguage.english: 'Continue',
    AppLanguage.sinhala: 'ඉදිරියට යන්න',
    AppLanguage.tamil:   'தொடரவும்',
  }[language]!;

  // ── Register Page ──
  String get personalDetails => {
    AppLanguage.english: 'Personal Details',
    AppLanguage.sinhala: 'පෞද්ගලික තොරතුරු',
    AppLanguage.tamil:   'தனிப்பட்ட விவரங்கள்',
  }[language]!;

  String get shopDetails => {
    AppLanguage.english: 'Shop Details',
    AppLanguage.sinhala: 'කඩය පිළිබඳ තොරතුරු',
    AppLanguage.tamil:   'கடை விவரங்கள்',
  }[language]!;

  String get profilePhoto => {
    AppLanguage.english: 'Profile Photo *',
    AppLanguage.sinhala: 'පෞද්ගලික ඡායාරූපය *',
    AppLanguage.tamil:   'சுயவிவர புகைப்படம் *',
  }[language]!;

  String get photoAdded => {
    AppLanguage.english: 'Photo Added ✓',
    AppLanguage.sinhala: 'ඡායාරූපය එකතු විය ✓',
    AppLanguage.tamil:   'புகைப்படம் சேர்க்கப்பட்டது ✓',
  }[language]!;

  String get fullName => {
    AppLanguage.english: 'Full Name *',
    AppLanguage.sinhala: 'සම්පූර්ණ නම *',
    AppLanguage.tamil:   'முழு பெயர் *',
  }[language]!;

  String get phone => {
    AppLanguage.english: 'Phone Number *',
    AppLanguage.sinhala: 'දුරකථන අංකය *',
    AppLanguage.tamil:   'தொலைபேசி எண் *',
  }[language]!;

  String get nic => {
    AppLanguage.english: 'NIC Number *',
    AppLanguage.sinhala: 'ජාතික හැඳුනුම්පත *',
    AppLanguage.tamil:   'தேசிய அடையாள அட்டை *',
  }[language]!;

  String get password => {
    AppLanguage.english: 'Password *',
    AppLanguage.sinhala: 'මුරපදය *',
    AppLanguage.tamil:   'கடவுச்சொல் *',
  }[language]!;

  String get confirmPassword => {
    AppLanguage.english: 'Confirm Password *',
    AppLanguage.sinhala: 'මුරපදය තහවුරු කරන්න *',
    AppLanguage.tamil:   'கடவுச்சொல்லை உறுதிப்படுத்தவும் *',
  }[language]!;

  String get shopImage => {
    AppLanguage.english: 'Shop Image *',
    AppLanguage.sinhala: 'කඩය ඡායාරූපය *',
    AppLanguage.tamil:   'கடை படம் *',
  }[language]!;

  String get shopImageAdded => {
    AppLanguage.english: 'Image Added ✓',
    AppLanguage.sinhala: 'ඡායාරූපය එකතු විය ✓',
    AppLanguage.tamil:   'படம் சேர்க்கப்பட்டது ✓',
  }[language]!;

  String get shopName => {
    AppLanguage.english: 'Shop Name (Optional)',
    AppLanguage.sinhala: 'කඩයේ නම (අවශ්‍ය නැත)',
    AppLanguage.tamil:   'கடை பெயர் (விருப்பமானது)',
  }[language]!;

  String get category => {
    AppLanguage.english: 'Business Category *',
    AppLanguage.sinhala: 'ව්‍යාපාර වර්ගය *',
    AppLanguage.tamil:   'வணிக வகை *',
  }[language]!;

  String get location => {
    AppLanguage.english: 'Shop Location *',
    AppLanguage.sinhala: 'කඩයේ ස්ථානය *',
    AppLanguage.tamil:   'கடை இடம் *',
  }[language]!;

  String get nextBtn => {
    AppLanguage.english: 'Next →',
    AppLanguage.sinhala: 'ඊළඟ →',
    AppLanguage.tamil:   'அடுத்து →',
  }[language]!;

  String get backBtn => {
    AppLanguage.english: '← Back',
    AppLanguage.sinhala: '← ආපසු',
    AppLanguage.tamil:   '← பின்',
  }[language]!;

  String get submitBtn => {
    AppLanguage.english: 'Submit',
    AppLanguage.sinhala: 'ඉදිරිපත් කරන්න',
    AppLanguage.tamil:   'சமர்ப்பிக்கவும்',
  }[language]!;

  String get successTitle => {
    AppLanguage.english: 'Registration Successful! 🎉',
    AppLanguage.sinhala: 'ලියාපදිංචිය සාර්ථකයි! 🎉',
    AppLanguage.tamil:   'பதிவு வெற்றிகரமாக முடிந்தது! 🎉',
  }[language]!;

  String get successMsg => {
    AppLanguage.english: 'Welcome to ShopFlow!',
    AppLanguage.sinhala: 'ShopFlow වෙත සාදරයෙන් පිළිගනිමු!',
    AppLanguage.tamil:   'ShopFlow க்கு வரவேற்கிறோம்!',
  }[language]!;

  String get goHome => {
    AppLanguage.english: 'Go to Home',
    AppLanguage.sinhala: 'මුල් පිටුවට',
    AppLanguage.tamil:   'முகப்புக்கு செல்லவும்',
  }[language]!;

  // ── Validators ──
  String get enterName => {
    AppLanguage.english: 'Enter your name',
    AppLanguage.sinhala: 'නම ඇතුළු කරන්න',
    AppLanguage.tamil:   'உங்கள் பெயரை உள்ளிடவும்',
  }[language]!;

  String get enterPhone => {
    AppLanguage.english: 'Enter phone number',
    AppLanguage.sinhala: 'දුරකථන අංකය ඇතුළු කරන්න',
    AppLanguage.tamil:   'தொலைபேசி எண்ணை உள்ளிடவும்',
  }[language]!;

  String get invalidPhone => {
    AppLanguage.english: 'Enter valid phone number',
    AppLanguage.sinhala: 'වලංගු අංකයක් ඇතුළු කරන්න',
    AppLanguage.tamil:   'சரியான எண்ணை உள்ளிடவும்',
  }[language]!;

  String get enterNic => {
    AppLanguage.english: 'Enter NIC number',
    AppLanguage.sinhala: 'NIC අංකය ඇතුළු කරන්න',
    AppLanguage.tamil:   'அடையாள அட்டை எண்ணை உள்ளிடவும்',
  }[language]!;

  String get enterPassword => {
    AppLanguage.english: 'Enter password',
    AppLanguage.sinhala: 'මුරපදය ඇතුළු කරන්න',
    AppLanguage.tamil:   'கடவுச்சொல்லை உள்ளிடவும்',
  }[language]!;

  String get passwordLength => {
    AppLanguage.english: 'Password must be at least 6 characters',
    AppLanguage.sinhala: 'මුරපදය අක්ෂර 6කට වඩා තිබිය යුතුය',
    AppLanguage.tamil:   'கடவுச்சொல் குறைந்தது 6 எழுத்துகள் இருக்க வேண்டும்',
  }[language]!;

  String get confirmPasswordError => {
    AppLanguage.english: 'Confirm your password',
    AppLanguage.sinhala: 'මුරපදය තහවුරු කරන්න',
    AppLanguage.tamil:   'கடவுச்சொல்லை உறுதிப்படுத்தவும்',
  }[language]!;

  String get passwordMismatch => {
    AppLanguage.english: 'Passwords do not match',
    AppLanguage.sinhala: 'මුරපද ගැලපෙන්නේ නැත',
    AppLanguage.tamil:   'கடவுச்சொற்கள் பொருந்தவில்லை',
  }[language]!;

  String get selectCategory => {
    AppLanguage.english: 'Please select a category',
    AppLanguage.sinhala: 'වර්ගය තෝරන්න',
    AppLanguage.tamil:   'வகையை தேர்ந்தெடுக்கவும்',
  }[language]!;

  String get enterLocation => {
    AppLanguage.english: 'Enter shop location',
    AppLanguage.sinhala: 'කඩයේ ස්ථානය ඇතුළු කරන්න',
    AppLanguage.tamil:   'கடை இடத்தை உள்ளிடவும்',
  }[language]!;

  String get addProfilePhoto => {
    AppLanguage.english: 'Please add your profile photo',
    AppLanguage.sinhala: 'පෞද්ගලික ඡායාරූපය එකතු කරන්න',
    AppLanguage.tamil:   'உங்கள் சுயவிவர புகைப்படத்தை சேர்க்கவும்',
  }[language]!;

  String get addShopPhoto => {
    AppLanguage.english: 'Please add your shop image',
    AppLanguage.sinhala: 'කඩය ඡායාරූපය එකතු කරන්න',
    AppLanguage.tamil:   'உங்கள் கடை படத்தை சேர்க்கவும்',
  }[language]!;

  // ── Categories ──
  List<Map<String, dynamic>> get categories => [
    {'key': 'food',      'label': {AppLanguage.english: 'Food & Beverages',     AppLanguage.sinhala: 'ආහාර හා පාන',           AppLanguage.tamil: 'உணவு & பானங்கள்'},     'icon': Icons.restaurant},
    {'key': 'clothing',  'label': {AppLanguage.english: 'Clothing & Fashion',   AppLanguage.sinhala: 'ඇඳුම් හා විලාසිතා',     AppLanguage.tamil: 'ஆடை & நாகரீகம்'},      'icon': Icons.checkroom},
    {'key': 'grocery',   'label': {AppLanguage.english: 'Grocery & Vegetables', AppLanguage.sinhala: 'ගෙවතු හා එළවළු',        AppLanguage.tamil: 'மளிகை & காய்கறிகள்'}, 'icon': Icons.shopping_basket},
    {'key': 'stationery','label': {AppLanguage.english: 'Stationery',           AppLanguage.sinhala: 'ලිපිද්‍රව්‍ය',          AppLanguage.tamil: 'எழுதுபொருள்'},         'icon': Icons.edit},
    {'key': 'other',     'label': {AppLanguage.english: 'Other',                AppLanguage.sinhala: 'වෙනත්',                  AppLanguage.tamil: 'மற்றவை'},               'icon': Icons.category},
  ];
}