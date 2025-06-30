import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../core/utils/color_utils.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              itemCount: 5,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: setOpacity(AppConstants.primaryColor, 0.1),
                      child: Icon(
                        Icons.restaurant,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                    title: Text('Item ${index + 1}'),
                    subtitle: Text('\$${(index + 1) * 5}.99'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            // TODO: Decrease quantity
                          },
                        ),
                        Text('${index + 1}'),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            // TODO: Increase quantity
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Checkout Section
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '\$45.99',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Proceed to checkout
                    },
                    child: const Text('Checkout'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 