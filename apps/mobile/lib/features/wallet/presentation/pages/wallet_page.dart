import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spys_api_client/spys_api_client.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../app/presentation/widgets/app_bottom_nav.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ----------------------------
  // UI STATE VARIABLES
  // ----------------------------
  int? selectedAmount;
  String topUpAmount = '';
  String paymentMethod = 'card'; // current selected payment method
  double beursieBalans = 0.0;
  bool isLaaiing = false;
  List<Map<String, dynamic>> transactions = [];
  List<Map<String, dynamic>> toelaeTransactions = [];

  // Bank Card input fields (dummy for now)
  String cardNumber = '';
  String expiryDate = '';
  String cvv = '';
  String cardHolder = '';

  final quickAmounts = [50, 100, 200, 500];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _laaiBeursieData();
  }

  // ----------------------------
  // DATA LAADING METHODS
  // ----------------------------
  Future<void> _laaiBeursieData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final beursieRepo = BeursieRepository(SupabaseDb(Supabase.instance.client));
      final toelaeRepo = ToelaeRepository(SupabaseDb(Supabase.instance.client));
      
      // Laai beursie balans (toelae + wallet - same field)
      final balans = await beursieRepo.kryBeursieBalans(user.id);
      
      // Laai transaksies (wallet transactions)
      final transaksies = await beursieRepo.lysTransaksies(user.id);
      
      // Laai toelae transaksies (allowance transactions - different type)
      final toelaeTransaksies = await toelaeRepo.lysToelaeTransaksies(user.id);
      
      setState(() {
        beursieBalans = balans;
        transactions = transaksies;
        toelaeTransactions = toelaeTransaksies;
      });
    } catch (e) {
      print('Fout met laai beursie data: $e');
    }
  }

  // ----------------------------
  // HANDLER FUNCTIONS
  // ----------------------------
  void handleQuickAmount(int amount) {
    setState(() {
      selectedAmount = amount;
      topUpAmount = amount.toString();
    });
  }

  void handlePaymentMethod(String method) {
    setState(() {
      paymentMethod = method;
    });
  }

  Future<void> _laaiBeursieOp() async {
    if (topUpAmount.isEmpty || double.tryParse(topUpAmount) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voer \'n geldige bedrag in')),
      );
      return;
    }

    final bedrag = double.parse(topUpAmount);
    if (bedrag < 10 || bedrag > 1000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bedrag moet tussen R10 en R1000 wees')),
      );
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jy moet eers aanmeld')),
      );
      return;
    }

    setState(() {
      isLaaiing = true;
    });

    try {
      final beursieRepo = BeursieRepository(SupabaseDb(Supabase.instance.client));
      
      // Simuleer betaling
      final betalingSuksesvol = await beursieRepo.simuleerBetaling(paymentMethod, bedrag);
      
      if (betalingSuksesvol) {
        // Laai beursie op
        final sukses = await beursieRepo.laaiBeursieOp(user.id, bedrag, paymentMethod);
        
        if (sukses) {
          // Herlaai data
          await _laaiBeursieData();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('R$bedrag suksesvol bygevoeg aan jou beursie!')),
          );
          
          // Reset form
          setState(() {
            topUpAmount = '';
            selectedAmount = null;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fout met laai beursie op. Probeer weer.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Betaling het gefaal. Probeer weer.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fout: $e')),
      );
    } finally {
      setState(() {
        isLaaiing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ----------------------------
          // HEADER + WALLET BALANCE
          // ----------------------------
          Container(
            color: Theme.of(context).colorScheme.primary,
            padding: const EdgeInsets.only(
                top: 20, left: 16, right: 16, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button + Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Beursie',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                // Wallet balance card
                Card(
                  color: Theme.of(context).colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Beskikbare Balans',
                                style: TextStyle(
                                    fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                            const SizedBox(height: 8),
                            Text('R${beursieBalans.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold)),
                            Text('Laas opgedateer: Vandag',
                                style: TextStyle(
                                    fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(30)),
                          child: Icon(Icons.account_balance_wallet,
                              size: 32, color: Theme.of(context).colorScheme.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ----------------------------
          // TABS: "Laai Beursie", "Betalings", and "Toelae"
          // ----------------------------
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Laai Beursie'),
              Tab(text: 'Betalings'),
              Tab(text: 'Toelae Geskiedenis'),
            ],
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // ----------------------------
                // TOP-UP TAB
                // ----------------------------
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ----------------------------
                      // QUICK AMOUNTS
                      // ----------------------------
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.add, size: 20),
                                  SizedBox(width: 8),
                                  Text('Kies Bedrag',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                children: quickAmounts.map((amount) {
                                  final isSelected = selectedAmount == amount;
                                  return ChoiceChip(
                                    label: Text('R$amount'),
                                    selected: isSelected,
                                    onSelected: (_) =>
                                        handleQuickAmount(amount),
                                    selectedColor: Theme.of(context).colorScheme.primary,
                                    labelStyle: TextStyle(
                                        color: isSelected
                                            ? Theme.of(context).colorScheme.onPrimary
                                            : Theme.of(context).colorScheme.primary),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 16),
                              const Text('Of voer eie bedrag in'),
                              const SizedBox(height: 8),
                              TextField(
                                decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText:
                                        'Minimum R10, Maksimum R1000'),
                                keyboardType: TextInputType.number,
                                onChanged: (val) {
                                  setState(() {
                                    topUpAmount = val;
                                    selectedAmount = null;
                                  });
                                },
                              ),
                              const SizedBox(height: 4),
                              Text('Minimum: R10 | Maksimum: R1000',
                                  style: TextStyle(
                                      fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ----------------------------
                      // PAYMENT METHOD SELECTION
                      // ----------------------------
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Betaalmetode',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Bank Card button
                                  _paymentMethodButton(
                                      'card', Icons.credit_card, 'Bankkaart'),
                                  _paymentMethodButton(
                                      'snapscan', Icons.smartphone, 'SnapScan'),
                                  _paymentMethodButton(
                                      'eft', Icons.swap_vert, 'EFT'),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // ----------------------------
                              // BANK CARD DETAILS FORM
                              // Only visible when Bank Card is selected
                              // ----------------------------
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: paymentMethod == 'card'
                                    ? Column(
                                        key: const ValueKey('cardForm'),
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Card Number
                                          TextField(
                                            decoration: const InputDecoration(
                                              labelText: 'Kaartnommer',
                                              border: OutlineInputBorder(),
                                              hintText: '1234 5678 9012 3456',
                                            ),
                                            keyboardType: TextInputType.number,
                                            onChanged: (val) =>
                                                cardNumber = val,
                                          ),
                                          const SizedBox(height: 12),
                                          // Expiry & CVV
                                          Row(
                                            children: [
                                              Expanded(
                                                child: TextField(
                                                  decoration:
                                                      const InputDecoration(
                                                          labelText:
                                                              'Vervaldatum (MM/YY)',
                                                          border:
                                                              OutlineInputBorder(),
                                                          hintText: 'MM/YY'),
                                                  keyboardType:
                                                      TextInputType.number,
                                                  onChanged: (val) =>
                                                      expiryDate = val,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: TextField(
                                                  decoration:
                                                      const InputDecoration(
                                                          labelText: 'CVV',
                                                          border:
                                                              OutlineInputBorder(),
                                                          hintText: '123'),
                                                  keyboardType:
                                                      TextInputType.number,
                                                  onChanged: (val) => cvv = val,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          // Card Holder Name
                                          TextField(
                                            decoration: const InputDecoration(
                                              labelText: 'Naam op Kaart',
                                              border: OutlineInputBorder(),
                                              hintText: 'Jou Naam',
                                            ),
                                            onChanged: (val) =>
                                                cardHolder = val,
                                          ),
                                        ],
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ----------------------------
                      // TOP-UP BUTTON
                      // ----------------------------
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary),
                          onPressed: isLaaiing ? null : _laaiBeursieOp,
                          icon: isLaaiing 
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary),
                                  ),
                                )
                              : const Icon(Icons.add),
                          label: Text(
                              isLaaiing 
                                  ? 'Laai...' 
                                  : 'Laai R${topUpAmount.isEmpty ? '0' : topUpAmount}'),
                        ),
                      )
                    ],
                  ),
                ),

                // ----------------------------
                // HISTORY TAB
                // ----------------------------
                transactions.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            'Geen transaksies gevind nie',
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final t = transactions[index];
                          final isInbetaling = t['transaksie_tipe'] != null && 
                              t['transaksie_tipe']['trans_tipe_naam'] == 'inbetaling';
                          final bedrag = (t['trans_bedrag'] as num?)?.toDouble() ?? 0.0;
                          final datum = DateTime.parse(t['trans_geskep_datum']);
                          final datumFormaat = '${datum.day} ${_kryMaandNaam(datum.month)} ${datum.year} ${datum.hour.toString().padLeft(2, '0')}:${datum.minute.toString().padLeft(2, '0')}';
                          
                          // Determine appropriate icon based on transaction type
                          IconData getTransactionIcon() {
                            if (isInbetaling) {
                              return Icons.account_balance_wallet; // Money coming in
                            }
                            
                            final beskrywing = (t['trans_beskrywing'] ?? '').toLowerCase();
                            if (beskrywing.contains('bestelling') || beskrywing.contains('order')) {
                              return Icons.restaurant; // Food order
                            } else if (beskrywing.contains('uitbetaling') || beskrywing.contains('payment')) {
                              return Icons.payment; // Payment made
                            } else if (beskrywing.contains('refund') || beskrywing.contains('terugbetaling')) {
                              return Icons.undo; // Refund
                            } else {
                              return Icons.shopping_cart; // General spending
                            }
                          }
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isInbetaling
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isInbetaling
                                        ? Colors.green.withOpacity(0.3)
                                        : Colors.red.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  getTransactionIcon(),
                                  color: isInbetaling
                                      ? Colors.green.shade600
                                      : Colors.red.shade600,
                                  size: 24,
                                ),
                              ),
                              title: Text(
                                t['trans_beskrywing'] ?? 'Transaksie',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15,
                                ),
                              ),
                              subtitle: Text(
                                datumFormaat,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontSize: 13,
                                ),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isInbetaling
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isInbetaling
                                        ? Colors.green.withOpacity(0.3)
                                        : Colors.red.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  '${isInbetaling ? '+' : '-'}R${bedrag.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isInbetaling
                                        ? Colors.green.shade700
                                        : Colors.red.shade700,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                // ----------------------------
                // ALLOWANCE HISTORY TAB
                // ----------------------------
                toelaeTransactions.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            'Geen toelae transaksies gevind nie',
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: toelaeTransactions.length,
                        itemBuilder: (context, index) {
                          final t = toelaeTransactions[index];
                          final tipeNaam = t['transaksie_tipe'] != null
                              ? t['transaksie_tipe']['trans_tipe_naam'] ?? ''
                              : '';
                          final isInbetaling = tipeNaam.contains('inbetaling');
                          final bedrag = (t['trans_bedrag'] as num?)?.toDouble() ?? 0.0;
                          final datum = DateTime.parse(t['trans_geskep_datum']);
                          final datumFormaat = '${datum.day} ${_kryMaandNaam(datum.month)} ${datum.year} ${datum.hour.toString().padLeft(2, '0')}:${datum.minute.toString().padLeft(2, '0')}';
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isInbetaling
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isInbetaling
                                        ? Colors.green.withOpacity(0.3)
                                        : Colors.red.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  isInbetaling
                                      ? Icons.account_balance_wallet
                                      : Icons.remove_circle_outline,
                                  color: isInbetaling
                                      ? Colors.green.shade600
                                      : Colors.red.shade600,
                                  size: 24,
                                ),
                              ),
                              title: Text(
                                t['trans_beskrywing'] ?? 'Toelae Transaksie',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15,
                                ),
                              ),
                              subtitle: Text(
                                datumFormaat,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontSize: 13,
                                ),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isInbetaling
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isInbetaling
                                        ? Colors.green.withOpacity(0.3)
                                        : Colors.red.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  '${isInbetaling ? '+' : '-'}R${bedrag.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isInbetaling
                                        ? Colors.green.shade700
                                        : Colors.red.shade700,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),

      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }

  // ----------------------------
  // HELPER METHODS
  // ----------------------------
  String _kryMaandNaam(int maand) {
    const maande = [
      'Jan', 'Feb', 'Mrt', 'Apr', 'Mei', 'Jun',
      'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return maande[maand - 1];
  }

  // ----------------------------
  // PAYMENT METHOD BUTTON WIDGET
  // ----------------------------
  Widget _paymentMethodButton(String method, IconData icon, String label) {
    final isSelected = paymentMethod == method;
    return GestureDetector(
      onTap: () => handlePaymentMethod(method),
      child: Container(
        width: 90,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(
              color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.primary),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.primary)),
          ],
        ),
      ),
    );
  }
}
