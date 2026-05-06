import 'package:flutter/material.dart';

import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../services/auth_services.dart';

// ── Date range presets ──────────────────────────────────────────────────────
enum _DateRange { today, last7, last30, custom }

extension _DateRangeLabel on _DateRange {
  String get label {
    switch (this) {
      case _DateRange.today:   return 'Today';
      case _DateRange.last7:   return 'Last 7 days';
      case _DateRange.last30:  return 'Last 30 days';
      case _DateRange.custom:  return 'Custom';
    }
  }
}

class DailySummaryPage extends StatefulWidget {
  const DailySummaryPage({super.key});

  @override
  State<DailySummaryPage> createState() => _DailySummaryPageState();
}

class _DailySummaryPageState extends State<DailySummaryPage> {
  bool _isLoading = true;
  String _ownerId = '';
  String? _error;

  // ── Stats ──
  int    _totalOrders     = 0;
  int    _pendingOrders   = 0;
  int    _confirmedOrders = 0;
  int    _cancelledOrders = 0;
  double _totalIncome     = 0;
  double _totalProfit     = 0;

  List<_BestSeller> _bestSellers = [];
  List<_DailyPoint> _dailyPoints = [];

  // ── Date filter state ──
  _DateRange _selectedRange = _DateRange.last7;
  DateTime?  _customFrom;
  DateTime?  _customTo;

  // All completed orders cached for refiltering
  List<Map<String, dynamic>> _allCompletedOrders = [];

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  // ─────────────────────────────── helpers ───────────────────────────────────

  DateTime get _fromDate {
    final now = DateTime.now();
    switch (_selectedRange) {
      case _DateRange.today:
        return DateTime(now.year, now.month, now.day);
      case _DateRange.last7:
        return DateTime(now.year, now.month, now.day - 6);
      case _DateRange.last30:
        return DateTime(now.year, now.month, now.day - 29);
      case _DateRange.custom:
        return _customFrom ?? DateTime(now.year, now.month, now.day - 6);
    }
  }

  DateTime get _toDate {
    final now = DateTime.now();
    if (_selectedRange == _DateRange.custom && _customTo != null) {
      return DateTime(
          _customTo!.year, _customTo!.month, _customTo!.day, 23, 59, 59);
    }
    return DateTime(now.year, now.month, now.day, 23, 59, 59);
  }

  int get _chartDays {
    final diff = _toDate.difference(_fromDate).inDays + 1;
    // Cap at 30 days for the chart; beyond that group by week is better
    return diff.clamp(1, 30);
  }

  List<Map<String, dynamic>> get _filteredOrders {
    return _allCompletedOrders.where((order) {
      final createdAt = DateTime.tryParse('${order['created_at']}');
      if (createdAt == null) return false;
      return !createdAt.isBefore(_fromDate) &&
             !createdAt.isAfter(_toDate);
    }).toList();
  }

  // ─────────────────────────────── load ──────────────────────────────────────

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
      final pendingResult   = await ApiService.getOrders(ownerId: _ownerId, status: 'pending');
      final preparingResult = await ApiService.getOrders(ownerId: _ownerId, status: 'preparing');
      final completedResult = await ApiService.getOrders(ownerId: _ownerId, status: 'completed');
      final cancelledResult = await ApiService.getOrders(ownerId: _ownerId, status: 'cancelled');

      final pendingOrders   = _extractOrders(pendingResult);
      final preparingOrders = _extractOrders(preparingResult);
      final completedOrders = _extractOrders(completedResult);
      final cancelledOrders = _extractOrders(cancelledResult);
      final allOrders       = [...pendingOrders, ...preparingOrders, ...completedOrders, ...cancelledOrders];

      _allCompletedOrders = completedOrders;

      if (!mounted) return;
      setState(() {
        _totalOrders     = allOrders.length;
        _pendingOrders   = pendingOrders.length;
        _confirmedOrders = preparingOrders.length + completedOrders.length;
        _cancelledOrders = cancelledOrders.length;
        _isLoading = false;
      });

