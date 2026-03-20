import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/language_provider.dart';
import '../services/api_service.dart';

class RegisterPage extends StatefulWidget {
  final AppStrings strings;
  const RegisterPage({super.key, required this.strings});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  AppStrings get s => widget.strings;
  int _currentStep = 0;
  bool _isLoading = false;
  Uint8List? _profilePhotoBytes;
  Uint8List? _shopImageBytes;

  // Personal
  final _nameController     = TextEditingController();
  final _phoneController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController  = TextEditingController();
  final _nicController      = TextEditingController();
  bool _obscurePassword     = true;
  bool _obscureConfirm      = true;
  // File? _profilePhoto;

  // Shop
  final _shopNameController = TextEditingController();
  final _locationController = TextEditingController();
  String? _selectedCategory;
  // File? _shopImage;

  final _personalFormKey = GlobalKey<FormState>();
  final _shopFormKey     = GlobalKey<FormState>();
  final _imagePicker     = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _nicController.dispose();
    _shopNameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // ── Pick image ──
Future<void> _pickImage(bool isProfile) async {
  try {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        if (isProfile) {
          _profilePhotoBytes = bytes;
        } else {
          _shopImageBytes = bytes;
        }
      });
    }
  } catch (e) {
    _showError('Could not open gallery. Please try again.');
  }
}
  // ── Next step ──
  void _nextStep() {
    if (_currentStep == 0) {
      if (_personalFormKey.currentState!.validate()) {
        setState(() => _currentStep = 1);
      }
    } else {
      if (_shopFormKey.currentState!.validate()) {
        _submitRegistration();
      }
    }
  }

  // ── Submit to PHP API ──
  Future<void> _submitRegistration() async {
    setState(() => _isLoading = true);

    final result = await ApiService.register(
      name:              _nameController.text.trim(),
      phone:             _phoneController.text.trim(),
      nic:               _nicController.text.trim(),
      password:          _passwordController.text.trim(),
      shopCategory:      _selectedCategory ?? '',
      shopLocation:      _locationController.text.trim(),
      shopName:          _shopNameController.text.trim(),
      language:          s.language.name,
      profilePhotoBytes: _profilePhotoBytes,
      profilePhotoName:  'profile.jpg',
      shopImageBytes:    _shopImageBytes,
      shopImageName:     'shop.jpg',
    );

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      _showSuccess();
    } else {
      final data = result['data'];
      String errorMsg = 'Registration failed';
      if (data != null) {
        if (data['errors'] != null) {
          errorMsg = (data['errors'] as Map).values.first[0];
        } else if (data['message'] != null) {
          errorMsg = data['message'];
        }
      }
      _showError(errorMsg);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70, height: 70,
              decoration: const BoxDecoration(
                  color: Colors.orange, shape: BoxShape.circle),
              child: const Icon(Icons.check, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 16),
            Text(s.successTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(s.successMsg,
                style: const TextStyle(color: Colors.orange)),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () =>
                  Navigator.popUntil(context, (r) => r.isFirst),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(s.goHome,
                  style: const TextStyle(color: Colors.white)),
            ),
          ),
        ],
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
        title: Text(s.personalDetails,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Step indicator
              Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 16, horizontal: 40),
                color: Colors.orange.shade50,
                child: Row(
                  children: [
                    _stepDot(1, s.personalDetails, _currentStep >= 0),
                    Expanded(
                      child: Container(
                        height: 2,
                        color: _currentStep >= 1
                            ? Colors.orange
                            : Colors.grey.shade300,
                      ),
                    ),
                    _stepDot(2, s.shopDetails, _currentStep >= 1),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: _currentStep == 0
                      ? _personalForm()
                      : _shopForm(),
                ),
              ),

              // Buttons
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, -2))],
                ),
                child: Row(
                  children: [
                    if (_currentStep == 1) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading
                              ? null
                              : () => setState(() => _currentStep = 0),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.orange),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                          ),
                          child: Text(s.backBtn,
                              style: const TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _nextStep,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(
                              vertical: 14),
                        ),
                        child: Text(
                          _currentStep == 0 ? s.nextBtn : s.submitBtn,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black38,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.orange),
              ),
            ),
        ],
      ),
    );
  }

  // ── Personal Form ──
  Widget _personalForm() {
    return Form(
      key: _personalFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(s.personalDetails),
          const SizedBox(height: 20),

          // Profile photo picker
          Center(
            child: GestureDetector(
              onTap: () => _pickImage(true),
              child: Column(
                children: [
                  Container(
                    width: 110, height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _profilePhotoBytes != null
                          ? Colors.orange.shade50
                          : Colors.grey.shade100,
                      border: Border.all(
                        color: _profilePhotoBytes != null
                            ? Colors.orange
                            : Colors.grey.shade400,
                        width: 2,
                      ),
                    ),
                    child: _profilePhotoBytes != null
                        ? ClipOval(
                            child: Image.memory(
                              _profilePhotoBytes!,
                              fit: BoxFit.cover,
                              width: 110,
                              height: 110,
                            ),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo,
                                  color: Colors.grey, size: 28),
                              SizedBox(height: 4),
                              Text('Add Photo',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _profilePhotoBytes != null
                        ? s.photoAdded
                        : 'Tap to select photo',
                    style: TextStyle(
                      color: _profilePhotoBytes != null
                          ? Colors.orange
                          : Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          _inputField(
              controller: _nameController,
              label: s.fullName,
              icon: Icons.person,
              validator: (v) =>
                  v!.trim().isEmpty ? s.enterName : null),
          const SizedBox(height: 14),
          _inputField(
              controller: _phoneController,
              label: s.phone,
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              validator: (v) {
                if (v!.trim().isEmpty) return s.enterPhone;
                if (v.trim().length < 10) return s.invalidPhone;
                return null;
              }),
          const SizedBox(height: 14),
          _inputField(
              controller: _nicController,
              label: s.nic,
              icon: Icons.credit_card,
              validator: (v) =>
                  v!.trim().isEmpty ? s.enterNic : null),
          const SizedBox(height: 14),
          _inputField(
              controller: _passwordController,
              label: s.password,
              icon: Icons.lock,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Colors.grey),
                onPressed: () => setState(
                    () => _obscurePassword = !_obscurePassword),
              ),
              validator: (v) {
                if (v!.trim().isEmpty) return s.enterPassword;
                if (v.trim().length < 6) return s.passwordLength;
                return null;
              }),
          const SizedBox(height: 14),
          _inputField(
              controller: _confirmController,
              label: s.confirmPassword,
              icon: Icons.lock_outline,
              obscureText: _obscureConfirm,
              suffixIcon: IconButton(
                icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Colors.grey),
                onPressed: () => setState(
                    () => _obscureConfirm = !_obscureConfirm),
              ),
              validator: (v) {
                if (v!.trim().isEmpty) return s.confirmPasswordError;
                if (v.trim() != _passwordController.text.trim()) {
                  return s.passwordMismatch;
                }
                return null;
              }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Shop Form ──
  Widget _shopForm() {
    return Form(
      key: _shopFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(s.shopDetails),
          const SizedBox(height: 20),

          // Shop image picker
          Center(
            child: GestureDetector(
              onTap: () => _pickImage(false),
              child: Column(
                children: [
                  Container(
                    width: 200, height: 130,
                    decoration: BoxDecoration(
                      color: _shopImageBytes != null
                          ? Colors.orange.shade50
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _shopImageBytes != null
                            ? Colors.orange
                            : Colors.grey.shade400,
                        width: 2,
                      ),
                    ),
                    child: _shopImageBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              _shopImageBytes!,
                              fit: BoxFit.cover,
                              width: 200,
                              height: 130,
                            ),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate,
                                  color: Colors.grey, size: 32),
                              SizedBox(height: 6),
                              Text('Add Shop Image',
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _shopImageBytes != null
                        ? s.shopImageAdded
                        : 'Tap to select image',
                    style: TextStyle(
                      color: _shopImageBytes != null
                          ? Colors.orange
                          : Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          _inputField(
              controller: _shopNameController,
              label: s.shopName,
              icon: Icons.storefront,
              validator: (_) => null),
          const SizedBox(height: 14),

          // Category dropdown
          DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            decoration: InputDecoration(
              labelText: s.category,
              prefixIcon:
                  const Icon(Icons.category, color: Colors.orange),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Colors.orange, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            items: s.categories.map((cat) {
              final label =
                  (cat['label'] as Map)[s.language] as String;
              return DropdownMenuItem<String>(
                value: cat['key'] as String,
                child: Row(
                  children: [
                    Icon(cat['icon'] as IconData,
                        color: Colors.orange, size: 20),
                    const SizedBox(width: 10),
                    Text(label,
                        style: const TextStyle(fontSize: 14)),
                  ],
                ),
              );
            }).toList(),
            onChanged: (val) =>
                setState(() => _selectedCategory = val),
            validator: (v) => v == null ? s.selectCategory : null,
          ),

          const SizedBox(height: 14),
          _inputField(
              controller: _locationController,
              label: s.location,
              icon: Icons.location_on,
              maxLines: 2,
              validator: (v) =>
                  v!.trim().isEmpty ? s.enterLocation : null),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Helpers ──
  Widget _sectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
            height: 3,
            width: 50,
            decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(2))),
      ],
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.orange),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Colors.orange, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _stepDot(int step, String label, bool isActive) {
    return Column(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor:
              isActive ? Colors.orange : Colors.grey.shade300,
          child: Text('$step',
              style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 4),
        Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 10,
                color: isActive ? Colors.orange : Colors.grey)),
      ],
    );
  }
}