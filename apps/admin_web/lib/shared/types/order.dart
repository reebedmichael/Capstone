enum OrderStatus {
  pending,
  preparing,
  readyDelivery,
  readyFetch,
  outForDelivery,
  delivered,
  done,
  cancelled,
}

class OrderItem {
  final String id;
  final String name;
  final int quantity;
  final double price;
  final OrderStatus status;
  final String scheduledDay;

  OrderItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    required this.status,
    required this.scheduledDay,
  });

  OrderItem copyWith({
    String? id,
    String? name,
    int? quantity,
    double? price,
    OrderStatus? status,
    String? scheduledDay,
  }) {
    return OrderItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      status: status ?? this.status,
      scheduledDay: scheduledDay ?? this.scheduledDay,
    );
  }
}

class Order {
  final String id;
  final String customerEmail;
  final String customerId;
  final List<OrderItem> items;
  final List<String> scheduledDays;
  final OrderStatus status;
  final DateTime createdAt;
  final double totalAmount;
  final String deliveryPoint;

  // --- ADD THESE NEW OPTIONAL FIELDS ---
  final String? originalOrderId;
  final String? foodType;

  Order({
    required this.id,
    required this.customerEmail,
    required this.customerId,
    required this.items,
    required this.scheduledDays,
    required this.status,
    required this.createdAt,
    required this.totalAmount,
    required this.deliveryPoint,
    // Add to constructor
    this.originalOrderId,
    this.foodType,
  });

  Order copyWith({
    String? id,
    String? customerEmail,
    String? customerId,
    List<OrderItem>? items,
    List<String>? scheduledDays,
    OrderStatus? status,
    DateTime? createdAt,
    double? totalAmount,
    String? deliveryPoint,
    // Add to copyWith
    String? originalOrderId,
    String? foodType,
  }) {
    return Order(
      id: id ?? this.id,
      customerEmail: customerEmail ?? this.customerEmail,
      customerId: customerId ?? this.customerId,
      items: items ?? this.items,
      scheduledDays: scheduledDays ?? this.scheduledDays,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      totalAmount: totalAmount ?? this.totalAmount,
      deliveryPoint: deliveryPoint ?? this.deliveryPoint,
      // Add to copyWith return
      originalOrderId: originalOrderId ?? this.originalOrderId,
      foodType: foodType ?? this.foodType,
    );
  }
}
