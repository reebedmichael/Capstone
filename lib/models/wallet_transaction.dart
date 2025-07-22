class WalletTransaction {
  final String id;
  final String userId;
  final double amount;
  final String type; // 'topup', 'payment', 'refund'
  final String description;
  final DateTime createdAt;
  final String status; // 'pending', 'completed', 'failed'
  final String? paymentMethod; // 'snapscan', 'card', 'eft'
  final String? referenceNumber;

  WalletTransaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.description,
    required this.createdAt,
    this.status = 'completed',
    this.paymentMethod,
    this.referenceNumber,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'],
      userId: json['userId'],
      amount: json['amount']?.toDouble() ?? 0.0,
      type: json['type'],
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      status: json['status'] ?? 'completed',
      paymentMethod: json['paymentMethod'],
      referenceNumber: json['referenceNumber'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'type': type,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
      'paymentMethod': paymentMethod,
      'referenceNumber': referenceNumber,
    };
  }

  WalletTransaction copyWith({
    String? id,
    String? userId,
    double? amount,
    String? type,
    String? description,
    DateTime? createdAt,
    String? status,
    String? paymentMethod,
    String? referenceNumber,
  }) {
    return WalletTransaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      referenceNumber: referenceNumber ?? this.referenceNumber,
    );
  }
} 