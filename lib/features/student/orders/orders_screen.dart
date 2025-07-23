import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../services/order_service.dart';
import '../../../services/auth_service.dart';
import '../../../models/order.dart';
import 'order_detail_screen.dart';
import '../../../core/utils/color_utils.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  final _orderService = OrderService();
  final _authService = AuthService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final user = _authService.currentUser;
    _orderService.initialize(user?.id ?? 'demo_user');
    // Trigger initial data load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _orderService.notifyListeners();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bestellings'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: setOpacity(Colors.white, 0.7),
          tabs: const [
            Tab(
              icon: Icon(Icons.access_time),
              text: 'Aktief',
            ),
            Tab(
              icon: Icon(Icons.history),
              text: 'Geskiedenis',
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<Order>>(
        stream: _orderService.ordersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          return TabBarView(
            controller: _tabController,
            children: [
              _buildOrdersList(_orderService.getActiveOrders(), isActive: true),
              _buildOrdersList(_orderService.getOrderHistory(), isActive: false),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOrdersList(List<Order> orders, {required bool isActive}) {
    if (orders.isEmpty) {
      return _buildEmptyState(isActive);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderCard(order, isActive);
      },
    );
  }

  Widget _buildEmptyState(bool isActive) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isActive ? Icons.access_time : Icons.history,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Text(
            isActive ? 'Geen aktiewe bestellings' : 'Geen geskiedenis',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Text(
            isActive 
              ? 'Jou aktiewe bestellings sal hier verskyn'
              : 'Jou voltooide bestellings sal hier verskyn',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          if (isActive) ...[
            const SizedBox(height: AppConstants.paddingLarge),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/menu');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.restaurant_menu),
              label: const Text('Kyk Spyskaart'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order, bool isActive) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailScreen(orderId: order.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppConstants.paddingSmall),
                    decoration: BoxDecoration(
                      color: setOpacity(_getStatusColor(order.status), 0.1),
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                    ),
                    child: Icon(
                      _getStatusIcon(order.status),
                      color: _getStatusColor(order.status),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bestelling #${order.id}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _formatDate(order.orderDate),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'R${order.totalAmount.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppConstants.primaryColor,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.paddingSmall,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(order.status),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _getStatusText(order.status),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: AppConstants.paddingMedium),
              
              // Items summary
              Text(
                '${order.items.length} ${order.items.length == 1 ? 'item' : 'items'}: ${order.items.map((item) => '${item.quantity}x ${item.name}').join(', ')}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              // Pickup location and time
              if (order.status == 'ready' && order.pickupTime != null) ...[
                const SizedBox(height: AppConstants.paddingSmall),
                Container(
                  padding: const EdgeInsets.all(AppConstants.paddingSmall),
                  decoration: BoxDecoration(
                    color: setOpacity(AppConstants.successColor, 0.1),
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: AppConstants.successColor,
                        size: 16,
                      ),
                      const SizedBox(width: AppConstants.paddingSmall),
                      Expanded(
                        child: Text(
                          '${order.pickupLocation} • Gereed tot ${_formatTime(order.pickupTime!)}',
                          style: const TextStyle(
                            color: AppConstants.successColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Allergies warning
              if (order.allergiesWarning.isNotEmpty) ...[
                const SizedBox(height: AppConstants.paddingSmall),
                Container(
                  padding: const EdgeInsets.all(AppConstants.paddingSmall),
                  decoration: BoxDecoration(
                    color: setOpacity(AppConstants.warningColor, 0.1),
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning,
                        color: AppConstants.warningColor,
                        size: 16,
                      ),
                      const SizedBox(width: AppConstants.paddingSmall),
                      Expanded(
                        child: Text(
                          'Allergieë: ${order.allergiesWarning.join(', ')}',
                          style: const TextStyle(
                            color: AppConstants.warningColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Feedback indicator
              if (order.status == 'delivered' && order.feedback != null) ...[
                const SizedBox(height: AppConstants.paddingSmall),
                Row(
                  children: [
                    const Icon(
                      Icons.star,
                      color: AppConstants.warningColor,
                      size: 16,
                    ),
                    const SizedBox(width: AppConstants.paddingSmall),
                    Text(
                      'Terugvoer gegee: ${order.feedback!.rating}/5',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ] else if (order.status == 'delivered') ...[
                const SizedBox(height: AppConstants.paddingSmall),
                Row(
                  children: [
                    Icon(
                      Icons.star_border,
                      color: Colors.grey[400],
                      size: 16,
                    ),
                    const SizedBox(width: AppConstants.paddingSmall),
                    const Text(
                      'Gee terugvoer',
                      style: TextStyle(
                        color: AppConstants.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
              
              const SizedBox(height: AppConstants.paddingSmall),
              
              // Action row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderDetailScreen(orderId: order.id),
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('Sien Detail'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'AFWAGTING';
      case 'processing':
        return 'BESIG';
      case 'ready':
        return 'GEREED';
      case 'delivered':
        return 'AFGELEWER';
      case 'cancelled':
        return 'GEKANSELLEER';
      default:
        return status.toUpperCase();
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minute gelede';
      } else {
        return '${difference.inHours} uur gelede';
      }
    } else if (difference.inDays == 1) {
      return 'Gister';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return AppConstants.warningColor;
      case 'Processing':
        return AppConstants.primaryColor;
      case 'Delivered':
        return AppConstants.successColor;
      case 'Cancelled':
        return AppConstants.errorColor;
      default:
        return AppConstants.primaryColor;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Pending':
        return Icons.pending;
      case 'Processing':
        return Icons.restaurant;
      case 'Delivered':
        return Icons.check_circle;
      case 'Cancelled':
        return Icons.cancel;
      default:
        return Icons.shopping_cart;
    }
  }
} 
