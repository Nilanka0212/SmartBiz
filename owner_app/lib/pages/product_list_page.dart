import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/auth_services.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() =>
      _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  List<dynamic> _products = [];
  bool _isLoading         = true;
  String _ownerId         = '';

  @override
  void initState() {
    super.initState();
    _loadOwnerAndProducts();
  }

  Future<void> _loadOwnerAndProducts() async {
    final owner = await AuthService.getOwner();
    if (owner != null) {
      _ownerId = owner['id'].toString();
      await _loadProducts();
    }
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    final result =
        await ApiService.getProducts(ownerId: _ownerId);
    setState(() {
      _isLoading = false;
      if (result['success'] == true) {
        _products = result['data']['products'] ?? [];
      }
    });
  }

  Future<void> _toggleProduct(
      String productId, bool currentValue) async {
    final result = await ApiService.toggleProduct(
      productId: productId,
      isActive:  !currentValue,
    );
    if (result['success'] == true) {
      await _loadProducts();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              result['data']['message'] ?? 'Failed'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: Colors.orange))
          : _products.isEmpty
              ? _emptyState()
              : RefreshIndicator(
                  onRefresh: _loadProducts,
                  color: Colors.orange,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _products.length,
                    itemBuilder: (context, index) =>
                        _productCard(_products[index]),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  AddEditProductPage(ownerId: _ownerId),
            ),
          );
          await _loadProducts();
        },
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Product',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text('No products yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54)),
          const SizedBox(height: 8),
          const Text('Tap + to add your first product',
              style: TextStyle(color: Colors.black45)),
        ],
      ),
    );
  }

  Widget _productCard(Map<String, dynamic> product) {
    final status     = product['status'] ?? 'pending';
    final isActive   = product['is_active'] == 1 ||
                       product['is_active'] == '1';
    final isPending  = status == 'pending';
    final isRejected = status == 'rejected';
    final isApproved = status == 'active' ||
                       status == 'inactive';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isRejected
            ? Border.all(color: Colors.red.shade200)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Product info ──
          ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: product['image'] != null
                  ? Image.network(
                      'http://10.0.2.2/SmartBiz/api/${product['image']}',
                      width: 60, height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, _e) =>
                          _imagePlaceholder(),
                    )
                  : _imagePlaceholder(),
            ),
            title: Text(
              product['name'] ?? '',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'Rs. ${product['price']}',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (product['description'] != null &&
                    product['description']
                        .toString()
                        .isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    product['description'],
                    style: const TextStyle(
                        color: Colors.black45,
                        fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
            trailing: isRejected
                ? null
                : IconButton(
                    icon: const Icon(Icons.edit,
                        color: Colors.orange),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddEditProductPage(
                            ownerId: _ownerId,
                            product: product,
                          ),
                        ),
                      );
                      await _loadProducts();
                    },
                  ),
          ),

          // ── Status bar ──
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isRejected
                  ? Colors.red.shade50
                  : isPending
                      ? Colors.orange.shade50
                      : Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                // ── Status icon ──
                Icon(
                  isRejected
                      ? Icons.cancel
                      : isPending
                          ? Icons.hourglass_empty
                          : isActive
                              ? Icons.check_circle
                              : Icons.pause_circle,
                  color: isRejected
                      ? Colors.red
                      : isPending
                          ? Colors.orange
                          : isActive
                              ? Colors.green
                              : Colors.grey,
                  size: 16,
                ),
                const SizedBox(width: 6),

                // ── Status label ──
                Text(
                  isRejected
                      ? 'Rejected'
                      : isPending
                          ? 'Waiting for approval'
                          : isActive
                              ? 'Active'
                              : 'Inactive',
                  style: TextStyle(
                    color: isRejected
                        ? Colors.red
                        : isPending
                            ? Colors.orange
                            : isActive
                                ? Colors.green
                                : Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const Spacer(),

                // ── Active/Inactive Toggle ──
                if (isApproved)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          fontSize: 12,
                          color: isActive
                              ? Colors.green
                              : Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Switch(
                        value: isActive,
                        onChanged: (_) => _toggleProduct(
                          product['id'].toString(),
                          isActive,
                        ),
                        activeThumbColor: Colors.green,
                        activeTrackColor:
                            Colors.green.shade200,
                        inactiveThumbColor: Colors.grey,
                        inactiveTrackColor:
                            Colors.grey.shade300,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),

                // ── Rejected: Fix & Retry button ──
                if (isRejected)
                  TextButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddEditProductPage(
                            ownerId: _ownerId,
                            product: product,
                          ),
                        ),
                      );
                      await _loadProducts();
                    },
                    icon: const Icon(Icons.refresh,
                        size: 14, color: Colors.red),
                    label: const Text('Fix & Retry',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.red)),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 60, height: 60,
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.fastfood,
          color: Colors.orange, size: 30),
    );
  }
}

