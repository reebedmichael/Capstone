import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../core/utils/color_utils.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Add new inventory item
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inventory',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                labelText: 'Search inventory...',
                                prefixIcon: Icon(Icons.search),
                              ),
                              onChanged: (value) {
                                // TODO: Implement search
                              },
                            ),
                          ),
                          const SizedBox(width: AppConstants.paddingMedium),
                          ElevatedButton.icon(
                            onPressed: () {
                              // TODO: Add new item
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Add Item'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.paddingLarge),
                      Expanded(
                        child: ListView.builder(
                          itemCount: 15,
                          itemBuilder: (context, index) {
                            final stockLevel = (index + 1) * 5;
                            final isLowStock = stockLevel < 10;
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: setOpacity(AppConstants.primaryColor, 0.1),
                                child: Icon(
                                  Icons.inventory,
                                  color: AppConstants.primaryColor,
                                ),
                              ),
                              title: Text('Item ${index + 1}'),
                              subtitle: Text('Category ${index % 4 + 1} • Stock: $stockLevel units'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isLowStock)
                                    Chip(
                                      label: const Text('Low Stock'),
                                      backgroundColor: setOpacity(AppConstants.warningColor, 0.1),
                                      labelStyle: const TextStyle(color: AppConstants.warningColor),
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      // TODO: Edit item
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 