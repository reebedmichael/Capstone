import 'package:flutter/material.dart';
import 'package:spys_api_client/spys_api_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class KpiCards extends StatefulWidget {
  final double mediaWidth;

  const KpiCards({Key? key, required this.mediaWidth}) : super(key: key);

  @override
  State<KpiCards> createState() => _KpiCardsState();
}

class _KpiCardsState extends State<KpiCards> {
  late final AdminDashboardRepository _repo;
  Map<String, dynamic>? _kpiData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final supabaseClient = Supabase.instance.client;
    _repo = AdminDashboardRepository(SupabaseDb(supabaseClient));
    _loadKpiData();
  }

  Future<void> _loadKpiData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final data = await _repo.fetcKpiStats();
      setState(() {
        _kpiData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  double _kpiWidth(double mediaWidth) {
    if (mediaWidth >= 1200) return (mediaWidth - 64) / 5 - 8;
    if (mediaWidth >= 800) return (mediaWidth - 48) / 3 - 8;
    return mediaWidth - 32;
  }

  Widget _buildKpiCard({
    required String title,
    required IconData icon,
    required String value,
    required Widget subtitle,
    double? width,
    bool valueIsLarge = true,
  }) {
    return SizedBox(
      width: width ?? 300,
      child: Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(icon, size: 18, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: valueIsLarge ? 20 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              subtitle,
            ],
          ),
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    return 'R${amount.toStringAsFixed(2)}';
  }

  String _calculatePercentageChange(double today, double yesterday) {
    if (yesterday == 0) return '+0%';
    final change = ((today - yesterday) / yesterday) * 100;
    return '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}%';
  }

  Color _getTrendColor(double today, double yesterday) {
    if (yesterday == 0) return Colors.grey;
    return today >= yesterday ? Colors.green : Colors.red;
  }

  IconData _getTrendIcon(double today, double yesterday) {
    if (yesterday == 0) return Icons.trending_flat;
    return today >= yesterday ? Icons.trending_up : Icons.trending_down;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: List.generate(
          4,
          (index) => SizedBox(
            width: _kpiWidth(widget.mediaWidth),
            child: Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 20,
                      width: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 24,
                      width: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 16,
                      width: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.error, color: Colors.red, size: 48),
              const SizedBox(height: 8),
              Text(
                'Kon nie KPI data laai nie',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade700),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _loadKpiData,
                icon: Icon(Icons.refresh),
                label: Text('Probeer weer'),
              ),
            ],
          ),
        ),
      );
    }

    final data = _kpiData!;
    final todayEarnings = data['todayEarnings'] as double;
    final yesterdayEarnings = data['yesterdayEarnings'] as double;
    final todayOrders = data['todayOrders'] as int;
    final yesterdayOrders = data['yesterdayOrders'] as int;
    final mostPopularItem = data['mostPopularItem'] as String?;
    final uncompletedOrders = data['uncompletedOrders'] as int;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildKpiCard(
          title: 'Totale verkope vandag',
          icon: Icons.money_sharp,
          value: _formatCurrency(todayEarnings),
          subtitle: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getTrendIcon(todayEarnings, yesterdayEarnings),
                size: 14,
                color: _getTrendColor(todayEarnings, yesterdayEarnings),
              ),
              const SizedBox(width: 6),
              Text(
                '${_calculatePercentageChange(todayEarnings, yesterdayEarnings)} van gister',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          width: _kpiWidth(widget.mediaWidth),
        ),
        _buildKpiCard(
          title: 'Bestellings vandag',
          icon: Icons.shopping_cart,
          value: todayOrders.toString(),
          subtitle: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getTrendIcon(
                  todayOrders.toDouble(),
                  yesterdayOrders.toDouble(),
                ),
                size: 14,
                color: _getTrendColor(
                  todayOrders.toDouble(),
                  yesterdayOrders.toDouble(),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${_calculatePercentageChange(todayOrders.toDouble(), yesterdayOrders.toDouble())} van gister',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          width: _kpiWidth(widget.mediaWidth),
        ),
        _buildKpiCard(
          title: 'Populêre Kos Items',
          icon: Icons.emoji_food_beverage,
          value: mostPopularItem ?? 'Geen data',
          subtitle: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star, size: 14, color: Colors.orange),
              const SizedBox(width: 6),
              Text(
                'Meeste bestellings vandag',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          width: _kpiWidth(widget.mediaWidth),
          valueIsLarge: false,
        ),
        _buildKpiCard(
          title: 'Kos Items',
          icon: Icons.schedule,
          value: uncompletedOrders.toString(),
          subtitle: const Text(
            'Items nog nie afgehandel nie',
            style: TextStyle(fontSize: 12),
          ),
          width: _kpiWidth(widget.mediaWidth),
        ),
      ],
    );
  }
}
