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

class _OrdersPageState extends State<OrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _pendingOrders   = [];
  List<dynamic> _preparingOrders = [];
  bool _isLoading                = true;
  String _ownerId                = '';
  Timer? _refreshTimer;
  int _lastPendingCount          = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadOwnerAndOrders();

    // Auto refresh every 15 seconds
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _loadOrders(notify: true),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
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
      status:  'pending',
    );
    final preparingResult = await ApiService.getOrders(
      ownerId: _ownerId,
      status:  'preparing',
    );

    final pendingData =
        Map<String, dynamic>.from(pendingResult['data']['data'] ?? {});
    final preparingData =
        Map<String, dynamic>.from(preparingResult['data']['data'] ?? {});
    final newPending = pendingData['orders']
        as List? ?? [];

    // ── Notify if new orders arrived ──
    if (notify && newPending.length > _lastPendingCount) {
      _notifyNewOrder();
    }

    _lastPendingCount = newPending.length;

    if (mounted) {
      setState(() {
        _isLoading       = false;
        _pendingOrders   = newPending;
        _preparingOrders = preparingData['orders']
            as List? ?? [];
      });
    }
  }

  Future<void> _notifyNewOrder() async {
    // Vibrate
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(
        pattern: [0, 500, 200, 500],
      );
    }

    // Show snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.notifications_active,
                  color: Colors.white),
              SizedBox(width: 10),
              Text('New order received! 🎉',
                  style: TextStyle(
                      fontWeight: FontWeight.bold)),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _updateStatus(
      String orderId, String status) async {
    final result = await ApiService.updateOrderStatus(
      orderId: orderId,
      status:  status,
    );

    if (result['success'] == true) {
      await _loadOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Order ${status == 'preparing'
                    ? 'accepted!'
                    : status == 'completed'
                        ? 'completed!'
                        : 'cancelled!'}'),
            backgroundColor: status == 'completed'
                ? Colors.green
                : status == 'preparing'
                    ? Colors.orange
                    : Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Tab bar ──
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.orange,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.orange,
            labelStyle: const TextStyle(
                fontWeight: FontWeight.bold),
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    const Text('Pending'),
                    if (_pendingOrders.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets
                            .symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_pendingOrders.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    const Text('Preparing'),
                    if (_preparingOrders.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets
                            .symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_preparingOrders.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Tab views ──
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                      color: Colors.orange))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Pending orders
                    _ordersList(
                      orders:    _pendingOrders,
                      emptyIcon: '⏳',
                      emptyText: 'No pending orders',
                      isPending: true,
                    ),
                    // Preparing orders
                    _ordersList(
                      orders:    _preparingOrders,
                      emptyIcon: '👨‍🍳',
                      emptyText: 'No orders being prepared',
                      isPending: false,
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _ordersList({
    required List<dynamic> orders,
    required String emptyIcon,
    required String emptyText,
    required bool isPending,
  }) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emptyIcon,
                style: const TextStyle(fontSize: 60)),
            const SizedBox(height: 16),
            Text(emptyText,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54)),
            const SizedBox(height: 8),
            const Text('Pull down to refresh',
                style: TextStyle(color: Colors.black45)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadOrders(),
      color: Colors.orange,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) =>
            _orderCard(orders[index], isPending),
      ),
    );
  }

  Widget _orderCard(
      Map<String, dynamic> order, bool isPending) {
    final items = (order['items_list'] ?? order['items']) as List? ?? [];
    final orderId = order['id'].toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isPending
            ? Border.all(
                color: Colors.orange.shade200)
            : null,
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
          // ── Order header ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isPending
                  ? Colors.orange.shade50
                  : Colors.blue.shade50,
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
                    color: isPending
                        ? Colors.orange
                        : Colors.blue,
                    borderRadius:
                        BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isPending
                        ? Icons.pending_actions
                        : Icons.restaurant,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #$orderId',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      _formatTime(
                          order['created_at'] ?? ''),
                      style: const TextStyle(
                        color: Colors.black45,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Total
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

          // ── Order items ──
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // Items list
                ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(
                      bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 24, height: 24,
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius:
                              BorderRadius.circular(6),
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
                          style: const TextStyle(
                              fontSize: 14),
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

                // Customer info
                if (order['customer_name'] != null &&
                    order['customer_name']
                        .toString()
                        .isNotEmpty) ...[
                  const Divider(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.person_outline,
                          size: 14,
                          color: Colors.black45),
                      const SizedBox(width: 6),
                      Text(
                        order['customer_name'],
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                      if (order['customer_phone'] !=
                              null &&
                          order['customer_phone']
                              .toString()
                              .isNotEmpty) ...[
                        const Text(' · ',
                            style: TextStyle(
                                color: Colors.black45)),
                        const Icon(Icons.phone,
                            size: 14,
                            color: Colors.black45),
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

                // Note
                if (order['note'] != null &&
                    order['note']
                        .toString()
                        .isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius:
                          BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                            Icons.note_outlined,
                            size: 14,
                            color: Colors.black45),
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

          // ── Action buttons ──
          Container(
            padding: const EdgeInsets.fromLTRB(
                14, 0, 14, 14),
            child: isPending
                ? Row(
                    children: [
                      // Accept button
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _updateStatus(
                                  orderId, 'preparing'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.orange,
                            foregroundColor:
                                Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                      10),
                            ),
                          ),
                          // icon: const Icon(
                          //     Icons.check, size: 18),
                          label: const Text(
                              'Accept & Prepare'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Reject button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _showCancelDialog(
                                  orderId),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                      10),
                            ),
                          ),
                          // icon: const Icon(
                              // Icons.close,
                              // color: Colors.red,
                              // size: 18),
                          label: const Text(
                              'Cancel',
                              style: TextStyle(
                                  color: Colors.red)),
                        ),
                      ),
                    ],
                  )
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _updateStatus(
                              orderId, 'completed'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets
                            .symmetric(vertical: 12),
                      ),
                      icon: const Icon(
                          Icons.check_circle,
                          size: 20),
                      label: const Text(
                        'Order Finished ✓',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Order?'),
        content: const Text(
            'Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateStatus(orderId, 'cancelled');
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red),
            child: const Text('Yes, Cancel',
                style: TextStyle(color: Colors.white)),
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
