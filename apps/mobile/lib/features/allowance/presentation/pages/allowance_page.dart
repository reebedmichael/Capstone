import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../locator.dart';
import 'package:spys_api_client/spys_api_client.dart';

class AllowancePage extends StatefulWidget {
  const AllowancePage({super.key});

  @override
  State<AllowancePage> createState() => _AllowancePageState();
}

class _AllowancePageState extends State<AllowancePage> {
  bool _loading = true;
  Map<String, dynamic>? _allowanceInfo;
  double? _walletBalance;

  @override
  void initState() {
    super.initState();
    _loadAllowanceData();
  }

  Future<void> _loadAllowanceData() async {
    setState(() => _loading = true);
    
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      // Load allowance info
      final allowanceInfo = await sl<AllowanceRepository>().getUserAllowance(user.id);
      
      // Load wallet balance
      final walletData = await Supabase.instance.client
          .from('gebruikers')
          .select('beursie_balans')
          .eq('gebr_id', user.id)
          .maybeSingle();
      
      setState(() {
        _allowanceInfo = allowanceInfo;
        _walletBalance = walletData?['beursie_balans']?.toDouble();
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading allowance data: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Toelae')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final double monthlyAllowance = _allowanceInfo?['aktiewe_toelaag']?.toDouble() ?? 0.0;
    final double currentBalance = _walletBalance ?? 0.0;
    final double estimatedSpent = monthlyAllowance - currentBalance;
    final double spendingPercentage = monthlyAllowance > 0 
        ? (estimatedSpent / monthlyAllowance) * 100 
        : 0.0;
    
    // Check if user is Ekstern (no allowance)
    final userType = _allowanceInfo?['gebr_tipe_naam'] ?? '';
    final isEkstern = userType == 'Ekstern' || monthlyAllowance == 0;

    final DateTime nextAllowanceDate = DateTime(2025, 9, 1);

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
          return Icon(Icons.check_circle, color: Theme.of(context).colorScheme.tertiary, size: 20);
        case 'pending':
          return Icon(Icons.access_time, color: Theme.of(context).colorScheme.error, size: 20);
        case 'failed':
          return Icon(Icons.error, color: Theme.of(context).colorScheme.error, size: 20);
        default:
          return Icon(Icons.help_outline, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20);
      }
    }

    Color statusColor(String status) {
      switch (status) {
        case 'received':
          return Theme.of(context).colorScheme.tertiary;
        case 'pending':
          return Theme.of(context).colorScheme.error;
        case 'failed':
          return Theme.of(context).colorScheme.error;
        default:
          return Theme.of(context).colorScheme.onSurfaceVariant;
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
            // Special message for Ekstern users
            if (isEkstern)
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Wag vir Goedkeuring',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Jou rekening is geregistreer as $userType. Admin goedkeuring is benodig om toelae te ontvang en alle funksies te gebruik.',
                        style: TextStyle(color: Colors.orange.shade700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Jy kan steeds kos bestel, maar toelae-afhanklike funksies is nie beskikbaar nie.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Current Month Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEkstern ? 'Toelae Status' : 'Hierdie maand se toelae',
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
                    if (_allowanceInfo != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _allowanceInfo!['toelaag_bron'] ?? 'No allowance',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (_allowanceInfo!['gebr_tipe_naam'] != null)
                        Text(
                          'Tipe: ${_allowanceInfo!['gebr_tipe_naam']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                    const SizedBox(height: 8),
                    if (!isEkstern) ...[
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
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Geen toelae toegeken - wag vir admin goedkeuring',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
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
