import 'package:flutter/material.dart';

/// Delivery addresses management screen
/// TODO: Implement real address management with:
/// - List of saved delivery addresses
/// - Add new address form with validation
/// - Edit existing addresses
/// - Set default delivery address
/// - Address verification and geocoding
/// - Campus building/dormitory selection
class AddressesScreen extends StatelessWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery Addresses')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.location_on, size: 64, color: Colors.grey),
            SizedBox(height: 24),
            Text('Delivery Addresses - Coming Soon', style: TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
} 