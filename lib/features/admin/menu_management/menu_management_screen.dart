import 'package:flutter/material.dart';
import 'package:spys/l10n/app_localizations.dart';

class MenuManagementScreen extends StatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  List<Map<String, dynamic>> menuItems = [
    {'naam': 'Chicken Burger', 'prys': 55, 'beskrywing': 'Heerlike hoenderburger', 'allergene': 'Gluten', 'beskikbaar': 'Ma-Vr'},
    {'naam': 'Beef Wrap', 'prys': 45, 'beskrywing': 'Beesvleis wrap', 'allergene': 'Gluten, Soya', 'beskikbaar': 'Elke dag'},
  ];

  void _showForm({Map<String, dynamic>? item, int? index}) {
    final naamController = TextEditingController(text: item?['naam'] ?? '');
    final prysController = TextEditingController(text: item?['prys']?.toString() ?? '');
    final beskrywingController = TextEditingController(text: item?['beskrywing'] ?? '');
    final allergeneController = TextEditingController(text: item?['allergene'] ?? '');
    final beskikbaarController = TextEditingController(text: item?['beskikbaar'] ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item == null ? AppLocalizations.of(context)!.addMenuItem : AppLocalizations.of(context)!.editMenuItem),
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
                controller: prysController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: AppLocalizations.of(context)!.price, border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: beskrywingController,
                decoration: InputDecoration(labelText: AppLocalizations.of(context)!.description, border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: allergeneController,
                decoration: InputDecoration(labelText: AppLocalizations.of(context)!.allergens, border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: beskikbaarController,
                decoration: InputDecoration(labelText: AppLocalizations.of(context)!.availability, border: const OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.cancel)),
          ElevatedButton(
            onPressed: () {
              if (naamController.text.isEmpty || prysController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.nameAndPriceRequired)));
                return;
              }
              setState(() {
                if (item == null) {
                  menuItems.add({
                    'naam': naamController.text,
                    'prys': int.tryParse(prysController.text) ?? 0,
                    'beskrywing': beskrywingController.text,
                    'allergene': allergeneController.text,
                    'beskikbaar': beskikbaarController.text,
                  });
                } else if (index != null) {
                  menuItems[index] = {
                    'naam': naamController.text,
                    'prys': int.tryParse(prysController.text) ?? 0,
                    'beskrywing': beskrywingController.text,
                    'allergene': allergeneController.text,
                    'beskikbaar': beskikbaarController.text,
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
        title: Text(AppLocalizations.of(context)!.deleteMenuItem),
        content: Text('${AppLocalizations.of(context)!.areYouSureYouWantToDelete} "${menuItems[index]['naam']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.cancel)),
          ElevatedButton(
            onPressed: () {
              setState(() {
                menuItems.removeAt(index);
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
              Text(loc?.menuItems ?? 'Menu Items', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
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
              itemCount: menuItems.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, i) {
                final item = menuItems[i];
                return Card(
                  child: ListTile(
                    title: Text(item['naam'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${item['beskrywing']}\n${loc?.price ?? 'Price'}: R${item['prys']}\n${loc?.allergens ?? 'Allergens'}: ${item['allergene']}\n${loc?.availability ?? 'Availability'}: ${item['beskikbaar']}'),
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
          Text(loc?.backendIntegrationForMenuManagement ?? 'Backend integration for menu management (TODO)', style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
        ],
      ),
    );
  }
} 
