import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AllowancePage extends StatelessWidget {
  const AllowancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final double monthlyAllowance = 1000.0;
    final double currentBalance = 90.0;
    final double estimatedSpent = monthlyAllowance - currentBalance;
    final double spendingPercentage = (estimatedSpent / monthlyAllowance) * 100;

    final DateTime nextAllowanceDate = DateTime(2025, 9, 1);
    final int dayOfMonth = DateTime.now().day;
    final double monthProgress = (dayOfMonth / 30) * 100;

    final List<Map<String, dynamic>> allowanceHistory = [
      {
        'id': '1',
        'amount': 1000.0,
        'date': DateTime(2025, 8, 1),
        'status': 'received',
        'month': 'Augustus 2025',
      },
      {
        'id': '2',
        'amount': 1000.0,
        'date': DateTime(2025, 7, 1),
        'status': 'received',
        'month': 'Julie 2025',
      },
      {
        'id': '3',
        'amount': 1000.0,
        'date': DateTime(2025, 6, 1),
        'status': 'received',
        'month': 'Junie 2025',
      },
    ];

    Widget statusIcon(String status) {
      switch (status) {
        case 'received':
          return const Icon(Icons.check_circle, color: Colors.green, size: 20);
        case 'pending':
          return const Icon(Icons.access_time, color: Colors.orange, size: 20);
        case 'failed':
          return const Icon(Icons.error, color: Colors.red, size: 20);
        default:
          return const Icon(Icons.help_outline, color: Colors.grey, size: 20);
      }
    }

    Color statusColor(String status) {
      switch (status) {
        case 'received':
          return Colors.green;
        case 'pending':
          return Colors.orange;
        case 'failed':
          return Colors.red;
        default:
          return Colors.grey;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Maandelikse Toelae"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/settings');
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Month Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hierdie maand se toelae',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    Text(
                      'R${monthlyAllowance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: spendingPercentage / 100,
                      minHeight: 8,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        spendingPercentage > 80 ? Colors.red : Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Besteding: R${estimatedSpent.toStringAsFixed(2)} (${spendingPercentage.toStringAsFixed(0)}%)',
                      style: TextStyle(
                        color: spendingPercentage > 80
                            ? Colors.red
                            : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Next Allowance Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Volgende Toelae',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('R${monthlyAllowance.toStringAsFixed(2)}'),
                        Text(
                          '${nextAllowanceDate.day}-${nextAllowanceDate.month}-${nextAllowanceDate.year}',
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const Icon(Icons.access_time, color: Colors.orange),
                        Text(
                          '${(nextAllowanceDate.difference(DateTime.now()).inDays)} dag(e) oor',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            // Toelae Inligting Section
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Toelae Inligting',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Jou maandelikse toelae is '
                      'R$monthlyAllowance.',
                    ),
                    Text(
                      '• Jy het R$currentBalance oor van jou toelae vir hierdie maand.',
                    ),
                    const Text(
                      '• Die toelae sal op die eerste dag van elke maand ontvang word.',
                    ),
                    const Text(
                      '• Bestee jou toelae oor die maand om nie oor jou begroting te gaan nie.',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            // Allowance Info (Spending Tips)

            // Allowance History
            const Text(
              'Toelae Geskiedenis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...allowanceHistory.map((record) {
              return Card(
                child: ListTile(
                  leading: statusIcon(record['status']),
                  title: Text(record['month']),
                  subtitle: Text(
                    '${record['date'].day}-${record['date'].month}-${record['date'].year}',
                  ),
                  trailing: Text(
                    'R${record['amount'].toStringAsFixed(2)}',
                    style: TextStyle(
                      color: statusColor(record['status']),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 16),
            Card(
              color: Colors.amber[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Besteding Wenke',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Beplan jou weeklikse besteding (ongeveer R250.00 per week)',
                    ),
                    Text('• Kyk uit vir spesiale aanbiedinge en afslag'),
                    Text('• Oorweeg goedkoper opsies as jou balans laag raak'),
                    Text(
                      '• Monitor jou besteding gereeld in die beursie seksie',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            // Bottom Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      context.go('/wallet');
                    },
                    icon: const Icon(Icons.wallet),
                    label: const Text("Bekyk Beursie"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      backgroundColor: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
