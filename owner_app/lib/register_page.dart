import 'package:flutter/material.dart';
import '../providers/language_provider.dart';

class RegisterPage extends StatefulWidget {
  final AppStrings strings;
  const RegisterPage({super.key, required this.strings});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  AppStrings get s => widget.strings;
  int _currentStep = 0;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nicController = TextEditingController();
  bool _profilePhotoAdded = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  final _shopNameController = TextEditingController();
  final _locationController = TextEditingController();
  String? _selectedCategory;
  bool _shopImageAdded = false;

  final _personalFormKey = GlobalKey<FormState>();
  final _shopFormKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nicController.dispose();
    _shopNameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (!_profilePhotoAdded) {
        _showError(s.addProfilePhoto);
        return;
      }
      if (_personalFormKey.currentState!.validate()) {
        setState(() => _currentStep = 1);
      }
    } else {
      if (!_shopImageAdded) {
        _showError(s.addShopPhoto);
        return;
      }
      if (_shopFormKey.currentState!.validate()) {
        _showSuccess();
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating),
    );
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70, height: 70,
              decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
              child: const Icon(Icons.check, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 16),
            Text(s.successTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(s.successMsg,
                style: const TextStyle(color: Colors.orange)),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(s.goHome, style: const TextStyle(color: Colors.white)),
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
      body: Column(
        children: [
          // Step indicator
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
            color: Colors.orange.shade50,
            child: Row(
              children: [
                _stepDot(1, s.personalDetails, _currentStep >= 0),
                Expanded(
                  child: Container(
                    height: 2,
                    color: _currentStep >= 1 ? Colors.orange : Colors.grey.shade300,
                  ),
                ),
                _stepDot(2, s.shopDetails, _currentStep >= 1),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: _currentStep == 0 ? _personalForm() : _shopForm(),
            ),
          ),

          // Buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
            ),
            child: Row(
              children: [
                if (_currentStep == 1) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _currentStep = 0),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.orange),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(s.backBtn,
                          style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      _currentStep == 0 ? s.nextBtn : s.submitBtn,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _personalForm() {
    return Form(
      key: _personalFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(s.personalDetails),
          const SizedBox(height: 20),
          Center(
            child: GestureDetector(
              onTap: () => setState(() => _profilePhotoAdded = true),
              child: Column(
                children: [
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _profilePhotoAdded ? Colors.orange.shade100 : Colors.grey.shade100,
                      border: Border.all(
                        color: _profilePhotoAdded ? Colors.orange : Colors.grey.shade400,
                        width: 2,
                      ),
                    ),
                    child: _profilePhotoAdded
                        ? const Icon(Icons.check_circle, color: Colors.orange, size: 45)
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_a_photo, color: Colors.grey, size: 28),
                              const SizedBox(height: 4),
                              Text(s.profilePhoto,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 9, color: Colors.red)),
                            ],
                          ),
                  ),
                  if (_profilePhotoAdded)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(s.photoAdded,
                          style: const TextStyle(color: Colors.orange, fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _inputField(controller: _nameController, label: s.fullName, icon: Icons.person,
              validator: (v) => v!.trim().isEmpty ? s.enterName : null),
          const SizedBox(height: 14),
          _inputField(controller: _phoneController, label: s.phone, icon: Icons.phone,
              keyboardType: TextInputType.phone,
              validator: (v) {
                if (v!.trim().isEmpty) return s.enterPhone;
                if (v.trim().length < 10) return s.invalidPhone;
                return null;
              }),
          const SizedBox(height: 14),
          _inputField(controller: _nicController, label: s.nic, icon: Icons.credit_card,
              validator: (v) => v!.trim().isEmpty ? s.enterNic : null),
          const SizedBox(height: 14),
          _inputField(controller: _passwordController, label: s.password, icon: Icons.lock,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (v) {
                if (v!.trim().isEmpty) return s.enterPassword;
                if (v.trim().length < 6) return s.passwordLength;
                return null;
              }),
          const SizedBox(height: 14),
          _inputField(controller: _confirmPasswordController, label: s.confirmPassword,
              icon: Icons.lock_outline, obscureText: _obscureConfirm,
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              validator: (v) {
                if (v!.trim().isEmpty) return s.confirmPasswordError;
                if (v.trim() != _passwordController.text.trim()) return s.passwordMismatch;
                return null;
              }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _shopForm() {
    return Form(
      key: _shopFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(s.shopDetails),
          const SizedBox(height: 20),
          Center(
            child: GestureDetector(
              onTap: () => setState(() => _shopImageAdded = true),
              child: Column(
                children: [
                  Container(
                    width: 160, height: 110,
                    decoration: BoxDecoration(
                      color: _shopImageAdded ? Colors.orange.shade100 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _shopImageAdded ? Colors.orange : Colors.grey.shade400,
                        width: 2,
                      ),
                    ),
                    child: _shopImageAdded
                        ? const Icon(Icons.check_circle, color: Colors.orange, size: 45)
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_photo_alternate, color: Colors.grey, size: 32),
                              const SizedBox(height: 6),
                              Text(s.shopImage,
                                  style: const TextStyle(fontSize: 11, color: Colors.red)),
                            ],
                          ),
                  ),
                  if (_shopImageAdded)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(s.shopImageAdded,
                          style: const TextStyle(color: Colors.orange, fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _inputField(controller: _shopNameController, label: s.shopName,
              icon: Icons.storefront, validator: (_) => null),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: InputDecoration(
              labelText: s.category,
              prefixIcon: const Icon(Icons.category, color: Colors.orange),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.orange, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            items: s.categories.map((cat) {
              final label = (cat['label'] as Map)[s.language] as String;
              return DropdownMenuItem<String>(
                value: cat['key'] as String,
                child: Row(
                  children: [
                    Icon(cat['icon'] as IconData, color: Colors.orange, size: 20),
                    const SizedBox(width: 10),
                    Text(label, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedCategory = val),
            validator: (v) => v == null ? s.selectCategory : null,
          ),
          const SizedBox(height: 14),
          _inputField(controller: _locationController, label: s.location,
              icon: Icons.location_on, maxLines: 2,
              validator: (v) => v!.trim().isEmpty ? s.enterLocation : null),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(height: 3, width: 50,
            decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(2))),
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.orange, width: 2),
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
          backgroundColor: isActive ? Colors.orange : Colors.grey.shade300,
          child: Text('$step',
              style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 4),
        Text(label, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: isActive ? Colors.orange : Colors.grey)),
      ],
    );
  }
}