// ─────────────────────────────────────────
// ADD / EDIT PRODUCT PAGE
// ─────────────────────────────────────────
class AddEditProductPage extends StatefulWidget {
  final String ownerId;
  final Map<String, dynamic>? product;

  const AddEditProductPage({
    super.key,
    required this.ownerId,
    this.product,
  });

  @override
  State<AddEditProductPage> createState() =>
      _AddEditProductPageState();
}

class _AddEditProductPageState
    extends State<AddEditProductPage> {
  final _nameController        = TextEditingController();
  final _priceController       = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey               = GlobalKey<FormState>();
  final _imagePicker           = ImagePicker();
  Uint8List? _imageBytes;
  bool _isLoading              = false;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text =
          widget.product!['name'] ?? '';
      _priceController.text =
          widget.product!['price'].toString();
      _descriptionController.text =
          widget.product!['description'] ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() => _imageBytes = bytes);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    Map<String, dynamic> result;

    if (_isEditing) {
      result = await ApiService.updateProduct(
        productId:   widget.product!['id'].toString(),
        name:        _nameController.text.trim(),
        price:       _priceController.text.trim(),
        description: _descriptionController.text.trim(),
        imageBytes:  _imageBytes,
        imageName:   'product.jpg',
      );
    } else {
      result = await ApiService.addProduct(
        ownerId:     widget.ownerId,
        name:        _nameController.text.trim(),
        price:       _priceController.text.trim(),
        description: _descriptionController.text.trim(),
        imageBytes:  _imageBytes,
        imageName:   'product.jpg',
      );
    }

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      final status = result['data']['status'] ?? 'pending';
      final issues = result['data']['issues'] as List? ?? [];
      final risk   = result['data']['risk']   ?? 'low';
      final labels = result['data']['labels'] as List? ?? [];

      if (!mounted) return;

      Color    dialogColor;
      IconData dialogIcon;
      String   dialogTitle;

      switch (status) {
        case 'active':
          dialogColor = Colors.green;
          dialogIcon  = Icons.check_circle;
          dialogTitle = _isEditing
              ? 'Product Updated & Approved! ✅'
              : 'Auto Approved! ✅';
          break;
        case 'rejected':
          dialogColor = Colors.red;
          dialogIcon  = Icons.cancel;
          dialogTitle = 'Product Rejected ❌';
          break;
        default:
          dialogColor = Colors.orange;
          dialogIcon  = Icons.hourglass_empty;
          dialogTitle = _isEditing
              ? 'Product Updated ⚠️'
              : 'Pending Review ⚠️';
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Icon ──
                Container(
                  width: 70, height: 70,
                  decoration: BoxDecoration(
                    color: dialogColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(dialogIcon,
                      color: Colors.white, size: 40),
                ),
                const SizedBox(height: 16),

                // ── Title ──
                Text(dialogTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                // ── Message ──
                Text(
                  result['data']['message'] ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 13),
                ),

                // ── Risk badge ──
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: risk == 'low'
                        ? Colors.green.shade50
                        : risk == 'medium'
                            ? Colors.orange.shade50
                            : Colors.red.shade50,
                    borderRadius:
                        BorderRadius.circular(20),
                    border: Border.all(
                      color: risk == 'low'
                          ? Colors.green
                          : risk == 'medium'
                              ? Colors.orange
                              : Colors.red,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        risk == 'low'
                            ? Icons.shield
                            : risk == 'medium'
                                ? Icons.warning_amber
                                : Icons.dangerous,
                        size: 14,
                        color: risk == 'low'
                            ? Colors.green
                            : risk == 'medium'
                                ? Colors.orange
                                : Colors.red,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Risk: ${risk.toUpperCase()}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: risk == 'low'
                              ? Colors.green
                              : risk == 'medium'
                                  ? Colors.orange
                                  : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Issues ──
                if (issues.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: status == 'rejected'
                          ? Colors.red.shade50
                          : Colors.orange.shade50,
                      borderRadius:
                          BorderRadius.circular(10),
                      border: Border.all(
                        color: status == 'rejected'
                            ? Colors.red.shade200
                            : Colors.orange.shade200,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline,
                                size: 14,
                                color: status == 'rejected'
                                    ? Colors.red
                                    : Colors.orange),
                            const SizedBox(width: 6),
                            Text('Issues found:',
                                style: TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                  fontSize: 12,
                                  color: status ==
                                          'rejected'
                                      ? Colors.red
                                      : Colors.orange,
                                )),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...issues.map((issue) => Padding(
                          padding: const EdgeInsets.only(
                              bottom: 4),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.arrow_right,
                                  size: 14,
                                  color: status ==
                                          'rejected'
                                      ? Colors.red
                                      : Colors.orange),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  issue.toString(),
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color:
                                          Colors.black54),
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                ],

                // ── Image labels ──
                if (labels.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius:
                          BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text('Detected in image:',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.black45)),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: labels
                              .take(6)
                              .map((label) => Container(
                                    padding: const EdgeInsets
                                        .symmetric(
                                        horizontal: 8,
                                        vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors
                                          .grey.shade200,
                                      borderRadius:
                                          BorderRadius
                                              .circular(10),
                                    ),
                                    child: Text(
                                      label.toString(),
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors
                                              .black54),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Tip for rejected ──
                if (status == 'rejected') ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius:
                          BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.blue.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.lightbulb_outline,
                            color: Colors.blue, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Fix the issues above and try adding the product again.',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  if (status != 'rejected') {
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: dialogColor,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12)),
                ),
                child: Text(
                  status == 'rejected'
                      ? 'Fix & Try Again'
                      : 'OK',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result['data']['message'] ??
                      'Failed to save product',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        title: Text(
          _isEditing ? 'Edit Product' : 'Add Product',
          style: const TextStyle(
              fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  // ── Image picker ──
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 160, height: 160,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius:
                              BorderRadius.circular(16),
                          border: Border.all(
                            color: _imageBytes != null
                                ? Colors.orange
                                : Colors.grey.shade400,
                            width: 2,
                          ),
                        ),
                        child: _imageBytes != null
                            ? ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(
                                        14),
                                child: Image.memory(
                                  _imageBytes!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : widget.product?['image'] !=
                                    null
                                ? ClipRRect(
                                    borderRadius:
                                        BorderRadius
                                            .circular(14),
                                    child: Image.network(
                                      'http://10.0.2.2/SmartBiz/api/${widget.product!['image']}',
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (_, __, _e) =>
                                              _imagePlaceholderWidget(),
                                    ),
                                  )
                                : _imagePlaceholderWidget(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Center(
                    child: Text('Tap to select image',
                        style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12)),
                  ),

                  const SizedBox(height: 24),

                  // ── Product name ──
                  _label('Product Name'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    decoration: _inputDecoration(
                        'Enter product name', Icons.label),
                    validator: (v) =>
                        v!.trim().isEmpty
                            ? 'Enter product name'
                            : null,
                  ),

                  const SizedBox(height: 16),

                  // ── Price ──
                  _label('Price (Rs.)'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _priceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(
                            decimal: true),
                    decoration: _inputDecoration(
                        'Enter price',
                        Icons.attach_money),
                    validator: (v) {
                      if (v!.trim().isEmpty) {
                        return 'Enter price';
                      }
                      if (double.tryParse(v.trim()) ==
                          null) {
                        return 'Enter valid price';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // ── Description ──
                  _label('Description'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: _inputDecoration(
                        'Enter product description',
                        Icons.description),
                    validator: (_) => null,
                  ),

                  const SizedBox(height: 30),

                  // ── Save button ──
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed:
                          _isLoading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _isEditing
                            ? 'Update Product'
                            : 'Add Product',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.black38,
              child: const Center(
                child: CircularProgressIndicator(
                    color: Colors.orange),
              ),
            ),
        ],
      ),
    );
  }

  Widget _imagePlaceholderWidget() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate,
            color: Colors.grey, size: 40),
        SizedBox(height: 8),
        Text('Add Image',
            style: TextStyle(
                color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  InputDecoration _inputDecoration(
      String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.orange),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
            color: Colors.orange, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }
}