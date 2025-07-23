class Order {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final double totalAmount;
  final String status; // 'pending', 'processing', 'ready', 'delivered', 'cancelled'
  final DateTime orderDate;
  final String pickupLocation;
  final String? notes;
  final double deliveryFee;
  final double tax;
  final String? qrCode;
  final bool canCancel;
  final DateTime? pickupTime;
  final OrderFeedback? feedback;
  final List<String> allergiesWarning;

  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.orderDate,
    required this.pickupLocation,
    this.notes,
    this.deliveryFee = 0.0,
    this.tax = 0.0,
    this.qrCode,
    this.canCancel = true,
    this.pickupTime,
    this.feedback,
    this.allergiesWarning = const [],
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      userId: json['userId'],
      items: (json['items'] as List)
          .map((item) => OrderItem.fromJson(item))
          .toList(),
      totalAmount: json['totalAmount']?.toDouble() ?? 0.0,
      status: json['status'],
      orderDate: DateTime.parse(json['orderDate']),
      pickupLocation: json['pickupLocation'] ?? json['deliveryAddress'] ?? '',
      notes: json['notes'],
      deliveryFee: json['deliveryFee']?.toDouble() ?? 0.0,
      tax: json['tax']?.toDouble() ?? 0.0,
      qrCode: json['qrCode'],
      canCancel: json['canCancel'] ?? true,
      pickupTime: json['pickupTime'] != null ? DateTime.parse(json['pickupTime']) : null,
      feedback: json['feedback'] != null ? OrderFeedback.fromJson(json['feedback']) : null,
      allergiesWarning: List<String>.from(json['allergiesWarning'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'items': items.map((item) => item.toJson()).toList(),
      'totalAmount': totalAmount,
      'status': status,
      'orderDate': orderDate.toIso8601String(),
      'pickupLocation': pickupLocation,
      'notes': notes,
      'deliveryFee': deliveryFee,
      'tax': tax,
      'qrCode': qrCode,
      'canCancel': canCancel,
      'pickupTime': pickupTime?.toIso8601String(),
      'feedback': feedback?.toJson(),
      'allergiesWarning': allergiesWarning,
    };
  }

  Order copyWith({
    String? id,
    String? userId,
    List<OrderItem>? items,
    double? totalAmount,
    String? status,
    DateTime? orderDate,
    String? pickupLocation,
    String? notes,
    double? deliveryFee,
    double? tax,
    String? qrCode,
    bool? canCancel,
    DateTime? pickupTime,
    OrderFeedback? feedback,
    List<String>? allergiesWarning,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      orderDate: orderDate ?? this.orderDate,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      notes: notes ?? this.notes,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      tax: tax ?? this.tax,
      qrCode: qrCode ?? this.qrCode,
      canCancel: canCancel ?? this.canCancel,
      pickupTime: pickupTime ?? this.pickupTime,
      feedback: feedback ?? this.feedback,
      allergiesWarning: allergiesWarning ?? this.allergiesWarning,
    );
  }
}

class OrderItem {
  final String menuItemId;
  final String name;
  final double price;
  final int quantity;
  final String? specialInstructions;
  final List<String> allergies;

  OrderItem({
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.quantity,
    this.specialInstructions,
    this.allergies = const [],
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      menuItemId: json['menuItemId'],
      name: json['name'],
      price: json['price']?.toDouble() ?? 0.0,
      quantity: json['quantity'] ?? 1,
      specialInstructions: json['specialInstructions'],
      allergies: List<String>.from(json['allergies'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'menuItemId': menuItemId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'specialInstructions': specialInstructions,
      'allergies': allergies,
    };
  }

  OrderItem copyWith({
    String? menuItemId,
    String? name,
    double? price,
    int? quantity,
    String? specialInstructions,
    List<String>? allergies,
  }) {
    return OrderItem(
      menuItemId: menuItemId ?? this.menuItemId,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      allergies: allergies ?? this.allergies,
    );
  }
}

class OrderFeedback {
  final String orderId;
  final double rating;
  final String? comment;
  final DateTime submittedAt;

  OrderFeedback({
    required this.orderId,
    required this.rating,
    this.comment,
    required this.submittedAt,
  });

  factory OrderFeedback.fromJson(Map<String, dynamic> json) {
    return OrderFeedback(
      orderId: json['orderId'],
      rating: json['rating']?.toDouble() ?? 0.0,
      comment: json['comment'],
      submittedAt: DateTime.parse(json['submittedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'rating': rating,
      'comment': comment,
      'submittedAt': submittedAt.toIso8601String(),
    };
  }
} 
