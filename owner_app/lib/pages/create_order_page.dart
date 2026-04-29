import 'package:flutter/material.dart';

import '../services/api_service.dart';

class CreateOrderPage extends StatefulWidget {
  final String ownerId;

  const CreateOrderPage({
    super.key,
    required this.ownerId,
  });

  @override
  State<CreateOrderPage> createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends State<CreateOrderPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _noteController = TextEditingController();

  List<Map<String, dynamic>> _products = [];
  final Map<String, int> _quantities = {};
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _paymentMethod;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    final result = await ApiService.getProducts(ownerId: widget.ownerId);

    final rawProducts = result['success'] == true
        ? List<Map<String, dynamic>>.from(result['data']['products'] ?? [])
        : <Map<String, dynamic>>[];

    final availableProducts = rawProducts.where((product) {
      final status = (product['status'] ?? '').toString();
      final isActive = product['is_active'] == 1 || product['is_active'] == '1';
      return (status == 'active' || status == 'inactive') && isActive;
    }).toList();

    if (!mounted) return;
    setState(() {
      _products = availableProducts;
      _isLoading = false;
    });
  }

  void _changeQuantity(String productId, int change) {
    final current = _quantities[productId] ?? 0;
    final updated = current + change;

    setState(() {
      if (updated <= 0) {
        _quantities.remove(productId);
      } else {
        _quantities[productId] = updated;
      }
    });
  }

  double _productTotal(Map<String, dynamic> product) {
    final productId = '${product['id']}';
    final qty = _quantities[productId] ?? 0;
    final price = double.tryParse('${product['price']}') ?? 0;
    return price * qty;
  }

  double get _orderTotal {
    return _products.fold<double>(
      0,
      (sum, product) => sum + _productTotal(product),
    );
  }

  int get _selectedItemCount {
    return _quantities.values.fold<int>(0, (sum, qty) => sum + qty);
  }

  Future<void> _submitOrder() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer name is required'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number is required'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_quantities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one product to create an order'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_paymentMethod == null || _paymentMethod!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a payment method'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final items = _quantities.entries
        .map((entry) => {
              'product_id': entry.key,
              'qty': entry.value,
            })
        .toList();

    final result = await ApiService.createOwnerOrder(
      ownerId: widget.ownerId,
      items: items,
      customerName: _nameController.text.trim(),
      customerPhone: _phoneController.text.trim(),
      note: _noteController.text.trim(),
      paymentMethod: _paymentMethod!,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['data']['message']?.toString() ?? 'Order created successfully',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['data']['message']?.toString() ?? 'Failed to create order',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        title: const Text(
          'Create Order',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            )
          : _products.isEmpty
              ? _emptyState()
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _sectionCard(
                            title: 'Customer Details',
                            subtitle: 'Customer name and phone number are required.',
                            child: Column(
                              children: [
                                _field(
                                  controller: _nameController,
                                  label: 'Customer name',
                                  icon: Icons.person_outline,
                                ),
                                const SizedBox(height: 12),
                                _field(
                                  controller: _phoneController,
                                  label: 'Phone number',
                                  icon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                ),
                                const SizedBox(height: 12),
                                _field(
                                  controller: _noteController,
                                  label: 'Special note',
                                  icon: Icons.note_outlined,
                                  maxLines: 3,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _sectionCard(
                            title: 'Payment Method',
                            subtitle: 'Choose a payment method before creating the order.',
                            child: Row(
                              children: [
                                Expanded(
                                  child: _paymentOption(
                                    label: 'Cash',
                                    icon: Icons.payments_outlined,
                                    value: 'cash',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _paymentOption(
                                    label: 'Online',
                                    icon: Icons.credit_card,
                                    value: 'online',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _sectionCard(
                            title: 'Products',
                            subtitle: 'Select products and quantities for this order.',
                            child: Column(
                              children: _products
                                  .map((product) => _productTile(product))
                                  .toList(),
                            ),
                          ),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                    _bottomBar(),
                  ],
                ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No active products available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add and activate products first before creating an order.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black45),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Colors.black45),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _paymentOption({
    required String label,
    required IconData icon,
    required String value,
  }) {
    final isSelected = _paymentMethod == value;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => setState(() => _paymentMethod = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.orange : Colors.black54),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.orange : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _productTile(Map<String, dynamic> product) {
    final productId = '${product['id']}';
    final qty = _quantities[productId] ?? 0;
    final price = double.tryParse('${product['price']}') ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${product['name'] ?? ''}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rs. ${price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if ((product['description'] ?? '').toString().trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${product['description']}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _changeQuantity(productId, -1),
                  icon: const Icon(Icons.remove),
                  color: Colors.red,
                ),
                Text(
                  '$qty',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => _changeQuantity(productId, 1),
                  icon: const Icon(Icons.add),
                  color: Colors.green,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_selectedItemCount items selected',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rs. ${_orderTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submitOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.add_shopping_cart),
                      label: Text(
                        _isSubmitting ? 'Creating...' : 'Create Order',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
