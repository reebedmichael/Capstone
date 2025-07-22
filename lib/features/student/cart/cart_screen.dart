import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../core/utils/color_utils.dart';
import '../../../services/cart_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/order_service.dart';
import '../../../models/cart_item.dart';
import '../../../models/user.dart';
import 'package:spys/l10n/app_localizations.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _cartService = CartService();
  final _authService = AuthService();
  final _orderService = OrderService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mandjie'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          StreamBuilder<List<CartItem>>(
            stream: _cartService.cartStream,
            builder: (context, snapshot) {
              final hasItems = _cartService.cartItems.isNotEmpty;
              return hasItems
                ? TextButton(
                    onPressed: () => _showClearCartDialog(),
                    child: const Text(
                      'Maak Leeg',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                : const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: StreamBuilder<List<CartItem>>(
        stream: _cartService.cartStream,
        builder: (context, snapshot) {
          final cartItems = snapshot.data ?? [];
          
          if (cartItems.isEmpty) {
            return _buildEmptyCart();
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final cartItem = cartItems[index];
                    return _buildCartItemCard(cartItem);
                  },
                ),
              ),
              // Checkout Section
              _buildCheckoutSection(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 60,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          Text(
            AppLocalizations.of(context)!.yourCartIsEmpty,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Text(
            AppLocalizations.of(context)!.addItemsFromMenu,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/menu');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
              ),
            ),
            icon: const Icon(Icons.restaurant_menu),
            label: Text(AppLocalizations.of(context)!.viewMenu),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemCard(CartItem cartItem) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Row(
          children: [
            // Item image placeholder
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: setOpacity(AppConstants.primaryColor, 0.1),
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
              ),
              child: Icon(
                Icons.restaurant,
                size: 40,
                color: AppConstants.primaryColor,
              ),
            ),
            
            const SizedBox(width: AppConstants.paddingMedium),
            
            // Item details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cartItem.menuItem.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingSmall),
                  Text(
                    'R${cartItem.menuItem.price.toStringAsFixed(2)} elk',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingSmall),
                  Text(
                    'Totaal: R${cartItem.totalPrice.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            
            // Quantity controls
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () {
                      if (cartItem.quantity > 1) {
                        _cartService.updateQuantity(
                          cartItem.menuItem.id,
                          cartItem.quantity - 1,
                        );
                      } else {
                        _removeItem(cartItem);
                      }
                    },
                    icon: Icon(
                      cartItem.quantity > 1 ? Icons.remove : Icons.delete,
                      color: cartItem.quantity > 1 
                        ? AppConstants.primaryColor 
                        : AppConstants.errorColor,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingSmall),
                    child: Text(
                      cartItem.quantity.toString(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      _cartService.updateQuantity(
                        cartItem.menuItem.id,
                        cartItem.quantity + 1,
                      );
                    },
                    icon: Icon(
                      Icons.add,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutSection() {
    return StreamBuilder<User?>(
      stream: _authService.userStream,
      builder: (context, snapshot) {
        final user = snapshot.data;
        final subtotal = _cartService.subtotal;
        final tax = _cartService.tax;
        final total = _cartService.total;
        final userBalance = user?.walletBalance ?? 0.0;
        final canCheckout = _cartService.canCheckout(userBalance);

        return Container(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: setOpacity(Colors.black, 0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Balance info
              Container(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                decoration: BoxDecoration(
                  color: canCheckout 
                    ? setOpacity(AppConstants.successColor, 0.1)
                    : setOpacity(AppConstants.errorColor, 0.1),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      color: canCheckout ? AppConstants.successColor : AppConstants.errorColor,
                    ),
                    const SizedBox(width: AppConstants.paddingSmall),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.yourBalance,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: canCheckout ? AppConstants.successColor : AppConstants.errorColor,
                        ),
                      ),
                    ),
                    if (!canCheckout)
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/wallet');
                        },
                        child: Text(AppLocalizations.of(context)!.loadUp),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppConstants.paddingMedium),
              
              // Price breakdown
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.subtotal,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    'R${subtotal.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.paddingSmall),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.tax,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    'R${tax.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.total,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'R${total.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                ],
              ),
              
              if (!canCheckout) ...[
                const SizedBox(height: AppConstants.paddingSmall),
                Text(
                  AppLocalizations.of(context)!.shortfall,
                  style: TextStyle(
                    color: AppConstants.errorColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              
              const SizedBox(height: AppConstants.paddingMedium),
              
              // Checkout buttons
              if (canCheckout) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _checkout(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingMedium),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                      ),
                    ),
                    icon: const Icon(Icons.payment),
                    label: Text(AppLocalizations.of(context)!.payNow,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/wallet');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingMedium),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                      ),
                    ),
                    icon: const Icon(Icons.account_balance_wallet),
                    label: Text(
                      AppLocalizations.of(context)!.payDifference,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _removeItem(CartItem cartItem) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.removeItem),
        content: Text('Wil jy ${cartItem.menuItem.name} uit jou mandjie verwyder?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              _cartService.removeFromCart(cartItem.menuItem.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${cartItem.menuItem.name} verwyder uit mandjie'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.errorColor,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context)!.remove),
          ),
        ],
      ),
    );
  }

  void _showClearCartDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.clearCart),
        content: Text(AppLocalizations.of(context)!.clearAllItems),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              _cartService.clearCart();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.cartCleared),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.errorColor,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context)!.clear),
          ),
        ],
      ),
    );
  }

  void _checkout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.confirmOrder),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Totaal: R${_cartService.total.toStringAsFixed(2)}'),
            const SizedBox(height: AppConstants.paddingSmall),
            Text('Items: ${_cartService.itemCount}'),
            const SizedBox(height: AppConstants.paddingMedium),
            Text(AppLocalizations.of(context)!.orderReadyForPickup),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final user = _authService.currentUser;
              if (user != null) {
                try {
                  final order = await _orderService.createOrder(
                    userId: user.id,
                    cartItems: _cartService.cartItems,
                    totalAmount: _cartService.total,
                  );
                  
                  _cartService.clearCart();
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/orders');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Bestelling #${order.id} geplaas! Kyk jou bestellings vir status.'),
                      backgroundColor: AppConstants.successColor,
                    ),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Fout met bestelling: ${e.toString()}'),
                      backgroundColor: AppConstants.errorColor,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context)!.confirm),
          ),
        ],
      ),
    );
  }
} 