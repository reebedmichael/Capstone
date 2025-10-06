import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:spys_api_client/spys_api_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SalesOverview extends StatefulWidget {
  const SalesOverview({Key? key}) : super(key: key);

  @override
  State<SalesOverview> createState() => _SalesOverviewState();
}

class _SalesOverviewState extends State<SalesOverview> {
  late final AdminDashboardRepository _repo;
  List<Map<String, dynamic>>? _weeklySalesData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final supabaseClient = Supabase.instance.client;
    _repo = AdminDashboardRepository(SupabaseDb(supabaseClient));
    _loadWeeklySalesData();
  }

  Future<void> _loadWeeklySalesData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final data = await _repo.fetchWeeklySales();
      setState(() {
        _weeklySalesData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatCurrency(double amount) {
    return 'R${amount.toInt()}';
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    const days = ['Ma', 'Di', 'Wo', 'Do', 'Vr', 'Sa', 'So'];
    return days[date.weekday - 1];
  }

  Widget _buildLineChart() {
    if (_weeklySalesData == null || _weeklySalesData!.isEmpty) {
      return Container(
        height: 320,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade100,
        ),
        child: const Center(
          child: Text(
            'Geen verkope data beskikbaar',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final data = _weeklySalesData!;
    final maxSales = data.fold<double>(
      0,
      (max, item) => (item['totalSales'] as num).toDouble() > max
          ? (item['totalSales'] as num).toDouble()
          : max,
    );

    return Container(
      height: 320,
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: maxSales > 0 ? maxSales / 5 : 1,
            verticalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(color: Colors.grey.shade300, strokeWidth: 1);
            },
            getDrawingVerticalLine: (value) {
              return FlLine(color: Colors.grey.shade300, strokeWidth: 1);
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (double value, TitleMeta meta) {
                  if (value.toInt() < data.length) {
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        _formatDate(data[value.toInt()]['date']),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: maxSales > 0 ? maxSales / 2 : 1,
                reservedSize: 40,
                getTitlesWidget: (double value, TitleMeta meta) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      _formatCurrency(value),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.shade300),
          ),
          minX: 0,
          maxX: (data.length - 1).toDouble(),
          minY: 0,
          maxY: maxSales,
          lineBarsData: [
            LineChartBarData(
              spots: data.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value['totalSales']);
              }).toList(),
              isCurved: true,
              gradient: LinearGradient(
                colors: [
                  Colors.deepOrange.shade400,
                  Colors.deepOrange.shade600,
                ],
              ),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.deepOrange.shade600,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    Colors.deepOrange.shade400.withOpacity(0.3),
                    Colors.deepOrange.shade600.withOpacity(0.1),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Card(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Verkope Oorsig',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Weeklikse verkope prestasie',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    if (_isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Chart or loading/error state
                if (_isLoading)
                  Container(
                    height: 320,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.shade100,
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Laai verkope data...'),
                        ],
                      ),
                    ),
                  )
                else if (_errorMessage != null)
                  Container(
                    height: 320,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.red.shade50,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, color: Colors.red, size: 48),
                          const SizedBox(height: 8),
                          Text(
                            'Kon nie verkope data laai nie',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade700),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _loadWeeklySalesData,
                            icon: Icon(Icons.refresh),
                            label: Text('Probeer weer'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  _buildLineChart(),
              ],
            ),
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: ElevatedButton(
            onPressed: () => context.go('/verslae'),

            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Text('Meer'),
          ),
        ),
      ],
    );
  }
}