      _applyFilter();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Failed to load summary';
      });
    }
  }

  // Re-compute everything from the cached orders whenever the filter changes
  void _applyFilter() {
    final filtered = _filteredOrders;

    // Income = total sell price across all items
    final income = filtered.fold<double>(
      0, (sum, o) => sum + _toDouble(o['total_price']));

    // Profit = sum of (sell_price - cost_price) * qty for every item
    final profit = filtered.fold<double>(0, (sum, order) {
      final items = List<Map<String, dynamic>>.from(
        order['items_list'] ?? order['items'] ?? []);
      return sum + items.fold<double>(0, (s, item) {
        final qty       = int.tryParse('${item['qty']}') ?? 0;
        final sellPrice = _toDouble(item['sell_price'] ?? item['price']);
        final costPrice = _toDouble(item['cost_price'] ?? 0);
        return s + (sellPrice - costPrice) * qty;
      });
    });

    setState(() {
      _totalIncome  = income;
      _totalProfit  = profit;
      _bestSellers  = _buildBestSellers(filtered);
      _dailyPoints  = _buildDailyPoints(filtered);
    });
  }

  // ─────────────────────────────── builders ──────────────────────────────────

  List<Map<String, dynamic>> _extractOrders(Map<String, dynamic> response) {
    final data    = Map<String, dynamic>.from(response['data'] ?? {});
    final payload = Map<String, dynamic>.from(data['data'] ?? {});
    return List<Map<String, dynamic>>.from(payload['orders'] ?? []);
  }

  List<_BestSeller> _buildBestSellers(List<Map<String, dynamic>> orders) {
    final Map<String, _BestSeller> totals = {};

    for (final order in orders) {
      final items = List<Map<String, dynamic>>.from(
        order['items_list'] ?? order['items'] ?? []);

      for (final item in items) {
        final name      = (item['name'] ?? 'Unknown Item').toString();
        final qty       = int.tryParse('${item['qty']}') ?? 0;
        final sellPrice = _toDouble(item['sell_price'] ?? item['price']);
        final costPrice = _toDouble(item['cost_price'] ?? 0);
        final profit    = (sellPrice - costPrice) * qty;

        final current = totals[name];
        if (current == null) {
          totals[name] = _BestSeller(name: name, quantity: qty, profit: profit);
        } else {
          totals[name] = _BestSeller(
            name: current.name,
            quantity: current.quantity + qty,
            profit: current.profit + profit,
          );
        }
      }
    }

    final ranked = totals.values.toList()
      ..sort((a, b) => b.quantity.compareTo(a.quantity));
    return ranked.take(3).toList();
  }

  List<_DailyPoint> _buildDailyPoints(List<Map<String, dynamic>> orders) {
    final from   = _fromDate;
    final days   = _chartDays;
    final Map<String, _DailyPoint> grouped = {};

    for (int i = 0; i < days; i++) {
      final day = DateTime(from.year, from.month, from.day + i);
      grouped[_dayKey(day)] = _DailyPoint(
        label: _shortLabel(day, days),
        orders: 0, income: 0, profit: 0);
    }

    for (final order in orders) {
      final createdAt = DateTime.tryParse('${order['created_at']}');
      if (createdAt == null) continue;
      final day = DateTime(createdAt.year, createdAt.month, createdAt.day);
      final key = _dayKey(day);
      if (!grouped.containsKey(key)) continue;

      final items = List<Map<String, dynamic>>.from(
        order['items_list'] ?? order['items'] ?? []);
      final orderProfit = items.fold<double>(0, (s, item) {
        final qty       = int.tryParse('${item['qty']}') ?? 0;
        final sellPrice = _toDouble(item['sell_price'] ?? item['price']);
        final costPrice = _toDouble(item['cost_price'] ?? 0);
        return s + (sellPrice - costPrice) * qty;
      });

      final current = grouped[key]!;
      grouped[key] = _DailyPoint(
        label:  current.label,
        orders: current.orders + 1,
        income: current.income + _toDouble(order['total_price']),
        profit: current.profit + orderProfit,
      );
    }

    return grouped.values.toList();
  }

  // ─────────────────────────────── date utils ────────────────────────────────

  double _toDouble(dynamic value) =>
      double.tryParse('$value') ?? 0;

  String _dayKey(DateTime date) =>
      '${date.year}-${date.month}-${date.day}';

  String _shortLabel(DateTime date, int totalDays) {
    if (totalDays <= 7) {
      const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return labels[date.weekday - 1];
    }
    if (totalDays <= 14) return '${date.day}/${date.month}';
    // For longer ranges only show every 5th day to avoid crowding
    return '${date.day}/${date.month}';
  }

  String _money(double amount) => amount.toStringAsFixed(2);

  // ─────────────────────────────── date picker ───────────────────────────────

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: _customFrom ?? now.subtract(const Duration(days: 6)),
        end:   _customTo   ?? now,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary:   Colors.orange,
              onPrimary: Colors.white,
              surface:   Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedRange = _DateRange.custom;
        _customFrom    = picked.start;
        _customTo      = picked.end;
      });
      _applyFilter();
    }
  }

  // ─────────────────────────────── build ─────────────────────────────────────

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
                onPressed: _loadSummary, child: const Text('Retry')),
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
          // ── Header ──
          const Text('Order Summary',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          // ── Order count cards (all-time totals, no date filter) ──
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _summaryCard(title: 'Total Orders',     value: '$_totalOrders',     icon: Icons.receipt_long,    color: Colors.orange),
              _summaryCard(title: 'Pending',          value: '$_pendingOrders',   icon: Icons.pending_actions, color: Colors.amber),
              _summaryCard(title: 'Confirmed',        value: '$_confirmedOrders', icon: Icons.check_circle,    color: Colors.green),
              _summaryCard(title: 'Cancelled',        value: '$_cancelledOrders', icon: Icons.cancel,          color: Colors.red),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 8),

          // ── Date range filter ──
          _dateFilterBar(),
          const SizedBox(height: 14),

          // ── Income and profit cards ──
          _financialCard(
            label: 'Total Income',
            value: 'Rs. ${_money(_totalIncome)}',
            icon: Icons.payments,
            gradientColors: const [
              Color(0xFFFFA726),
              Color(0xFFFF7043),
            ],
          ),
          const SizedBox(height: 12),
          _financialCard(
            label: 'Total Profit',
            value: 'Rs. ${_money(_totalProfit)}',
            icon: Icons.trending_up,
            gradientColors: _totalProfit >= 0
                ? [const Color(0xFF66BB6A), const Color(0xFF00897B)]
                : [const Color(0xFFEF5350), const Color(0xFFB71C1C)],
          ),

          const SizedBox(height: 18),
          _salesChartCard(),
          const SizedBox(height: 18),
          _profitChartCard(),
          const SizedBox(height: 18),
          _bestSellerCard(),
        ],
      ),
    );
  }

  // ─────────────────────────────── date filter bar ───────────────────────────

  Widget _dateFilterBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Filter by period',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black54)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ..._DateRange.values.map((range) {
                final isSelected = _selectedRange == range;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      if (range == _DateRange.custom) {
                        _pickCustomRange();
                      } else {
                        setState(() {
                          _selectedRange = range;
                          _customFrom    = null;
                          _customTo      = null;
                        });
                        _applyFilter();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.orange
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? Colors.orange
                              : Colors.grey.shade300,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.orange
                                      .withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          if (range == _DateRange.custom)
                            Icon(
                              Icons.date_range,
                              size: 14,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.black54,
                            ),
                          if (range == _DateRange.custom)
                            const SizedBox(width: 4),
                          Text(
                            range == _DateRange.custom &&
                                    _customFrom != null &&
                                    _customTo != null
                                ? '${_customFrom!.day}/${_customFrom!.month} – ${_customTo!.day}/${_customTo!.month}'
                                : range.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────── widgets ───────────────────────────────────

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return SizedBox(
      width: 160,
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
            Text(value,
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: color)),
            const SizedBox(height: 4),
            Text(title,
                style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _financialCard({
    required String label,
    required String value,
    required IconData icon,
    required List<Color> gradientColors,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: Colors.white70, size: 18),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ]),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _salesChartCard() {
    return _chartContainer(
      title: 'Daily Sales',
      subtitle: 'Completed orders in selected period',
      child: _responsiveLineChart(
        color: Colors.orange,
        values: _dailyPoints.map((p) => p.orders.toDouble()).toList(),
        valueLabel: (v) => '${v.toInt()} orders',
        leftLabelBuilder: (v) => v.toInt().toString(),
      ),
    );
  }

  Widget _profitChartCard() {
    return _chartContainer(
      title: 'Daily Profit',
      subtitle: 'Net profit (sell price − cost price)',
      child: _responsiveLineChart(
        color: Colors.green,
        values: _dailyPoints.map((p) => p.profit).toList(),
        valueLabel: (v) => 'Rs. ${v.toStringAsFixed(0)}',
        leftLabelBuilder: _compactMoneyLabel,
        allowNegative: true,
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
          const Text('Best Selling Products',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Top products from filtered period',
              style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 14),
          if (_bestSellers.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('No completed orders in this period',
                    style: TextStyle(color: Colors.black45)),
              ),
            )
          else
            ..._bestSellers.asMap().entries.map((entry) {
              final index = entry.key;
              final item  = entry.value;
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
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text('${index + 1}',
                          style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text('${item.quantity} sold',
                              style: const TextStyle(
                                  color: Colors.black54, fontSize: 12)),
                        ],
                      ),
                    ),
                    // ── Profit column ──
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Rs. ${_money(item.profit)}',
                            style: TextStyle(
                                color: item.profit >= 0
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                        Text('profit',
                            style: const TextStyle(
                                color: Colors.black45,
                                fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ─────────────────────────────── chart helpers ─────────────────────────────

  Widget _chartContainer({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return LayoutBuilder(builder: (context, constraints) {
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
            Text(title,
                style: TextStyle(
                    fontSize: compact ? 16 : 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: const TextStyle(color: Colors.black54)),
            SizedBox(height: compact ? 12 : 18),
            child,
          ],
        ),
      );
    });
  }

  Widget _responsiveLineChart({
    required Color color,
    required List<double> values,
    required String Function(double) valueLabel,
    required String Function(double) leftLabelBuilder,
    bool allowNegative = false,
  }) {
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 400;

      final maxValue = values.fold<double>(0, (m, v) => v > m ? v : m);
      final minValue = allowNegative
          ? values.fold<double>(0, (m, v) => v < m ? v : m)
          : 0.0;

      final chartMax = maxValue <= 0 ? 1.0 : maxValue * 1.2;
      final chartMin = minValue >= 0 ? 0.0 : minValue * 1.2;

      // Show every Nth label to avoid crowding
      final labelInterval = values.length <= 7
          ? 1
          : values.length <= 14
              ? 2
              : 5;

      return SizedBox(
        height: compact ? 200 : 250,
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: (_dailyPoints.length - 1).toDouble(),
            minY: chartMin,
            maxY: chartMax,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: (chartMax - chartMin) / 4,
              getDrawingHorizontalLine: (_) => FlLine(
                color: Colors.grey.withValues(alpha: 0.15),
                strokeWidth: 1,
              ),
            ),
            // Zero line when profit can be negative
            extraLinesData: allowNegative && chartMin < 0
                ? ExtraLinesData(horizontalLines: [
                    HorizontalLine(
                      y: 0,
                      color: Colors.grey.withValues(alpha: 0.4),
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    )
                  ])
                : null,
            borderData: FlBorderData(
              show: true,
              border: Border(
                left: BorderSide(
                    color: Colors.grey.withValues(alpha: 0.25)),
                bottom: BorderSide(
                    color: Colors.grey.withValues(alpha: 0.25)),
              ),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: compact ? 36 : 44,
                  interval: (chartMax - chartMin) / 4,
                  getTitlesWidget: (value, meta) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(leftLabelBuilder(value),
                        style: TextStyle(
                            fontSize: compact ? 9 : 10,
                            color: Colors.black54)),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: labelInterval.toDouble(),
                  getTitlesWidget: (value, meta) {
                    if ((value - value.roundToDouble()).abs() > 0.001) {
                      return const SizedBox();
                    }
                    final index = value.toInt();
                    if (index < 0 || index >= _dailyPoints.length) {
                      return const SizedBox();
                    }
                    if (index % labelInterval != 0) {
                      return const SizedBox();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(_dailyPoints[index].label,
                          style: TextStyle(
                              fontSize: compact ? 9 : 11,
                              color: Colors.black54)),
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
                    .map((spot) => LineTooltipItem(
                          '${_dailyPoints[spot.x.toInt()].label}\n${valueLabel(spot.y)}',
                          const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12),
                        ))
                    .toList(),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(values.length,
                    (i) => FlSpot(i.toDouble(), values[i])),
                isCurved: true,
                curveSmoothness: 0.25,
                barWidth: compact ? 3 : 4,
                color: color,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (_, __, ___, ____) =>
                      FlDotCirclePainter(
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
    });
  }

  String _compactMoneyLabel(double value) {
    if (value.abs() >= 1000) {
      final k = value / 1000;
      return '${k.toStringAsFixed(value.abs() >= 10000 ? 0 : 1)}k';
    }
    return value.toStringAsFixed(0);
  }
}

// ─────────────────────────────── models ────────────────────────────────────

class _BestSeller {
  final String name;
  final int    quantity;
  final double profit;

  const _BestSeller({
    required this.name,
    required this.quantity,
    required this.profit,
  });
}

class _DailyPoint {
  final String label;
  final int    orders;
  final double income;
  final double profit;

  const _DailyPoint({
    required this.label,
    required this.orders,
    required this.income,
    required this.profit,
  });
}