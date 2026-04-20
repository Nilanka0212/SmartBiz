import 'dart:async';

import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../main.dart';
import '../providers/language_provider.dart';
import '../services/api_service.dart';
import '../services/auth_services.dart';
import 'daily_summary_page.dart';
import 'orders_page.dart';
import 'previous_orders_page.dart';
import 'product_list_page.dart';
import 'settings_page.dart';
import 'welcome_page.dart';

class DashboardPage extends StatefulWidget {
  final Map<String, dynamic> owner;
  const DashboardPage({super.key, required this.owner});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  Timer? _pollTimer;
  bool _isLoadingPending = false;
  bool _isDialogShowing = false;
  List<Map<String, dynamic>> _pendingOrders = [];
  final List<Map<String, dynamic>> _dialogQueue = [];
  final Set<int> _notifiedOrderIds = <int>{};
  late Map<String, dynamic> _owner;

  AppLanguage get _language =>
      MyApp.of(context)?.language ?? AppLanguage.english;
  String get _ownerId => '${_owner['id']}';

  @override
  void initState() {
    super.initState();
    _owner = Map<String, dynamic>.from(widget.owner);
    _fetchPendingOrders();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _fetchPendingOrders(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  // ── Drawer menu items ──
  final List<Map<String, dynamic>> _menuItems = [
    {
      'en': 'Home',
      'si': 'මුල් පිටුව',
      'ta': 'முகப்பு',
      'icon': Icons.home,
    },
    {
      'en': 'Product List',
      'si': 'නිෂ්පාදන ලැයිස්තුව',
      'ta': 'தயாரிப்பு பட்டியல்',
      'icon': Icons.inventory,
    },
    {
      'en': 'Previous Orders',
      'si': 'පෙර ඇණවුම්',
      'ta': 'முந்தைய ஆர்டர்கள்',
      'icon': Icons.receipt_long,
    },
    {
      'en': 'Daily Summary',
      'si': 'දෛනික සාරාංශය',
      'ta': 'தினசரி சுருக்கம்',
      'icon': Icons.bar_chart,
    },
    {
      'en': 'Settings',
      'si': 'සැකසීම්',
      'ta': 'அமைப்புகள்',
      'icon': Icons.settings,
    },
  ];

  // ── Language helpers ──
  String _getLabel(Map<String, dynamic> item) {
    switch (_language) {
      case AppLanguage.sinhala:
        return item['si'];
      case AppLanguage.tamil:
        return item['ta'];
      default:
        return item['en'];
    }
  }

  String get _welcomeText {
    switch (_language) {
      case AppLanguage.sinhala:
        return 'සාදරයෙන් පිළිගනිමු';
      case AppLanguage.tamil:
        return 'வரவேற்கிறோம்';
      default:
        return 'Welcome';
    }
  }

  String get _pendingOrdersText {
    switch (_language) {
      case AppLanguage.sinhala:
        return 'පොරොත්තු ඇණවුම්';
      case AppLanguage.tamil:
        return 'நிலுவையிலுள்ள ஆர்டர்கள்';
      default:
        return 'Pending Orders';
    }
  }

  String get _logoutText {
    switch (_language) {
      case AppLanguage.sinhala:
        return 'පිටවීම';
      case AppLanguage.tamil:
        return 'வெளியேறு';
      default:
        return 'Logout';
    }
  }

  String get _createOrderTitle {
    switch (_language) {
      case AppLanguage.sinhala:
        return 'ඇණවුමක් සාදන්න';
      case AppLanguage.tamil:
        return 'ஆர்டர் உருவாக்கு';
      default:
        return 'Create Order';
    }
  }

  String get _createOrderSubtitle {
    switch (_language) {
      case AppLanguage.sinhala:
        return 'ගනුදෙනුකරු දුරකථනය නොමැති විට';
      case AppLanguage.tamil:
        return 'வாடிக்கையாளர் தொலைபேசி இல்லாதபோது';
      default:
        return 'For customers without phone';
    }
  }

  String get _createOrderBtnText {
    switch (_language) {
      case AppLanguage.sinhala:
        return 'නව ඇණවුම';
      case AppLanguage.tamil:
        return 'புதிய ஆர்டர்';
      default:
        return 'New Order';
    }
  }

  // ── Pages ──
  Widget _getPage() {
    switch (_selectedIndex) {
      case 0:
        return _homePage();
      case 1:
        return const ProductListPage();
      case 2:
        return const PreviousOrdersPage();
      case 3:
        return const DailySummaryPage();
      case 4:
        return SettingsPage(
          owner: _owner,
          onOwnerChanged: (updatedOwner) {
            setState(() {
              _owner = Map<String, dynamic>.from(updatedOwner);
            });
          },
        );
      default:
        return _homePage();
    }
  }

  String _getPageTitle() {
    return _getLabel(_menuItems[_selectedIndex]);
  }

  Future<void> _fetchPendingOrders() async {
    if (_isLoadingPending) return;
    _isLoadingPending = true;

    final response = await ApiService.getPendingOrders(
      ownerId: _ownerId,
    );

    _isLoadingPending = false;
    if (!mounted || response['success'] != true) {
      return;
    }

    final payload =
        Map<String, dynamic>.from(response['data']['data'] ?? {});
    final rawOrders =
        List<Map<String, dynamic>>.from(payload['orders'] ?? []);

    setState(() {
      _pendingOrders = rawOrders;
    });

    for (final order in rawOrders) {
      final orderId = int.tryParse('${order['id']}');
      if (orderId == null || _notifiedOrderIds.contains(orderId)) {
        continue;
      }

      _notifiedOrderIds.add(orderId);
      _dialogQueue.add(order);
    }

    _showNextOrderDialog();
  }

  Future<void> _showNextOrderDialog() async {
    if (!mounted || _isDialogShowing || _dialogQueue.isEmpty) {
      return;
    }

    _isDialogShowing = true;
    final order = _dialogQueue.removeAt(0);
    final shouldConfirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.notifications_active,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'New Order #${order['id']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              (order['customer_name'] ?? '').toString().trim().isEmpty
                  ? 'Customer: Walk-in customer'
                  : 'Customer: ${order['customer_name']}',
            ),
            const SizedBox(height: 6),
            Text(
              (order['customer_phone'] ?? '').toString().trim().isEmpty
                  ? 'Phone: Not provided'
                  : 'Phone: ${order['customer_phone']}',
            ),
            const SizedBox(height: 6),
            Text('Items: ${_itemsSummary(order)}'),
            const SizedBox(height: 6),
            Text(
              'Total: Rs. ${_formatMoney(order['total_price'])}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Payment: ${order['payment_method']} / ${order['payment_status']}',
            ),
            if ((order['note'] ?? '').toString().trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Note: ${order['note']}',
                style: const TextStyle(color: Colors.black54),
              ),
            ],
            const SizedBox(height: 12),
            const Text(
              'Confirm this order to move it to preparing.',
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    _isDialogShowing = false;

    if (shouldConfirm == true) {
      await _confirmOrder(order);
    }

    if (mounted) {
      _showNextOrderDialog();
    }
  }

  Future<void> _confirmOrder(Map<String, dynamic> order) async {
    final response = await ApiService.updateOrderStatus(
      orderId: '${order['id']}',
      status: 'preparing',
    );

    if (!mounted) return;

    if (response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order #${order['id']} is now preparing'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _fetchPendingOrders();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          response['data']?['message']?.toString() ?? 'Failed to update order',
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatMoney(dynamic value) {
    final amount = double.tryParse('$value') ?? 0;
    return amount.toStringAsFixed(2);
  }

  String _itemsSummary(Map<String, dynamic> order) {
    final rawItems =
        List<Map<String, dynamic>>.from(order['items_list'] ?? []);
    if (rawItems.isEmpty) return 'No items';

    return rawItems
        .map((item) => '${item['name']} x${item['qty']}')
        .join(', ');
  }

  // ── Create order dialog ──
  void _showCreateOrderDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24, right: 24, top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add_shopping_cart,
                      color: Colors.orange),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(_createOrderTitle,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    Text(_createOrderSubtitle,
                        style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black45)),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Info box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Create orders for customers who don\'t have the app or forgot their phone.',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Create Order page coming soon!'),
                      backgroundColor: Colors.orange,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.add),
                label: Text(_createOrderBtnText,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      // ── App Bar ──
      appBar: AppBar(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        title: Text(
          _getPageTitle(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined),
                if (_pendingOrders.isNotEmpty)
                  Positioned(
                    right: -3,
                    top: -3,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _pendingOrders.isEmpty
                ? _fetchPendingOrders
                : _showNextOrderDialog,
          ),
        ],
      ),

      // ── Side Drawer ──
      drawer: Drawer(
        child: Column(
          children: [
            // Drawer header
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.fromLTRB(20, 50, 20, 20),
              decoration: const BoxDecoration(
                color: Colors.orange,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    backgroundImage:
                        _owner['profile_photo'] != null
                            ? NetworkImage(
                                AppConfig.apiAssetUrl(
                                  _owner['profile_photo'].toString(),
                                ),
                              )
                            : null,
                    child: _owner['profile_photo'] ==
                            null
                        ? const Icon(Icons.person,
                            color: Colors.orange, size: 40)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _owner['shop_name'] ?? '  My Shop',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _owner['name'] ?? 'Owner',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone,
                          color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        _owner['phone'] ?? '',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Menu items
            Expanded(
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(vertical: 8),
                itemCount: _menuItems.length,
                itemBuilder: (context, index) {
                  final item     = _menuItems[index];
                  final isActive = _selectedIndex == index;
                  return Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.orange.shade50
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading: Icon(
                        item['icon'] as IconData,
                        color: isActive
                            ? Colors.orange
                            : Colors.black54,
                        size: 22,
                      ),
                      title: Text(
                        _getLabel(item),
                        style: TextStyle(
                          color: isActive
                              ? Colors.orange
                              : Colors.black87,
                          fontWeight: isActive
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 15,
                        ),
                      ),
                      onTap: () {
                        setState(
                            () => _selectedIndex = index);
                        Navigator.pop(context);
                      },
                    ),
                  );
                },
              ),
            ),

            const Divider(height: 1),

            // Logout
            ListTile(
              leading: const Icon(Icons.logout,
                  color: Colors.red, size: 22),
              title: Text(
                _logoutText,
                style: const TextStyle(
                    color: Colors.red, fontSize: 15),
              ),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(16)),
                    title: Text(_logoutText),
                    content: const Text(
                        'Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(context, false),
                        child: const Text('Cancel',
                            style: TextStyle(
                                color: Colors.grey)),
                      ),
                      ElevatedButton(
                        onPressed: () =>
                            Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        child: const Text('Logout',
                            style: TextStyle(
                                color: Colors.white)),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await AuthService.clearLogin();
                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const WelcomePage()),
                    (route) => false,
                  );
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),

      // ── Body ──
      body: _getPage(),
    );
  }

  // ── Home Page ──
  Widget _homePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.orange,
                  Colors.orange.shade700,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.shade200,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        _welcomeText,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _owner['name'] ?? 'Owner',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _owner['shop_name'] ??
                            'My Shop',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white30,
                  backgroundImage:
                      _owner['profile_photo'] != null
                          ? NetworkImage(
                              AppConfig.apiAssetUrl(
                                _owner['profile_photo'].toString(),
                              ),
                            )
                          : null,
                  child: _owner['profile_photo'] == null
                      ? const Icon(Icons.person,
                          color: Colors.white, size: 35)
                      : null,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Create Order Card ──
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                        child: const Icon(
                            Icons.add_shopping_cart,
                            color: Colors.orange,
                            size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            _createOrderTitle,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            _createOrderSubtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _showCreateOrderDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.add, size: 20),
                      label: Text(
                        _createOrderBtnText,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Pending Orders Card ──
          Text(
            _pendingOrdersText,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            height: 640,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: const OrdersPage(),
          ),

          // ── QR Code Card ──
Container(
  width: double.infinity,
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ],
  ),
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.qr_code,
                  color: Colors.purple, size: 22),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your Shop QR Code',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                Text('Let customers scan to order',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.black45)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        // QR Image
        Image.network(
          'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${Uri.encodeComponent('${AppConfig.customerShopBaseUrl}?id=${_owner['id']}')}',
          width: 200, height: 200,
        ),
        const SizedBox(height: 8),
        const Text('Show this QR to your customers',
            style: TextStyle(
                color: Colors.black45, fontSize: 12)),
      ],
    ),
  ),
),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
