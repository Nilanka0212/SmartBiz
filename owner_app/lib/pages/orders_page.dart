import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';

import '../services/api_service.dart';
import '../services/auth_services.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  List<dynamic> _openOrders = [];
  bool _isLoading = true;
  String _ownerId = '';
  Timer? _refreshTimer;
  int _lastPendingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadOwnerAndOrders();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _loadOrders(notify: true),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOwnerAndOrders() async {
    final owner = await AuthService.getOwner();
    if (owner != null) {
      _ownerId = owner['id'].toString();
      await _loadOrders();
    }
  }

  Future<void> _loadOrders({bool notify = false}) async {
    if (_ownerId.isEmpty) return;

    final pendingResult = await ApiService.getOrders(
      ownerId: _ownerId,
      status: 'pending',
    );
    final preparingResult = await ApiService.getOrders(
      ownerId: _ownerId,
      status: 'preparing',
    );

    final pendingData =
        Map<String, dynamic>.from(pendingResult['data']['data'] ?? {});
    final preparingData =
        Map<String, dynamic>.from(preparingResult['data']['data'] ?? {});
    final pendingOrders = List<dynamic>.from(pendingData['orders'] ?? []);
    final preparingOrders =
        List<dynamic>.from(preparingData['orders'] ?? []);

    if (notify && pendingOrders.length > _lastPendingCount) {
      _notifyNewOrder();
    }

    _lastPendingCount = pendingOrders.length;

    final combinedOrders = [
      ...pendingOrders,
      ...preparingOrders,
    ];

    combinedOrders.sort((a, b) {
      final aStatus = (a['status'] ?? '').toString();
      final bStatus = (b['status'] ?? '').toString();
      if (aStatus != bStatus) {
        return aStatus == 'pending' ? -1 : 1;
      }

      final aDate = DateTime.tryParse('${a['created_at']}');
      final bDate = DateTime.tryParse('${b['created_at']}');
      if (aDate == null || bDate == null) return 0;
      return bDate.compareTo(aDate);
    });

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _openOrders = combinedOrders;
    });
  }

  Future<void> _notifyNewOrder() async {
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(pattern: [0, 500, 200, 500]);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.notifications_active, color: Colors.white),
            SizedBox(width: 10),
            Text(
              'New order received!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _updateStatus(String orderId, String status) async {
    final result = await ApiService.updateOrderStatus(
      orderId: orderId,
      status: status,
    );

    if (result['success'] == true) {
      await _loadOrders();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'preparing'
                ? 'Order accepted and moved to preparing'
                : status == 'completed'
                    ? 'Order finished successfully'
                    : 'Order cancelled',
          ),
          backgroundColor: status == 'preparing'
              ? Colors.orange
              : status == 'completed'
                  ? Colors.green
                  : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          color: Colors.white,
          child: Row(
            children: [
              const Text(
                'Open Orders',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 10),
              if (_openOrders.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${_openOrders.length}',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const Spacer(),
              const Text(
                'Pending and preparing together',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.black45,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.orange),
                )
              : _ordersList(),
        ),
      ],
    );
  }

  Widget _ordersList() {
    if (_openOrders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 56, color: Colors.black26),
            SizedBox(height: 16),
            Text(
              'No open orders',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Pull down to refresh',
              style: TextStyle(color: Colors.black45),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      color: Colors.orange,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _openOrders.length,
        itemBuilder: (context, index) =>
            _orderCard(Map<String, dynamic>.from(_openOrders[index])),
      ),
    );
  }

  Widget _orderCard(Map<String, dynamic> order) {
    final items = (order['items_list'] ?? order['items']) as List? ?? [];
    final orderId = order['id'].toString();
    final status = (order['status'] ?? 'pending').toString();
    final isPending = status == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending ? Colors.orange.shade200 : Colors.blue.shade100,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isPending ? Colors.orange.shade50 : Colors.blue.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isPending ? Colors.orange : Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isPending ? Icons.pending_actions : Icons.restaurant,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #$orderId',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      _formatTime(order['created_at'] ?? ''),
                      style: const TextStyle(
                        color: Colors.black45,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isPending ? Colors.orange : Colors.blue,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isPending ? 'Pending' : 'Preparing',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Rs. ${double.parse(order['total_price'].toString()).toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                '${item['qty']}',
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item['name'] ?? '',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          Text(
                            'Rs. ${(item['price'] * item['qty']).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )),
                if (order['customer_name'] != null &&
                    order['customer_name'].toString().isNotEmpty) ...[
                  const Divider(height: 16),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 14,
                        color: Colors.black45,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        order['customer_name'],
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                      if (order['customer_phone'] != null &&
                          order['customer_phone'].toString().isNotEmpty) ...[
                        const Text(
                          ' · ',
                          style: TextStyle(color: Colors.black45),
                        ),
                        const Icon(
                          Icons.phone,
                          size: 14,
                          color: Colors.black45,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          order['customer_phone'],
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                if (order['note'] != null && order['note'].toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.note_outlined,
                          size: 14,
                          color: Colors.black45,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            order['note'],
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => _updateStatus(
                      orderId,
                      isPending ? 'preparing' : 'completed',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPending ? Colors.orange : Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: Icon(
                      isPending ? Icons.local_dining : Icons.check_circle,
                      size: 20,
                    ),
                    label: Text(
                      isPending ? 'Accept & Prepare' : 'Order Finished',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (isPending) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showCancelDialog(orderId),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(String orderId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Order?'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateStatus(orderId, 'cancelled');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) {
        return '${diff.inMinutes} min ago';
      }
      if (diff.inHours < 24) {
        return '${diff.inHours} hours ago';
      }
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (e) {
      return dateStr;
    }
  }
}
