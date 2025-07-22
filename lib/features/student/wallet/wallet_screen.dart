import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../core/utils/color_utils.dart';
import '../../../services/auth_service.dart';
import '../../../services/wallet_service.dart';
import '../../../models/user.dart';
import '../../../models/wallet_transaction.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _authService = AuthService();
  final _walletService = WalletService();

  @override
  void initState() {
    super.initState();
    final user = _authService.currentUser;
    if (user != null) {
      _walletService.initialize(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beursie'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<User?>(
        stream: _authService.userStream,
        builder: (context, userSnapshot) {
          final user = userSnapshot.data;
          if (user == null) {
            return const Center(child: Text('Geen gebruiker nie'));
          }

          return Column(
            children: [
              // Balance Card
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(AppConstants.paddingMedium),
                padding: const EdgeInsets.all(AppConstants.paddingLarge),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppConstants.primaryColor, setOpacity(AppConstants.primaryColor, 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                  boxShadow: [
                    BoxShadow(
                      color: setOpacity(AppConstants.primaryColor, 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: AppConstants.paddingSmall),
                        const Text(
                          'Huidige Saldo',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.paddingMedium),
                    Text(
                      'R${user.walletBalance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingLarge),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          icon: Icons.add,
                          label: 'Laai Op',
                          onPressed: () => _showTopUpDialog(),
                        ),
                        _buildActionButton(
                          icon: Icons.history,
                          label: 'Geskiedenis',
                          onPressed: () => _showTransactionHistory(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Quick Actions
              Container(
                margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionCard(
                        icon: Icons.qr_code_scanner,
                        title: 'SnapScan',
                        subtitle: 'Vinnige top-up',
                        color: Colors.green,
                        onTap: () => _showTopUpDialog(defaultMethod: 'snapscan'),
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingMedium),
                    Expanded(
                      child: _buildQuickActionCard(
                        icon: Icons.credit_card,
                        title: 'Kaart',
                        subtitle: 'Debet/Krediet',
                        color: Colors.blue,
                        onTap: () => _showTopUpDialog(defaultMethod: 'card'),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppConstants.paddingMedium),
              
              // Recent Transactions
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Onlangse Transaksies',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () => _showTransactionHistory(),
                            child: const Text('Sien Alles'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.paddingMedium),
                      Expanded(
                        child: StreamBuilder<List<WalletTransaction>>(
                          stream: _walletService.transactionStream,
                          builder: (context, snapshot) {
                            final transactions = snapshot.data ?? [];
                            final recentTransactions = transactions.take(5).toList();
                            
                            if (recentTransactions.isEmpty) {
                              return _buildEmptyTransactions();
                            }

                            return ListView.builder(
                              itemCount: recentTransactions.length,
                              itemBuilder: (context, index) {
                                final transaction = recentTransactions[index];
                                return _buildTransactionCard(transaction);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppConstants.primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingLarge,
          vertical: AppConstants.paddingMedium,
        ),
      ),
      icon: Icon(icon),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                decoration: BoxDecoration(
                  color: setOpacity(color, 0.1),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: AppConstants.paddingSmall),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyTransactions() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Text(
            'Geen transaksies nog nie',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Text(
            'Jou transaksies sal hier verskyn',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(WalletTransaction transaction) {
    final isIncome = transaction.amount > 0;
    final color = isIncome ? AppConstants.successColor : AppConstants.errorColor;
    final icon = _getTransactionIcon(transaction.type);

    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(AppConstants.paddingSmall),
          decoration: BoxDecoration(
            color: setOpacity(color, 0.1),
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          transaction.description,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatDateTime(transaction.createdAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            if (transaction.referenceNumber != null)
              Text(
                'Ref: ${transaction.referenceNumber}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                  fontSize: 10,
                ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isIncome ? '+' : ''}R${transaction.amount.abs().toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 16,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor(transaction.status),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _getStatusText(transaction.status),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        isThreeLine: transaction.referenceNumber != null,
      ),
    );
  }

  IconData _getTransactionIcon(String type) {
    switch (type) {
      case 'topup':
        return Icons.add_circle;
      case 'payment':
        return Icons.shopping_cart;
      case 'refund':
        return Icons.replay;
      default:
        return Icons.attach_money;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return AppConstants.successColor;
      case 'pending':
        return AppConstants.warningColor;
      case 'failed':
        return AppConstants.errorColor;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'completed':
        return 'VOLTOOI';
      case 'pending':
        return 'AFWAGTING';
      case 'failed':
        return 'GEFAAL';
      default:
        return status.toUpperCase();
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} min gelede';
      } else {
        return '${difference.inHours}h gelede';
      }
    } else if (difference.inDays == 1) {
      return 'Gister';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  void _showTopUpDialog({String? defaultMethod}) {
    double amount = 50.0;
    String paymentMethod = defaultMethod ?? 'snapscan';
    final amountController = TextEditingController(text: amount.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Laai Beursie Op'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Bedrag',
                  prefixText: 'R ',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  amount = double.tryParse(value) ?? 50.0;
                },
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              Row(
                children: [
                  const Text('Betaalmetode:'),
                  const SizedBox(width: AppConstants.paddingSmall),
                  Expanded(
                    child: DropdownButton<String>(
                      value: paymentMethod,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'snapscan', child: Text('SnapScan')),
                        DropdownMenuItem(value: 'card', child: Text('Kaart')),
                        DropdownMenuItem(value: 'eft', child: Text('EFT')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          paymentMethod = value ?? 'snapscan';
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              // Quick amount buttons
              Wrap(
                spacing: 8,
                children: [50, 100, 200, 500].map((quickAmount) {
                  return ActionChip(
                    label: Text('R$quickAmount'),
                    onPressed: () {
                      setState(() {
                        amount = quickAmount.toDouble();
                        amountController.text = quickAmount.toString();
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kanselleer'),
            ),
            ElevatedButton(
              onPressed: () => _processTopUp(amount, paymentMethod),
              child: const Text('Laai Op'),
            ),
          ],
        ),
      ),
    );
  }

  void _processTopUp(double amount, String paymentMethod) async {
    Navigator.pop(context);
    
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: AppConstants.paddingMedium),
            Text('Verwerk betaling...'),
          ],
        ),
      ),
    );

    final user = _authService.currentUser;
    if (user != null) {
      final success = await _walletService.topUpWallet(
        userId: user.id,
        amount: amount,
        paymentMethod: paymentMethod,
      );

      Navigator.pop(context); // Close loading dialog

      if (success) {
        // Update user balance
        final updatedUser = user.copyWith(
          walletBalance: user.walletBalance + amount,
        );
        _authService.updateProfile(updatedUser);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('R${amount.toStringAsFixed(2)} suksesvol bygevoeg!'),
            backgroundColor: AppConstants.successColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Top-up het gefaal. Probeer weer.'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  void _showTransactionHistory() {
    // TODO: Navigate to full transaction history screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Volledige transaksie geskiedenis kom binnekort!'),
      ),
    );
  }
} 