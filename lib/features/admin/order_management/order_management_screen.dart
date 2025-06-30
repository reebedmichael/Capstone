import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../core/utils/color_utils.dart';

class OrderManagementScreen extends StatelessWidget {
  const OrderManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Management'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Orders',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            // Filter tabs
            Row(
              children: [
                _buildFilterChip(context, 'All', true),
                const SizedBox(width: AppConstants.paddingMedium),
                _buildFilterChip(context, 'Pending', false),
                const SizedBox(width: AppConstants.paddingMedium),
                _buildFilterChip(context, 'Processing', false),
                const SizedBox(width: AppConstants.paddingMedium),
                _buildFilterChip(context, 'Completed', false),
                const SizedBox(width: AppConstants.paddingMedium),
                _buildFilterChip(context, 'Cancelled', false),
              ],
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                  child: ListView.builder(
                    itemCount: 15,
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
                              Text('Customer ${index + 1} • \$${(index + 1) * 8}.99'),
                              Text(
                                'Status: $status',
                                style: TextStyle(
                                  color: _getStatusColor(status),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.visibility),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Viewing details for Order #${1000 + index}')),
                                  );
                                },
                              ),
                              if (status == 'Pending')
                                IconButton(
                                  icon: const Icon(Icons.check),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Order #${1000 + index} accepted!')),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, bool isSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Filtered by: $label')),
        );
      },
    );
  }

  String _getOrderStatus(int index) {
    final statuses = ['Pending', 'Processing', 'Completed', 'Cancelled'];
    return statuses[index % statuses.length];
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return AppConstants.warningColor;
      case 'Processing':
        return AppConstants.primaryColor;
      case 'Completed':
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
      case 'Completed':
        return Icons.check_circle;
      case 'Cancelled':
        return Icons.cancel;
      default:
        return Icons.shopping_cart;
    }
  }
} 