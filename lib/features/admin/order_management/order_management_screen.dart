import 'package:flutter/material.dart';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  List<Map<String, dynamic>> orders = [
    {
      'id': 1,
      'gebruiker': 'Jan Smit',
      'items': 'Burger x2, Friet x1',
      'status': 'In verwerking',
      'tyd': '09:30',
      'datum': '2024-06-15',
      'totaal': 85.50,
      'betaalmetode': 'Kredietkaart',
      'adres': '123 Main Street, Cape Town',
      'telefoon': '+27 81 123 4567',
      'besonderhede': 'Geen mayo op burger'
    },
    {
      'id': 2,
      'gebruiker': 'Piet Pienaar',
      'items': 'Wrap x1, Cooldrink x1',
      'status': 'Gereed',
      'tyd': '10:00',
      'datum': '2024-06-15',
      'totaal': 45.00,
      'betaalmetode': 'Kontant',
      'adres': '456 Oak Avenue, Stellenbosch',
      'telefoon': '+27 82 987 6543',
      'besonderhede': 'Extra saus'
    },
    {
      'id': 3,
      'gebruiker': 'Anna Jacobs',
      'items': 'Pizza x1, Salad x1',
      'status': 'Afgehandel',
      'tyd': '08:45',
      'datum': '2024-06-15',
      'totaal': 125.75,
      'betaalmetode': 'EFT',
      'adres': '789 Pine Road, Durban',
      'telefoon': '+27 83 456 7890',
      'besonderhede': 'Vegetariese pizza'
    },
  ];
  String statusFilter = 'Alle';
  final statusOptions = ['Alle', 'In verwerking', 'Gereed', 'Afgehandel', 'Kanselleer'];

  void _showOrderDetails(Map<String, dynamic> order, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bestelling #${order['id']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Kliënt:', order['gebruiker'].toString()),
              _buildDetailRow('Items:', order['items'].toString()),
              _buildDetailRow('Status:', order['status'].toString()),
              _buildDetailRow('Tyd:', '${order['datum']} ${order['tyd']}'),
              _buildDetailRow('Totaal:', 'R${order['totaal'].toStringAsFixed(2)}'),
              _buildDetailRow('Betaalmetode:', order['betaalmetode'].toString()),
              _buildDetailRow('Adres:', order['adres'].toString()),
              _buildDetailRow('Telefoon:', order['telefoon'].toString()),
              _buildDetailRow('Besonderhede:', order['besonderhede'].toString()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Sluit'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditOrderDialog(order, index);
            },
            child: const Text('Wysig'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showEditOrderDialog(Map<String, dynamic> order, int index) {
    String selectedStatus = order['status'];
    final besondsheldeController = TextEditingController(text: order['besonderhede']);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Wysig Bestelling #${order['id']}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: statusOptions.where((s) => s != 'Alle').map((status) =>
                    DropdownMenuItem(value: status, child: Text(status))
                  ).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedStatus = value ?? selectedStatus;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: besondsheldeController,
                  decoration: const InputDecoration(
                    labelText: 'Besonderhede',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kanselleer'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  orders[index]['status'] = selectedStatus;
                  orders[index]['besonderhede'] = besondsheldeController.text;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Bestelling #${order['id']} gewysig')),
                );
                // TODO: Backend integration for edit
              },
              child: const Text('Stoor'),
            ),
          ],
        ),
      ),
    );
  }



  void _cancelOrder(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kanselleer bestelling'),
        content: Text('Is jy seker jy wil bestelling #${orders[index]['id']} kanselleer?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Nee')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                orders[index]['status'] = 'Kanselleer';
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Bestelling #${orders[index]['id']} gekanselleer')),
              );
              // TODO: Backend integration for cancel
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Ja, kanselleer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'In verwerking':
        return const Color(0xFFE64A19);
      case 'Gereed':
        return Colors.green;
      case 'Afgehandel':
        return Colors.blue;
      case 'Kanselleer':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredOrders = statusFilter == 'Alle'
        ? orders
        : orders.where((o) => o['status'] == statusFilter).toList();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Bestellings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Text('Filter: ', style: Theme.of(context).textTheme.bodyMedium),
                  DropdownButton<String>(
                    value: statusFilter,
                    items: statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) => setState(() => statusFilter = val ?? 'Alle'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: filteredOrders.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, i) {
                final order = filteredOrders[i];
                final originalIndex = orders.indexOf(order);
                return Card(
                  elevation: 2,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(order['status']),
                      child: Text(
                        '#${order['id']}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text('${order['gebruiker']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      'Items: ${order['items']}\n'
                      'Totaal: R${order['totaal'].toStringAsFixed(2)}\n'
                      'Tyd: ${order['datum']} ${order['tyd']}'
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'view':
                            _showOrderDetails(order, originalIndex);
                            break;
                          case 'edit':
                            _showEditOrderDialog(order, originalIndex);
                            break;
                          case 'cancel':
                            if (order['status'] != 'Kanselleer') {
                              _cancelOrder(originalIndex);
                            }
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'view',
                          child: Row(
                            children: [
                              Icon(Icons.visibility, size: 20),
                              SizedBox(width: 8),
                              Text('Bekyk Details'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 8),
                              Text('Wysig'),
                            ],
                          ),
                        ),
                        if (order['status'] != 'Kanselleer')
                          const PopupMenuItem(
                            value: 'cancel',
                            child: Row(
                              children: [
                                Icon(Icons.cancel, size: 20, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Kanselleer', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          const Text('// TODO: Backend integration for order management', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
        ],
      ),
    );
  }
} 
