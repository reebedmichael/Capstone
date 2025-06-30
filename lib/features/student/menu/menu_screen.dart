import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../core/utils/color_utils.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Search menu
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Categories
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: AppConstants.paddingMedium),
                  child: Chip(
                    label: Text('Category ${index + 1}'),
                    backgroundColor: index == 0 
                      ? AppConstants.primaryColor 
                      : setOpacity(AppConstants.primaryColor, 0.1),
                    labelStyle: TextStyle(
                      color: index == 0 ? Colors.white : AppConstants.primaryColor,
                    ),
                  ),
                );
              },
            ),
          ),
          // Menu Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              itemCount: 20,
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
                    title: Text('Menu Item ${index + 1}'),
                    subtitle: Text('Category ${index % 5 + 1} • \$${(index + 1) * 5}.99'),
                    trailing: ElevatedButton(
                      onPressed: () {
                        // TODO: Add to cart
                      },
                      child: const Text('Add'),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 