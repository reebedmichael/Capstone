import 'package:flutter/material.dart';

class KpiCards extends StatelessWidget {
  final double mediaWidth;

  const KpiCards({Key? key, required this.mediaWidth}) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildKpiCard(
          title: 'Totale verkope vandag',
          icon: Icons.attach_money,
          value: '\$8,234',
          subtitle: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.trending_up, size: 14, color: Colors.green),
              SizedBox(width: 6),
              Text('+12.5% van gister', style: TextStyle(fontSize: 12)),
            ],
          ),
          width: _kpiWidth(mediaWidth),
        ),
        _buildKpiCard(
          title: 'Bestellings vandag',
          icon: Icons.shopping_cart,
          value: '152',
          subtitle: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.trending_up, size: 14, color: Colors.green),
              SizedBox(width: 6),
              Text('+8.2% van gister', style: TextStyle(fontSize: 12)),
            ],
          ),
          width: _kpiWidth(mediaWidth),
        ),
        _buildKpiCard(
          title: 'Populêre Kos Items',
          icon: Icons.emoji_food_beverage,
          value: 'Grilled Chicken Salad',
          subtitle: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.trending_up, size: 14, color: Colors.green),
              SizedBox(width: 6),
              Text(
                '127 bestellings vandag (+18%)',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          width: _kpiWidth(mediaWidth),
          valueIsLarge: false,
        ),
        _buildKpiCard(
          title: 'Kos items nog nie afgehandel nie',
          icon: Icons.schedule,
          value: '23',
          subtitle: const Text('', style: TextStyle(fontSize: 12)),
          width: _kpiWidth(mediaWidth),
        ),
      ],
    );
  }
}
