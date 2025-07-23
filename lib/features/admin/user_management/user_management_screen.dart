import 'package:flutter/material.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<Map<String, dynamic>> users = [
    {'naam': 'Jan Smit', 'email': 'jan@spys.co.za', 'rol': 'Admin', 'aktief': true, 'laasteLogin': 'Vandag 08:00', 'geregistreer': '2024-01-15'},
    {'naam': 'Piet Pienaar', 'email': 'piet@spys.co.za', 'rol': 'Superadmin', 'aktief': false, 'laasteLogin': 'Gister 17:30', 'geregistreer': '2024-01-10'},
    {'naam': 'Anna Jacobs', 'email': 'anna@spys.co.za', 'rol': 'Admin', 'aktief': true, 'laasteLogin': 'Vandag 09:15', 'geregistreer': '2024-02-01'},
  ];

  void _showEditUserDialog({Map<String, dynamic>? user, int? index}) {
    final naamController = TextEditingController(text: user?['naam'] ?? '');
    final emailController = TextEditingController(text: user?['email'] ?? '');
    String selectedRole = user?['rol'] ?? 'Admin';
    bool isActive = user?['aktief'] ?? true;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(user == null ? 'Voeg Gebruiker By' : 'Wysig Gebruiker'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: naamController,
                  decoration: const InputDecoration(
                    labelText: 'Naam',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-pos',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Rol',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Admin', 'Superadmin'].map((role) =>
                    DropdownMenuItem(value: role, child: Text(role))
                  ).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedRole = value ?? 'Admin';
                    });
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Aktief'),
                  value: isActive,
                  onChanged: (value) {
                    setDialogState(() {
                      isActive = value;
                    });
                  },
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
                if (naamController.text.isEmpty || emailController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Naam en e-pos is vereist')),
                  );
                  return;
                }

                setState(() {
                  if (user == null) {
                    // Add new user
                    users.add({
                      'naam': naamController.text,
                      'email': emailController.text,
                      'rol': selectedRole,
                      'aktief': isActive,
                      'laasteLogin': 'Nog nie ingeteken nie',
                      'geregistreer': DateTime.now().toString().split(' ')[0],
                    });
                  } else if (index != null) {
                    // Edit existing user
                    users[index] = {
                      ...users[index],
                      'naam': naamController.text,
                      'email': emailController.text,
                      'rol': selectedRole,
                      'aktief': isActive,
                    };
                  }
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(user == null ? 'Gebruiker bygevoeg' : 'Gebruiker gewysig')),
                );
                // TODO: Backend integration for add/edit user
              },
              child: const Text('Stoor'),
            ),
          ],
        ),
      ),
    );
  }

  void _approveUser(int index) {
    setState(() {
      users[index]['aktief'] = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${users[index]['naam']} is goedgekeur')),
    );
    // TODO: Backend integration for approve
  }

  void _disableUser(int index) {
    setState(() {
      users[index]['aktief'] = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${users[index]['naam']} is gedeaktiveer')),
    );
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
              final userName = users[index]['naam'];
              setState(() {
                users.removeAt(index);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$userName is verwyder')),
              );
              // TODO: Backend integration for delete
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Verwyder', style: TextStyle(color: Colors.white)),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Gebruikers', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () => _showEditUserDialog(),
                icon: const Icon(Icons.person_add),
                label: const Text('Voeg Gebruiker By'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: users.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, i) {
                final user = users[i];
                return Card(
                  elevation: 2,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: user['rol'] == 'Superadmin' ? const Color(0xFFBF360C) : const Color(0xFFE64A19),
                      child: Icon(
                        user['rol'] == 'Superadmin' ? Icons.verified_user : Icons.person,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(user['naam'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      'E-pos: ${user['email']}\n'
                      'Rol: ${user['rol']}\n'
                      'Status: ${user['aktief'] ? 'Aktief' : 'Geblok'}\n'
                      'Laaste login: ${user['laasteLogin']}\n'
                      'Geregistreer: ${user['geregistreer']}'
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _showEditUserDialog(user: user, index: i);
                            break;
                          case 'toggle':
                            user['aktief'] ? _disableUser(i) : _approveUser(i);
                            break;
                          case 'delete':
                            _deleteUser(i);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
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
                        PopupMenuItem(
                          value: 'toggle',
                          child: Row(
                            children: [
                              Icon(user['aktief'] ? Icons.block : Icons.check_circle, size: 20),
                              const SizedBox(width: 8),
                              Text(user['aktief'] ? 'Deaktiveer' : 'Aktiveer'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Verwyder', style: TextStyle(color: Colors.red)),
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
          const Text('// TODO: Backend integration for user management', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
        ],
      ),
    );
  }
} 
