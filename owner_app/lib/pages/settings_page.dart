import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../main.dart';
import '../providers/language_provider.dart';
import '../services/auth_services.dart';
import 'welcome_page.dart';

class SettingsPage extends StatefulWidget {
  final Map<String, dynamic> owner;
  final ValueChanged<Map<String, dynamic>>? onOwnerChanged;

  const SettingsPage({
    super.key,
    required this.owner,
    this.onOwnerChanged,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late Map<String, dynamic> _owner;

  @override
  void initState() {
    super.initState();
    _owner = Map<String, dynamic>.from(widget.owner);
  }

  @override
  void didUpdateWidget(covariant SettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.owner != widget.owner) {
      _owner = Map<String, dynamic>.from(widget.owner);
    }
  }

  AppLanguage get _language =>
      MyApp.of(context)?.language ?? AppLanguage.english;

  String get _currentLanguageLabel {
    switch (_language) {
      case AppLanguage.sinhala:
        return 'Sinhala';
      case AppLanguage.tamil:
        return 'Tamil';
      case AppLanguage.english:
        return 'English';
    }
  }

  String get _displayName {
    final name = (_owner['name'] ?? '').toString().trim();
    return name.isEmpty ? 'Owner' : name;
  }

  String get _shopName {
    final shopName = (_owner['shop_name'] ?? '').toString().trim();
    return shopName.isEmpty ? 'My Shop' : shopName;
  }

  String _readValue(String key, String fallback) {
    final value = (_owner[key] ?? '').toString().trim();
    return value.isEmpty ? fallback : value;
  }

  Future<void> _persistOwner(Map<String, dynamic> updatedOwner) async {
    await AuthService.updateOwner(updatedOwner);
    if (!mounted) return;
    setState(() {
      _owner = Map<String, dynamic>.from(updatedOwner);
    });
    widget.onOwnerChanged?.call(_owner);
  }

  Future<void> _saveField({
    required String key,
    required String value,
  }) async {
    final updatedOwner = Map<String, dynamic>.from(_owner);
    updatedOwner[key] = value.trim();
    await _persistOwner(updatedOwner);
  }

  Future<void> _changeLanguage(AppLanguage language) async {
    MyApp.of(context)?.setLanguage(language);
    final updatedOwner = Map<String, dynamic>.from(_owner);
    updatedOwner['language'] = language.name;
    await _persistOwner(updatedOwner);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Language changed to ${_languageName(language)}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _languageName(AppLanguage language) {
    switch (language) {
      case AppLanguage.sinhala:
        return 'Sinhala';
      case AppLanguage.tamil:
        return 'Tamil';
      case AppLanguage.english:
        return 'English';
    }
  }

  Future<void> _showEditDialog({
    required String title,
    required String keyName,
    required String initialValue,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) async {
    final controller = TextEditingController(text: initialValue);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(title),
          content: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            autofocus: true,
            decoration: InputDecoration(
              hintText: hintText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, controller.text.trim()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (result == null || result.isEmpty || result == initialValue.trim()) {
      return;
    }

    await _saveField(key: keyName, value: result);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title updated'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    await AuthService.clearLogin();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomePage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final profilePhoto = (_owner['profile_photo'] ?? '').toString().trim();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.orange.shade400,
                  Colors.deepOrange.shade400,
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.shade100,
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: Colors.white24,
                  backgroundImage: profilePhoto.isNotEmpty
                      ? NetworkImage(AppConfig.apiAssetUrl(profilePhoto))
                      : null,
                  child: profilePhoto.isEmpty
                      ? const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 34,
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Account Settings',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _shopName,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionCard(
            title: 'Profile Details',
            subtitle: 'Update the owner information shown in the app.',
            child: Column(
              children: [
                _infoTile(
                  icon: Icons.person_outline,
                  title: 'Full name',
                  value: _displayName,
                  onTap: () => _showEditDialog(
                    title: 'Full name',
                    keyName: 'name',
                    initialValue: _readValue('name', ''),
                    hintText: 'Enter your name',
                  ),
                ),
                _infoTile(
                  icon: Icons.phone_outlined,
                  title: 'Phone number',
                  value: _readValue('phone', 'Not added'),
                  onTap: () => _showEditDialog(
                    title: 'Phone number',
                    keyName: 'phone',
                    initialValue: _readValue('phone', ''),
                    hintText: 'Enter your phone number',
                    keyboardType: TextInputType.phone,
                  ),
                ),
                _infoTile(
                  icon: Icons.credit_card_outlined,
                  title: 'NIC',
                  value: _readValue('nic', 'Not available'),
                  onTap: () => _showEditDialog(
                    title: 'NIC',
                    keyName: 'nic',
                    initialValue: _readValue('nic', ''),
                    hintText: 'Enter NIC number',
                  ),
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionCard(
            title: 'Shop Details',
            subtitle: 'Keep your shop profile easy for customers to recognize.',
            child: Column(
              children: [
                _infoTile(
                  icon: Icons.storefront_outlined,
                  title: 'Shop name',
                  value: _shopName,
                  onTap: () => _showEditDialog(
                    title: 'Shop name',
                    keyName: 'shop_name',
                    initialValue: _readValue('shop_name', ''),
                    hintText: 'Enter shop name',
                  ),
                ),
                _infoTile(
                  icon: Icons.category_outlined,
                  title: 'Category',
                  value: _readValue('shop_category', 'Not set'),
                  onTap: () => _showEditDialog(
                    title: 'Category',
                    keyName: 'shop_category',
                    initialValue: _readValue('shop_category', ''),
                    hintText: 'Enter business category',
                  ),
                ),
                _infoTile(
                  icon: Icons.location_on_outlined,
                  title: 'Location',
                  value: _readValue('shop_location', 'Not set'),
                  onTap: () => _showEditDialog(
                    title: 'Location',
                    keyName: 'shop_location',
                    initialValue: _readValue('shop_location', ''),
                    hintText: 'Enter shop location',
                    maxLines: 2,
                  ),
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionCard(
            title: 'Language',
            subtitle: 'Choose the app language for this device.',
            child: Column(
              children: [
                _languageTile(
                  language: AppLanguage.english,
                  title: 'English',
                  subtitle: 'Current app language: $_currentLanguageLabel',
                ),
                _languageTile(
                  language: AppLanguage.sinhala,
                  title: 'Sinhala',
                  subtitle: 'Use Sinhala across the owner app',
                ),
                _languageTile(
                  language: AppLanguage.tamil,
                  title: 'Tamil',
                  subtitle: 'Use Tamil across the owner app',
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionCard(
            title: 'Account Actions',
            subtitle: 'Quick actions for this signed-in owner account.',
            child: Column(
              children: [
                _infoTile(
                  icon: Icons.badge_outlined,
                  title: 'Owner ID',
                  value: _readValue('id', '-'),
                  trailing: const SizedBox.shrink(),
                ),
                _infoTile(
                  icon: Icons.logout,
                  title: 'Logout',
                  value: 'Sign out from this device',
                  valueColor: Colors.red,
                  iconColor: Colors.red,
                  onTap: _logout,
                  isLast: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black45,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onTap,
    Widget? trailing,
    Color? iconColor,
    Color? valueColor,
    bool isLast = false,
  }) {
    final content = Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: (iconColor ?? Colors.orange).withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: iconColor ?? Colors.orange,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  color: valueColor ?? Colors.black54,
                ),
              ),
            ],
          ),
        ),
        trailing ??
            Icon(
              onTap == null ? Icons.info_outline : Icons.edit_outlined,
              color: onTap == null ? Colors.black26 : Colors.black38,
              size: 18,
            ),
      ],
    );

    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: content,
          ),
        ),
        if (!isLast) const Divider(height: 14),
      ],
    );
  }

  Widget _languageTile({
    required AppLanguage language,
    required String title,
    required String subtitle,
    bool isLast = false,
  }) {
    final isSelected = _language == language;
    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _changeLanguage(language),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Radio<AppLanguage>(
                  value: language,
                  groupValue: _language,
                  activeColor: Colors.orange,
                  onChanged: (value) {
                    if (value != null) {
                      _changeLanguage(value);
                    }
                  },
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Active',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (!isLast) const Divider(height: 10),
      ],
    );
  }
}
