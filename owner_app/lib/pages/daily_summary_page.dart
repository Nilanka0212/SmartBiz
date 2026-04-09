import 'package:flutter/material.dart';

import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../services/auth_services.dart';

class DailySummaryPage extends StatefulWidget {
  const DailySummaryPage({super.key});

  @override
  State<DailySummaryPage> createState() => _DailySummaryPageState();
}

class _DailySummaryPageState extends State<DailySummaryPage> {
  bool _isLoading = true;
  String _ownerId = '';
  String? _error;

  int _totalOrders = 0;
  int _pendingOrders = 0;
  int _confirmedOrders = 0;
  int _cancelledOrders = 0;
  double _totalIncome = 0;

  List<_BestSeller> _bestSellers = [];
  List<_DailyPoint> _dailyPoints = [];

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    final owner = await AuthService.getOwner();
    if (owner == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Owner account not found';
      });
      return;
    }

    _ownerId = owner['id'].toString();

    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final pendingResult = await ApiService.getOrders(
        ownerId: _ownerId,
        status: 'pending',
      );
      final preparingResult = await ApiService.getOrders(
        ownerId: _ownerId,
        status: 'preparing',
      );
      final completedResult = await ApiService.getOrders(
        ownerId: _ownerId,
        status: 'completed',
      );
      final cancelledResult = await ApiService.getOrders(
        ownerId: _ownerId,
        status: 'cancelled',
      );

      final pendingOrders = _extractOrders(pendingResult);
      final preparingOrders = _extractOrders(preparingResult);
      final completedOrders = _extractOrders(completedResult);
      final cancelledOrders = _extractOrders(cancelledResult);

      final allOrders = [
        ...pendingOrders,
        ...preparingOrders,
        ...completedOrders,
        ...cancelledOrders,
      ];

      final income = completedOrders.fold<double>(
        0,
        (sum, order) => sum + _toDouble(order['total_price']),
      );

      final bestSellers = _buildBestSellers(completedOrders);
      final dailyPoints = _buildDailyPoints(completedOrders);

      if (!mounted) return;
      setState(() {
        _totalOrders = allOrders.length;
        _pendingOrders = pendingOrders.length;
        _confirmedOrders = preparingOrders.length + completedOrders.length;
        _cancelledOrders = cancelledOrders.length;
        _totalIncome = income;
        _bestSellers = bestSellers;
        _dailyPoints = dailyPoints;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Failed to load summary';
      });
    }
  }

  List<Map<String, dynamic>> _extractOrders(Map<String, dynamic> response) {
    final data = Map<String, dynamic>.from(response['data'] ?? {});
    final payload = Map<String, dynamic>.from(data['data'] ?? {});
    return List<Map<String, dynamic>>.from(payload['orders'] ?? []);
  }

  List<_BestSeller> _buildBestSellers(List<Map<String, dynamic>> orders) {
    final Map<String, _BestSeller> totals = {};

    for (final order in orders) {
      final items = List<Map<String, dynamic>>.from(
        order['items_list'] ?? order['items'] ?? [],
      );

      for (final item in items) {
        final name = (item['name'] ?? 'Unknown Item').toString();
        final qty = int.tryParse('${item['qty']}') ?? 0;
        final revenue =
            _toDouble(item['price']) * qty;

        final current = totals[name];
        if (current == null) {
          totals[name] = _BestSeller(
            name: name,
            quantity: qty,
            revenue: revenue,
          );
        } else {
          totals[name] = _BestSeller(
            name: current.name,
            quantity: current.quantity + qty,
            revenue: current.revenue + revenue,
          );
        }
      }
    }

    final ranked = totals.values.toList()
      ..sort((a, b) => b.quantity.compareTo(a.quantity));
    return ranked.take(5).toList();
  }

  List<_DailyPoint> _buildDailyPoints(List<Map<String, dynamic>> orders) {
    final now = DateTime.now();
    final Map<String, _DailyPoint> grouped = {};

    for (int i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day - i);
      final key = _dayKey(day);
      grouped[key] = _DailyPoint(
        label: _shortDay(day.weekday),
        orders: 0,
        income: 0,
      );
    }

    for (final order in orders) {
      final createdAt = DateTime.tryParse('${order['created_at']}');
      if (createdAt == null) continue;

      final day = DateTime(createdAt.year, createdAt.month, createdAt.day);
      final key = _dayKey(day);
      if (!grouped.containsKey(key)) continue;

      final current = grouped[key]!;
      grouped[key] = _DailyPoint(
        label: current.label,
        orders: current.orders + 1,
        income: current.income + _toDouble(order['total_price']),
      );
    }

    return grouped.values.toList();
  }

  double _toDouble(dynamic value) {
    return double.tryParse('$value') ?? 0;
  }

  String _dayKey(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }

  String _shortDay(int weekday) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[weekday - 1];
  }

  String _money(double amount) {
    return amount.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.orange),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 52, color: Colors.red),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadSummary,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSummary,
      color: Colors.orange,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _summaryCard(
                title: 'Total Orders',
                value: '$_totalOrders',
                icon: Icons.receipt_long,
                color: Colors.orange,
              ),
              _summaryCard(
                title: 'Pending Orders',
                value: '$_pendingOrders',
                icon: Icons.pending_actions,
                color: Colors.amber,
              ),
              _summaryCard(
                title: 'Confirmed Orders',
                value: '$_confirmedOrders',
                icon: Icons.check_circle,
                color: Colors.green,
              ),
              _summaryCard(
                title: 'Cancelled Orders',
                value: '$_cancelledOrders',
                icon: Icons.cancel,
                color: Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _incomeCard(),
          const SizedBox(height: 18),
          _salesChartCard(),
          const SizedBox(height: 18),
          _incomeChartCard(),
          const SizedBox(height: 18),
          _bestSellerCard(),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return SizedBox(
      width: 170,
      child: Container(
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
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }

Widget _incomeCard() {
  return Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFFFA726), Color(0xFFFF7043)],
      ),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Total Income',
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 8),
        Text(
          'Rs. ${_money(_totalIncome)}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}
Widget _salesChartCard() {
  return _chartContainer(
    title: 'Daily Sales',
    subtitle: 'Last 7 days completed-order count',
    child: _responsiveLineChart(
      color: Colors.orange,
      values: _dailyPoints.map((point) => point.orders.toDouble()).toList(),
      valueLabel: (value) => '${value.toInt()} orders',
      leftLabelBuilder: (value) => value.toInt().toString(),
    ),
  );
}

  Widget _bestSellerCard() {
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
          const Text(
            'Best Selling Products',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Top products from completed orders',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 14),
          if (_bestSellers.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No completed orders yet',
                  style: TextStyle(color: Colors.black45),
                ),
              ),
            )
          else
            ..._bestSellers.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${item.quantity} items sold',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Rs. ${_money(item.revenue)}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _incomeChartCard() {
    return _chartContainer(
      title: 'Daily Income',
      subtitle: 'Last 7 days completed-order revenue',
      child: _responsiveLineChart(
        color: Colors.green,
        values: _dailyPoints.map((point) => point.income).toList(),
        valueLabel: (value) => 'Rs. ${value.toStringAsFixed(0)}',
        leftLabelBuilder: _compactMoneyLabel,
      ),
    );
  }

  Widget _chartContainer({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 400;
        return Container(
          padding: EdgeInsets.all(compact ? 12 : 16),
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
                style: TextStyle(
                  fontSize: compact ? 16 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.black54),
              ),
              SizedBox(height: compact ? 12 : 18),
              child,
            ],
          ),
        );
      },
    );
  }

  Widget _responsiveLineChart({
    required Color color,
    required List<double> values,
    required String Function(double value) valueLabel,
    required String Function(double value) leftLabelBuilder,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 400;
        final maxValue = values.fold<double>(0, (max, value) => value > max ? value : max);
        final chartMax = maxValue <= 0 ? 1.0 : maxValue * 1.2;

        return SizedBox(
          height: compact ? 200 : 250,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: (_dailyPoints.length - 1).toDouble(),
              minY: 0,
              maxY: chartMax,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: chartMax / 4,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: Colors.grey.withValues(alpha: 0.15),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  left: BorderSide(color: Colors.grey.withValues(alpha: 0.25)),
                  bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.25)),
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: compact ? 32 : 40,
                    interval: chartMax / 4,
                    getTitlesWidget: (value, meta) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Text(
                        leftLabelBuilder(value),
                        style: TextStyle(
                          fontSize: compact ? 9 : 10,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= _dailyPoints.length) {
                        return const SizedBox();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _dailyPoints[index].label,
                          style: TextStyle(
                            fontSize: compact ? 10 : 12,
                            color: Colors.black54,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                handleBuiltInTouches: true,
                touchTooltipData: LineTouchTooltipData(
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  tooltipRoundedRadius: 10,
                  getTooltipItems: (spots) => spots
                      .map(
                        (spot) => LineTooltipItem(
                          '${_dailyPoints[spot.x.toInt()].label}\n${valueLabel(spot.y)}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(
                    values.length,
                    (index) => FlSpot(index.toDouble(), values[index]),
                  ),
                  isCurved: true,
                  curveSmoothness: 0.25,
                  barWidth: compact ? 3 : 4,
                  color: color,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                      radius: compact ? 3 : 4,
                      color: color,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        color.withValues(alpha: 0.25),
                        color.withValues(alpha: 0.03),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _compactMoneyLabel(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(value >= 10000 ? 0 : 1)}k';
    }
    return value.toStringAsFixed(0);
  }
}

class _BestSeller {
  final String name;
  final int quantity;
  final double revenue;

  const _BestSeller({
    required this.name,
    required this.quantity,
    required this.revenue,
  });
}

class _DailyPoint {
  final String label;
  final int orders;
  final double income;

  const _DailyPoint({
    required this.label,
    required this.orders,
    required this.income,
  });
}
