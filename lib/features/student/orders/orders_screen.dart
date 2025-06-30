import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../core/utils/color_utils.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        itemCount: 10,
        itemBuilder: (context, index) {
          final status = _getOrderStatus(index);
          return Card(
            margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: setOpacity(_getStatusColor(status), 0.1),
                child: Icon(
                  _getStatusIcon(status),
                  color: _getStatusColor(status),
                ),
              ),
              title: Text('Order #${1000 + index}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${index + 1} items • \$${(index + 1) * 8}.99'),
                  Text(
                    'Status: $status',
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: View order details
              },
            ),
          );
        },
      ),
    );
  }

  String _getOrderStatus(int index) {
    final statuses = ['Pending', 'Processing', 'Delivered', 'Cancelled'];
    return statuses[index % statuses.length];
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