import 'package:flutter/material.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<Map<String, dynamic>> users = [
    {'naam': 'Jan Smit', 'rol': 'Admin', 'aktief': true, 'laasteLogin': 'Vandag 08:00'},
    {'naam': 'Piet Pienaar', 'rol': 'Superadmin', 'aktief': false, 'laasteLogin': 'Gister 17:30'},
    {'naam': 'Anna Jacobs', 'rol': 'Admin', 'aktief': true, 'laasteLogin': 'Vandag 09:15'},
  ];

  void _approveUser(int index) {
    setState(() {
      users[index]['aktief'] = true;
    });
    // TODO: Backend integration for approve
  }

  void _disableUser(int index) {
    setState(() {
      users[index]['aktief'] = false;
    });
    // TODO: Backend integration for disable
  }

  void _deleteUser(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verwyder gebruiker'),
        content: Text('Is jy seker jy wil "${users[index]['naam']}" verwyder?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kanselleer')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                users.removeAt(index);
              });
              Navigator.pop(context);
              // TODO: Backend integration for delete
            },
            child: const Text('Verwyder'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Gebruikers', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: users.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, i) {
                final user = users[i];
                return Card(
                  child: ListTile(
                    leading: Icon(user['rol'] == 'Superadmin' ? Icons.verified_user : Icons.person, color: user['rol'] == 'Superadmin' ? Colors.orange : Colors.blue),
                    title: Text(user['naam'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Rol: ${user['rol']}\nStatus: ${user['aktief'] ? 'Aktief' : 'Geblok'}\nLaaste login: ${user['laasteLogin']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(user['aktief'] ? Icons.block : Icons.check_circle, color: user['aktief'] ? Colors.red : Colors.green),
                          tooltip: user['aktief'] ? 'Disable' : 'Approve',
                          onPressed: () => user['aktief'] ? _disableUser(i) : _approveUser(i),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteUser(i),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          const Text('// TODO: Backend integration for user management', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
        ],
      ),
    );
  }
} 