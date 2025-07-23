import 'package:flutter/material.dart';
import 'package:spys/l10n/app_localizations.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<Map<String, dynamic>> voorraad = [
    {'naam': 'Hoender', 'hoeveelheid': 20, 'laasteByvoeg': '2024-06-01'},
    {'naam': 'Beesvleis', 'hoeveelheid': 10, 'laasteByvoeg': '2024-06-02'},
  ];

  void _showForm({Map<String, dynamic>? item, int? index}) {
    final naamController = TextEditingController(text: item?['naam'] ?? '');
    final hoeveelheidController = TextEditingController(text: item?['hoeveelheid']?.toString() ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item == null ? AppLocalizations.of(context)!.addInventory : AppLocalizations.of(context)!.editInventory),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: naamController,
                decoration: InputDecoration(labelText: AppLocalizations.of(context)!.name, border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: hoeveelheidController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: AppLocalizations.of(context)!.quantity, border: const OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.cancel)),
          ElevatedButton(
            onPressed: () {
              if (naamController.text.isEmpty || hoeveelheidController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.nameAndQuantityRequired)));
                return;
              }
              setState(() {
                if (item == null) {
                  voorraad.add({
                    'naam': naamController.text,
                    'hoeveelheid': int.tryParse(hoeveelheidController.text) ?? 0,
                    'laasteByvoeg': DateTime.now().toString().split(' ')[0],
                  });
                } else if (index != null) {
                  voorraad[index] = {
                    'naam': naamController.text,
                    'hoeveelheid': int.tryParse(hoeveelheidController.text) ?? 0,
                    'laasteByvoeg': DateTime.now().toString().split(' ')[0],
                  };
                }
              });
              Navigator.pop(context);
              // TODO: Backend integration for add/edit
            },
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
  }

  void _deleteItem(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteInventory),
        content: Text('Is jy seker jy wil "${voorraad[index]['naam']}" verwyder?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.cancel)),
          ElevatedButton(
            onPressed: () {
              setState(() {
                voorraad.removeAt(index);
              });
              Navigator.pop(context);
              // TODO: Backend integration for delete
            },
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(loc?.inventory ?? 'Inventory', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () => _showForm(),
                icon: const Icon(Icons.add),
                label: Text(loc?.add ?? 'Add'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: voorraad.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, i) {
                final item = voorraad[i];
                return Card(
                  child: ListTile(
                    title: Text(item['naam'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${loc?.quantity ?? 'Quantity'}: ${item['hoeveelheid']}\n${loc?.lastAdded ?? 'Last Added'}: ${item['laasteByvoeg']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit), onPressed: () => _showForm(item: item, index: i)),
                        IconButton(icon: const Icon(Icons.delete), onPressed: () => _deleteItem(i)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(loc?.backendIntegrationInventory ?? 'Backend integration for inventory (TODO)', style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
        ],
      ),
    );
  }
} 
