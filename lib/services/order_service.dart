import 'dart:async';
import 'dart:math';
import '../models/order.dart';
import '../models/cart_item.dart';

class OrderService {
  OrderService();

  final List<Order> _orders = [];
  final StreamController<List<Order>> _ordersController = StreamController<List<Order>>.broadcast();

  Stream<List<Order>> get ordersStream => _ordersController.stream;
  List<Order> get orders => List.unmodifiable(_orders);

  // Initialize with mock orders
  void initialize(String userId) {
    _orders.clear();
    _orders.addAll([
      Order(
        id: '1001',
        userId: userId,
        items: [
          OrderItem(
            menuItemId: '1',
            name: 'Klassieke Burger',
            price: 85.00,
            quantity: 1,
            allergies: ['Gluten', 'Soja'],
          ),
          OrderItem(
            menuItemId: '6',
            name: 'Vars Appelsap',
            price: 25.00,
            quantity: 1,
            allergies: [],
          ),
        ],
        totalAmount: 126.50,
        status: 'ready',
        orderDate: DateTime.now().subtract(const Duration(minutes: 25)),
        pickupLocation: 'Hoofkombuis - Toonbank A',
        qrCode: 'QR_1001_${DateTime.now().millisecondsSinceEpoch}',
        canCancel: false,
        pickupTime: DateTime.now().add(const Duration(minutes: 5)),
        allergiesWarning: ['Gluten', 'Soja'],
      ),
      Order(
        id: '1002',
        userId: userId,
        items: [
          OrderItem(
            menuItemId: '4',
            name: 'Caesar Slaai',
            price: 65.00,
            quantity: 1,
            allergies: ['Gluten', 'Laktose', 'Eiers'],
          ),
          OrderItem(
            menuItemId: '7',
            name: 'Cappuccino',
            price: 35.00,
            quantity: 1,
            allergies: ['Laktose'],
          ),
        ],
        totalAmount: 115.00,
        status: 'processing',
        orderDate: DateTime.now().subtract(const Duration(minutes: 10)),
        pickupLocation: 'Hoofkombuis - Toonbank B',
        qrCode: 'QR_1002_${DateTime.now().millisecondsSinceEpoch}',
        canCancel: true,
        allergiesWarning: ['Gluten', 'Laktose', 'Eiers'],
      ),
      Order(
        id: '1003',
        userId: userId,
        items: [
          OrderItem(
            menuItemId: '10',
            name: 'Quinoa Bowl',
            price: 80.00,
            quantity: 2,
            allergies: ['Sesamsaad'],
          ),
        ],
        totalAmount: 184.00,
        status: 'delivered',
        orderDate: DateTime.now().subtract(const Duration(days: 1)),
        pickupLocation: 'Hoofkombuis - Toonbank A',
        qrCode: 'QR_1003_${DateTime.now().millisecondsSinceEpoch}',
        canCancel: false,
        pickupTime: DateTime.now().subtract(const Duration(days: 1, minutes: -30)),
        feedback: OrderFeedback(
          orderId: '1003',
          rating: 4.5,
          comment: 'Heerlike kos, vinnige diens!',
          submittedAt: DateTime.now().subtract(const Duration(hours: 20)),
        ),
        allergiesWarning: ['Sesamsaad'],
      ),
      Order(
        id: '1004',
        userId: userId,
        items: [
          OrderItem(
            menuItemId: '3',
            name: 'Spek & Kaas Burger',
            price: 95.00,
            quantity: 1,
            allergies: ['Gluten', 'Laktose'],
          ),
        ],
        totalAmount: 109.25,
        status: 'cancelled',
        orderDate: DateTime.now().subtract(const Duration(days: 2)),
        pickupLocation: 'Hoofkombuis - Toonbank A',
        qrCode: 'QR_1004_${DateTime.now().millisecondsSinceEpoch}',
        canCancel: false,
        allergiesWarning: ['Gluten', 'Laktose'],
      ),
    ]);
    
    _ordersController.add(_orders);
  }

  void notifyListeners() {
    _ordersController.add(_orders);
  }

  Future<Order> createOrder({
    required String userId,
    required List<CartItem> cartItems,
    required double totalAmount,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    final orderItems = cartItems.map((cartItem) => OrderItem(
      menuItemId: cartItem.menuItem.id,
      name: cartItem.menuItem.name,
      price: cartItem.menuItem.price,
      quantity: cartItem.quantity,
      specialInstructions: cartItem.specialInstructions,
      allergies: cartItem.menuItem.allergies,
    )).toList();

    final order = Order(
      id: (1000 + _orders.length + 1).toString(),
      userId: userId,
      items: orderItems,
      totalAmount: totalAmount,
      status: 'pending',
      orderDate: DateTime.now(),
      pickupLocation: 'Hoofkombuis - Toonbank ${String.fromCharCode(65 + Random().nextInt(3))}',
      qrCode: 'QR_${1000 + _orders.length + 1}_${DateTime.now().millisecondsSinceEpoch}',
      canCancel: true,
      allergiesWarning: orderItems
          .expand((item) => item.allergies)
          .toSet()
          .toList(),
    );

    _orders.insert(0, order);
    _ordersController.add(_orders);
    
    // Simulate order status updates
    _simulateOrderProgress(order.id);
    
    return order;
  }

  List<Order> getActiveOrders() {
    return _orders.where((order) => 
      order.status == 'pending' || 
      order.status == 'processing' || 
      order.status == 'ready'
    ).toList();
  }

  List<Order> getOrderHistory() {
    return _orders.where((order) => 
      order.status == 'delivered' || 
      order.status == 'cancelled'
    ).toList();
  }

  Order? getOrderById(String orderId) {
    try {
      return _orders.firstWhere((order) => order.id == orderId);
    } catch (e) {
      return null;
    }
  }

  Future<bool> cancelOrder(String orderId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index >= 0 && _orders[index].canCancel) {
      _orders[index] = _orders[index].copyWith(
        status: 'cancelled',
        canCancel: false,
      );
      _ordersController.add(_orders);
      return true;
    }
    return false;
  }

  Future<bool> submitFeedback(String orderId, double rating, String? comment) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index >= 0 && _orders[index].status == 'delivered') {
      final feedback = OrderFeedback(
        orderId: orderId,
        rating: rating,
        comment: comment,
        submittedAt: DateTime.now(),
      );
      
      _orders[index] = _orders[index].copyWith(feedback: feedback);
      _ordersController.add(_orders);
      return true;
    }
    return false;
  }

  void _simulateOrderProgress(String orderId) {
    // Simulate realistic order progression
    Timer(const Duration(seconds: 30), () {
      _updateOrderStatus(orderId, 'processing');
    });
    
    Timer(const Duration(minutes: 15), () {
      _updateOrderStatus(orderId, 'ready');
    });
    
    // Auto-deliver after 1 hour (for demo purposes)
    Timer(const Duration(hours: 1), () {
      _updateOrderStatus(orderId, 'delivered');
    });
  }

  void _updateOrderStatus(String orderId, String newStatus) {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index >= 0) {
      _orders[index] = _orders[index].copyWith(
        status: newStatus,
        canCancel: newStatus == 'pending' || newStatus == 'processing',
        pickupTime: newStatus == 'ready' ? DateTime.now().add(const Duration(minutes: 30)) : null,
      );
      _ordersController.add(_orders);
    }
  }

  void dispose() {
    _ordersController.close();
  }
} 
