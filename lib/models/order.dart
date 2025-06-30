class Order {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final double totalAmount;
  final String status; // 'pending', 'processing', 'delivered', 'cancelled'
  final DateTime orderDate;
  final String deliveryAddress;
  final String? notes;
  final double deliveryFee;
  final double tax;

  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.orderDate,
    required this.deliveryAddress,
    this.notes,
    this.deliveryFee = 0.0,
    this.tax = 0.0,
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
      deliveryAddress: json['deliveryAddress'],
      notes: json['notes'],
      deliveryFee: json['deliveryFee']?.toDouble() ?? 0.0,
      tax: json['tax']?.toDouble() ?? 0.0,
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
      'deliveryAddress': deliveryAddress,
      'notes': notes,
      'deliveryFee': deliveryFee,
      'tax': tax,
    };
  }
}

class OrderItem {
  final String menuItemId;
  final String name;
  final double price;
  final int quantity;
  final String? specialInstructions;

  OrderItem({
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.quantity,
    this.specialInstructions,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      menuItemId: json['menuItemId'],
      name: json['name'],
      price: json['price']?.toDouble() ?? 0.0,
      quantity: json['quantity'] ?? 1,
      specialInstructions: json['specialInstructions'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'menuItemId': menuItemId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'specialInstructions': specialInstructions,
    };
  }
} 