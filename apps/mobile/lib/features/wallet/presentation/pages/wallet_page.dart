import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
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

  // Bank Card input fields (dummy for now)
  String cardNumber = '';
  String expiryDate = '';
  String cvv = '';
  String cardHolder = '';

  // Mock transactions
  final List<Map<String, dynamic>> transactions = [
    {
      'type': 'debit',
      'amount': 45.00,
      'description': 'Boerewors en Pap - Hoofkampus Kafeteria',
      'date': '20 Jul 2024 12:30',
      'status': 'completed'
    },
    {
      'type': 'credit',
      'amount': 200.00,
      'description': 'Beursie Top-up - Bankkaart',
      'date': '19 Jul 2024 14:15',
      'status': 'completed'
    },
    {
      'type': 'debit',
      'amount': 38.00,
      'description': 'Vegetariese Pasta - Hoofkampus Kafeteria',
      'date': '18 Jul 2024 13:45',
      'status': 'completed'
    },
  ];

  final quickAmounts = [50, 100, 200, 500];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ----------------------------
          // HEADER + WALLET BALANCE
          // ----------------------------
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.only(
                top: 40, left: 16, right: 16, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button + Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    Text('Beursie',
                        style: AppTypography.titleLarge
                            .copyWith(color: Colors.white)),
                    const SizedBox(width: 40), // spacing
                  ],
                ),
                const SizedBox(height: 16),
                // Wallet balance card
                Card(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Beskikbare Balans',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 8),
                            const Text('R0.00',
                                style: TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold)),
                            const Text('Laas opgedateer: Vandag',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(30)),
                          child: Icon(Icons.account_balance_wallet,
                              size: 32, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ----------------------------
          // TABS: "Laai Beursie" and "Geskiedenis"
          // ----------------------------
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Laai Beursie'),
              Tab(text: 'Geskiedenis'),
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
                                    selectedColor: AppColors.primary,
                                    labelStyle: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : AppColors.primary),
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
                              const Text('Minimum: R10 | Maksimum: R1000',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey)),
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
                              backgroundColor: AppColors.primary),
                          onPressed: () {
                            // DUMMY ACTION: Show snackbar
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Top-up clicked')));
                          },
                          icon: const Icon(Icons.add),
                          label: Text(
                              'Laai R${topUpAmount.isEmpty ? '0' : topUpAmount}'),
                        ),
                      )
                    ],
                  ),
                ),

                // ----------------------------
                // HISTORY TAB
                // ----------------------------
                ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final t = transactions[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: t['type'] == 'credit'
                              ? Colors.green.shade100
                              : Colors.red.shade100,
                          child: Icon(
                            t['type'] == 'credit'
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color: t['type'] == 'credit'
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        title: Text(t['description']),
                        subtitle: Text(t['date']),
                        trailing: Text(
                          '${t['type'] == 'credit' ? '+' : '-'}R${t['amount'].toStringAsFixed(2)}',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: t['type'] == 'credit'
                                  ? Colors.green
                                  : Colors.red),
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
              color: isSelected ? AppColors.primary : Colors.grey),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? AppColors.primary : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? Colors.white : AppColors.primary),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? Colors.white : AppColors.primary)),
          ],
        ),
      ),
    );
  }
}
