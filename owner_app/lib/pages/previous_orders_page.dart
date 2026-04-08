import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_services.dart';

class PreviousOrdersPage extends StatefulWidget {
  const PreviousOrdersPage({super.key});

  @override
  State<PreviousOrdersPage> createState() =>
      _PreviousOrdersPageState();
}

class _PreviousOrdersPageState
    extends State<PreviousOrdersPage> {
  List<dynamic> _orders = [];
  bool _isLoading       = true;
  String _ownerId       = '';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final owner = await AuthService.getOwner();
    if (owner != null) {
      _ownerId = owner['id'].toString();
    }

    setState(() => _isLoading = true);

    // Load completed and cancelled orders
    final completedResult = await ApiService.getOrders(
      ownerId: _ownerId,
      status:  'completed',
    );
    final cancelledResult = await ApiService.getOrders(
      ownerId: _ownerId,
      status:  'cancelled',
    );

    final completedData =
        Map<String, dynamic>.from(completedResult['data']['data'] ?? {});
    final cancelledData =
        Map<String, dynamic>.from(cancelledResult['data']['data'] ?? {});
    final completed = completedData['orders']
        as List? ?? [];
    final cancelled = cancelledData['orders']
        as List? ?? [];

    // Merge and sort by date
    final allOrders = [...completed, ...cancelled];
    allOrders.sort((a, b) =>
        b['created_at'].compareTo(a['created_at']));

    setState(() {
      _orders    = allOrders;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: Colors.orange))
          : _orders.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Text('📋',
                          style:
                              TextStyle(fontSize: 60)),
                      SizedBox(height: 16),
                      Text('No previous orders',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadOrders,
                  color: Colors.orange,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _orders.length,
                    itemBuilder: (context, index) =>
                        _orderCard(_orders[index]),
                  ),
                ),
    );
  }

  Widget _orderCard(Map<String, dynamic> order) {
    final items = (order['items_list'] ?? order['items']) as List? ?? [];
    final isCompleted = order['status'] == 'completed';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
          // Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isCompleted
                  ? Colors.green.shade50
                  : Colors.red.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isCompleted
                      ? Icons.check_circle
                      : Icons.cancel,
                  color: isCompleted
                      ? Colors.green
                      : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Order #${order['id']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Rs. ${double.parse(order['total_price'].toString()).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? Colors.green
                            : Colors.red,
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                      child: Text(
                        isCompleted
                            ? 'Completed'
                            : 'Cancelled',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Items
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(
                      bottom: 6),
                  child: Row(
                    children: [
                      Text(
                        '${item['qty']}x',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item['name'] ?? '',
                          style: const TextStyle(
                              fontSize: 13),
                        ),
                      ),
                      Text(
                        'Rs. ${(item['price'] * item['qty']).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )),
                if (order['customer_name'] != null &&
                    order['customer_name']
                        .toString()
                        .isNotEmpty) ...[
                  const Divider(height: 12),
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
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time,
                        size: 14,
                        color: Colors.black45),
                    const SizedBox(width: 6),
                    Text(
                      order['created_at'] ?? '',
                      style: const TextStyle(
                        color: Colors.black45,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
