import 'dart:async';
import 'dart:math';
import '../models/wallet_transaction.dart';

class WalletService {
  static final WalletService _instance = WalletService._internal();
  factory WalletService() => _instance;
  WalletService._internal();

  final List<WalletTransaction> _transactions = [];
  final StreamController<List<WalletTransaction>> _transactionController = 
      StreamController<List<WalletTransaction>>.broadcast();

  Stream<List<WalletTransaction>> get transactionStream => _transactionController.stream;
  List<WalletTransaction> get transactions => List.unmodifiable(_transactions);

  void initialize(String userId) {
    _transactions.clear();
    _transactions.addAll([
      WalletTransaction(
        id: '1001',
        userId: userId,
        amount: 200.00,
        type: 'topup',
        description: 'SnapScan Top-up',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        status: 'completed',
        paymentMethod: 'snapscan',
        referenceNumber: 'SS_2024001',
      ),
      WalletTransaction(
        id: '1002',
        userId: userId,
        amount: -126.50,
        type: 'payment',
        description: 'Bestelling #1001 - Klassieke Burger & Appelsap',
        createdAt: DateTime.now().subtract(const Duration(days: 2, hours: 2)),
        status: 'completed',
        referenceNumber: 'ORD_1001',
      ),
      WalletTransaction(
        id: '1003',
        userId: userId,
        amount: 100.00,
        type: 'topup',
        description: 'Kaart Top-up',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        status: 'completed',
        paymentMethod: 'card',
        referenceNumber: 'CD_2024002',
      ),
      WalletTransaction(
        id: '1004',
        userId: userId,
        amount: -115.00,
        type: 'payment',
        description: 'Bestelling #1002 - Caesar Slaai & Cappuccino',
        createdAt: DateTime.now().subtract(const Duration(hours: 10)),
        status: 'completed',
        referenceNumber: 'ORD_1002',
      ),
      WalletTransaction(
        id: '1005',
        userId: userId,
        amount: 109.25,
        type: 'refund',
        description: 'Terugbetaling - Bestelling #1004 Gekanselleer',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        status: 'completed',
        referenceNumber: 'REF_1004',
      ),
    ]);
    
    _transactionController.add(_transactions);
  }

  Future<bool> topUpWallet({
    required String userId,
    required double amount,
    required String paymentMethod,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    // Simulate 90% success rate
    if (Random().nextDouble() < 0.9) {
      final transaction = WalletTransaction(
        id: (1000 + _transactions.length + 1).toString(),
        userId: userId,
        amount: amount,
        type: 'topup',
        description: '${_getPaymentMethodName(paymentMethod)} Top-up',
        createdAt: DateTime.now(),
        status: 'completed',
        paymentMethod: paymentMethod,
        referenceNumber: '${_getPaymentMethodCode(paymentMethod)}_${DateTime.now().millisecondsSinceEpoch}',
      );

      _transactions.insert(0, transaction);
      _transactionController.add(_transactions);
      return true;
    } else {
      // Simulate failed transaction
      final transaction = WalletTransaction(
        id: (1000 + _transactions.length + 1).toString(),
        userId: userId,
        amount: amount,
        type: 'topup',
        description: '${_getPaymentMethodName(paymentMethod)} Top-up - GEFAAL',
        createdAt: DateTime.now(),
        status: 'failed',
        paymentMethod: paymentMethod,
        referenceNumber: '${_getPaymentMethodCode(paymentMethod)}_${DateTime.now().millisecondsSinceEpoch}',
      );

      _transactions.insert(0, transaction);
      _transactionController.add(_transactions);
      return false;
    }
  }

  Future<bool> processPayment({
    required String userId,
    required double amount,
    required String description,
    required String referenceNumber,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    final transaction = WalletTransaction(
      id: (1000 + _transactions.length + 1).toString(),
      userId: userId,
      amount: -amount,
      type: 'payment',
      description: description,
      createdAt: DateTime.now(),
      status: 'completed',
      referenceNumber: referenceNumber,
    );

    _transactions.insert(0, transaction);
    _transactionController.add(_transactions);
    return true;
  }

  Future<bool> processRefund({
    required String userId,
    required double amount,
    required String description,
    required String referenceNumber,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    final transaction = WalletTransaction(
      id: (1000 + _transactions.length + 1).toString(),
      userId: userId,
      amount: amount,
      type: 'refund',
      description: description,
      createdAt: DateTime.now(),
      status: 'completed',
      referenceNumber: referenceNumber,
    );

    _transactions.insert(0, transaction);
    _transactionController.add(_transactions);
    return true;
  }

  List<WalletTransaction> getTransactionsByType(String type) {
    return _transactions.where((t) => t.type == type).toList();
  }

  List<WalletTransaction> getRecentTransactions({int limit = 10}) {
    return _transactions.take(limit).toList();
  }

  double calculateBalance() {
    return _transactions.fold(0.0, (sum, transaction) {
      return sum + transaction.amount;
    });
  }

  List<WalletTransaction> getTransactionsForDateRange(DateTime start, DateTime end) {
    return _transactions.where((t) => 
      t.createdAt.isAfter(start) && t.createdAt.isBefore(end)
    ).toList();
  }

  String _getPaymentMethodName(String method) {
    switch (method) {
      case 'snapscan':
        return 'SnapScan';
      case 'card':
        return 'Kaart';
      case 'eft':
        return 'EFT';
      default:
        return method;
    }
  }

  String _getPaymentMethodCode(String method) {
    switch (method) {
      case 'snapscan':
        return 'SS';
      case 'card':
        return 'CD';
      case 'eft':
        return 'EFT';
      default:
        return 'XX';
    }
  }

  void dispose() {
    _transactionController.close();
  }
} 
