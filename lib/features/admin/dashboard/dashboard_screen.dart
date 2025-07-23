import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String selectedPeriod = 'Vandag';

  @override
  Widget build(BuildContext context) {
    // Dynamic data based on selected period
    final stats = _getStatsForPeriod(selectedPeriod);
    
    if (stats.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1200;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with period selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)?.dashboard ?? 'Dashboard',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButton<String>(
                      value: selectedPeriod,
                      underline: const SizedBox(),
                      items: ['Vandag', 'Hierdie Week', 'Hierdie Maand', 'Hierdie Jaar'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedPeriod = value ?? 'Vandag';
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Stats Cards
              isWide 
                ? Row(
                    children: stats.asMap().entries.map((entry) {
                      final index = entry.key;
                      final stat = entry.value;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: index < stats.length - 1 ? 16 : 0),
                          child: _buildStatCard(stat),
                        ),
                      );
                    }).toList(),
                  )
                : Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: stats.map((stat) => SizedBox(
                      width: constraints.maxWidth > 48 ? (constraints.maxWidth - 48) / 2 : 150,  // Two cards per row on mobile
                      child: _buildStatCard(stat),
                    )).toList(),
                  ),
              
              const SizedBox(height: 32),
              
              // Recent Activity Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Onlangse Aktiwiteite',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 5,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final activities = [
                            {'title': 'Nuwe bestelling ontvang', 'time': '2 min gelede', 'icon': Icons.shopping_bag},
                            {'title': 'Gebruiker geregistreer', 'time': '5 min gelede', 'icon': Icons.person_add},
                            {'title': 'Betaling verwerk', 'time': '10 min gelede', 'icon': Icons.payment},
                            {'title': 'Menu item bygevoeg', 'time': '15 min gelede', 'icon': Icons.restaurant_menu},
                            {'title': 'Terugvoer ontvang', 'time': '20 min gelede', 'icon': Icons.feedback},
                          ];
                          final activity = activities[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                              child: Icon(
                                activity['icon'] as IconData,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            title: Text(activity['title'] as String),
                            subtitle: Text(activity['time'] as String),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _getStatsForPeriod(String period) {
    switch (period) {
      case 'Vandag':
        return [
          {'label': 'Bestellings Vandag', 'value': 23, 'icon': Icons.shopping_cart, 'color': const Color(0xFFBF360C), 'change': 15},
          {'label': 'Inkomste Vandag', 'value': 'R1,250', 'icon': Icons.attach_money, 'color': Colors.green, 'change': 8},
          {'label': 'Nuwe Gebruikers', 'value': 5, 'icon': Icons.person_add, 'color': const Color(0xFFBF360C), 'change': 12},
          {'label': 'Aktiewe Gebruikers', 'value': 87, 'icon': Icons.people, 'color': Colors.purple, 'change': 3},
        ];
      case 'Hierdie Week':
        return [
          {'label': 'Bestellings Hierdie Week', 'value': 187, 'icon': Icons.shopping_cart, 'color': const Color(0xFFBF360C), 'change': 8},
          {'label': 'Inkomste Hierdie Week', 'value': 'R12,450', 'icon': Icons.attach_money, 'color': Colors.green, 'change': 15},
          {'label': 'Nuwe Gebruikers', 'value': 34, 'icon': Icons.person_add, 'color': const Color(0xFFBF360C), 'change': 20},
          {'label': 'Aktiewe Gebruikers', 'value': 245, 'icon': Icons.people, 'color': Colors.purple, 'change': 5},
        ];
      case 'Hierdie Maand':
        return [
          {'label': 'Bestellings Hierdie Maand', 'value': 750, 'icon': Icons.shopping_cart, 'color': const Color(0xFFBF360C), 'change': 25},
          {'label': 'Inkomste Hierdie Maand', 'value': 'R45,230', 'icon': Icons.attach_money, 'color': Colors.green, 'change': 18},
          {'label': 'Nuwe Gebruikers', 'value': 123, 'icon': Icons.person_add, 'color': const Color(0xFFBF360C), 'change': 30},
          {'label': 'Aktiewe Gebruikers', 'value': 567, 'icon': Icons.people, 'color': Colors.purple, 'change': 12},
        ];
      default:
        return [
          {'label': 'Bestellings Hierdie Jaar', 'value': 8420, 'icon': Icons.shopping_cart, 'color': const Color(0xFFBF360C), 'change': 35},
          {'label': 'Inkomste Hierdie Jaar', 'value': 'R523,400', 'icon': Icons.attach_money, 'color': Colors.green, 'change': 42},
          {'label': 'Nuwe Gebruikers', 'value': 1234, 'icon': Icons.person_add, 'color': const Color(0xFFBF360C), 'change': 45},
          {'label': 'Aktiewe Gebruikers', 'value': 2341, 'icon': Icons.people, 'color': Colors.purple, 'change': 28},
        ];
    }
  }

  Widget _buildStatCard(Map<String, dynamic> stat) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (stat['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: (stat['color'] as Color).withOpacity(0.3)),
                  ),
                  child: Icon(
                    stat['icon'] as IconData,
                    color: stat['color'] as Color,
                    size: 24,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '+${stat['change']}%',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              stat['value'].toString(),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: stat['color'] as Color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              stat['label'] as String,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

