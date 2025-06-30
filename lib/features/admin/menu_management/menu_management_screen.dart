import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../core/utils/color_utils.dart';

class MenuManagementScreen extends StatelessWidget {
  const MenuManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Add new menu item
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
              'Menu Items',
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
                                labelText: 'Search menu items...',
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
                          itemCount: 10,
                          itemBuilder: (context, index) {
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: setOpacity(AppConstants.primaryColor, 0.1),
                                child: Icon(
                                  Icons.restaurant,
                                  color: AppConstants.primaryColor,
                                ),
                              ),
                              title: Text('Menu Item ${index + 1}'),
                              subtitle: Text('Category ${index % 3 + 1} • \$${(index + 1) * 5}.99'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      // TODO: Edit item
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () {
                                      // TODO: Delete item
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