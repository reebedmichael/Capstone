import 'dart:async';
import '../models/cart_item.dart';
import '../models/menu_item.dart';

class CartService {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final List<CartItem> _cartItems = [];
  final StreamController<List<CartItem>> _cartController = StreamController<List<CartItem>>.broadcast();

  Stream<List<CartItem>> get cartStream => _cartController.stream;
  List<CartItem> get cartItems => List.unmodifiable(_cartItems);
  int get itemCount => _cartItems.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => _cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get tax => subtotal * 0.15; // 15% VAT
  double get total => subtotal + tax;

  void addToCart(MenuItem menuItem, {int quantity = 1, String? specialInstructions}) {
    final existingIndex = _cartItems.indexWhere((item) => item.menuItem.id == menuItem.id);
    
    if (existingIndex >= 0) {
      // Update existing item
      final existingItem = _cartItems[existingIndex];
      _cartItems[existingIndex] = existingItem.copyWith(
        quantity: existingItem.quantity + quantity,
        specialInstructions: specialInstructions ?? existingItem.specialInstructions,
      );
    } else {
      // Add new item
      _cartItems.add(CartItem(
        menuItem: menuItem,
        quantity: quantity,
        specialInstructions: specialInstructions,
      ));
    }
    
    _cartController.add(_cartItems);
  }

  void removeFromCart(String menuItemId) {
    _cartItems.removeWhere((item) => item.menuItem.id == menuItemId);
    _cartController.add(_cartItems);
  }

  void updateQuantity(String menuItemId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(menuItemId);
      return;
    }

    final index = _cartItems.indexWhere((item) => item.menuItem.id == menuItemId);
    if (index >= 0) {
      _cartItems[index] = _cartItems[index].copyWith(quantity: quantity);
      _cartController.add(_cartItems);
    }
  }

  void clearCart() {
    _cartItems.clear();
    _cartController.add(_cartItems);
  }

  bool canCheckout(double userBalance) {
    return _cartItems.isNotEmpty && userBalance >= total;
  }

  double getBalanceShortfall(double userBalance) {
    return total - userBalance;
  }

  void dispose() {
    _cartController.close();
  }
} 
