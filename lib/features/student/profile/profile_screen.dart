import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../core/utils/color_utils.dart';
import '../../../services/auth_service.dart';
import '../../../models/user.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  List<String> _selectedAllergies = [];
  final List<String> _availableAllergies = [
    'Neute', 'Gluten', 'Laktose', 'Soja', 'Eiers', 'Vis', 'Skaaldiere', 'Sesamsaad'
  ];

  @override
  void initState() {
    super.initState();
    final user = _authService.currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _selectedAllergies = List<String>.from(user?.allergies ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.userStream,
      builder: (context, snapshot) {
        // Always assign a non-null user
        final User user = snapshot.data ?? User(
          id: '1',
          name: 'Demo Student',
          email: 'demo@spys.com',
          phone: '+27 82 123 4567',
          userType: 'student',
          walletBalance: 1234.56,
          addresses: ['123 Demo Street, Demo City', '456 Example Ave, Test Town'],
          allergies: ['Gluten', 'Peanuts'],
          termsAccepted: true,
          isActive: true,
          lastLogin: DateTime.now(),
          profileImageUrl: 'https://randomuser.me/api/portraits/men/1.jpg',
        );
        return Scaffold(
          appBar: AppBar(
            title: const Text('Profiel'),
            backgroundColor: AppConstants.primaryColor,
            foregroundColor: Colors.white,
            actions: [
              if (!_isEditing)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Column(
              children: [
                // Profile Header
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingLarge),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: setOpacity(AppConstants.primaryColor, 0.1),
                          child: Icon(
                            Icons.person,
                            size: 50,
                            color: AppConstants.primaryColor,
                          ),
                        ),
                        const SizedBox(height: AppConstants.paddingMedium),
                        !_isEditing
                            ? Column(
                                children: [
                                  Text(
                                    user.name,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    user.userType,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  TextField(
                                    controller: _nameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Naam',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  const SizedBox(height: AppConstants.paddingSmall),
                                  TextField(
                                    controller: _phoneController,
                                    decoration: const InputDecoration(
                                      labelText: 'Foon',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.phone,
                                  ),
                                ],
                              ),
                        const SizedBox(height: AppConstants.paddingMedium),
                        !_isEditing
                            ? Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.email, size: 16, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(user.email, style: const TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                  const SizedBox(height: AppConstants.paddingSmall),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.phone, size: 16, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(user.phone, style: const TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  TextField(
                                    controller: _emailController,
                                    enabled: false,
                                    decoration: const InputDecoration(
                                      labelText: 'E-pos',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ],
                              ),
                        const SizedBox(height: AppConstants.paddingMedium),
                        // Allergies
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Allergieë:',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(height: AppConstants.paddingSmall),
                        !_isEditing
                            ? Wrap(
                                spacing: 8,
                                children: user.allergies.isEmpty
                                    ? [const Text('Geen')] 
                                    : user.allergies.map((a) => Chip(label: Text(a))).toList(),
                              )
                            : Wrap(
                                spacing: 8,
                                children: _availableAllergies.map((allergy) {
                                  final selected = _selectedAllergies.contains(allergy);
                                  return FilterChip(
                                    label: Text(allergy),
                                    selected: selected,
                                    onSelected: (val) {
                                      setState(() {
                                        if (val) {
                                          _selectedAllergies.add(allergy);
                                        } else {
                                          _selectedAllergies.remove(allergy);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                        const SizedBox(height: AppConstants.paddingMedium),
                        if (_isEditing)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: _saveProfile,
                                child: const Text('Stoor'),
                              ),
                              const SizedBox(width: AppConstants.paddingMedium),
                              OutlinedButton(
                                onPressed: () {
                                  setState(() {
                                    _isEditing = false;
                                    _nameController.text = user.name;
                                    _phoneController.text = user.phone;
                                    _selectedAllergies = List<String>.from(user.allergies);
                                  });
                                },
                                child: const Text('Kanselleer'),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.paddingLarge),
                // Change password
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.lock),
                    title: const Text('Verander wagwoord'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showChangePasswordDialog,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingLarge),
                // Logout
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.logout, color: AppConstants.errorColor),
                    title: const Text('Teken uit', style: TextStyle(color: AppConstants.errorColor)),
                    onTap: _showLogoutDialog,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _saveProfile() async {
    final user = _authService.currentUser;
    if (user == null) return;
    final updatedUser = user.copyWith(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      allergies: List<String>.from(_selectedAllergies),
    );
    await _authService.updateProfile(updatedUser);
    if (!mounted) return;
    setState(() {
      _isEditing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profiel gestoor!'), backgroundColor: AppConstants.successColor),
    );
  }

  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Verander wagwoord'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPasswordController,
                obscureText: obscureOld,
                decoration: InputDecoration(
                  labelText: 'Huidige wagwoord',
                  suffixIcon: IconButton(
                    icon: Icon(obscureOld ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => obscureOld = !obscureOld),
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.paddingSmall),
              TextField(
                controller: newPasswordController,
                obscureText: obscureNew,
                decoration: InputDecoration(
                  labelText: 'Nuwe wagwoord',
                  suffixIcon: IconButton(
                    icon: Icon(obscureNew ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => obscureNew = !obscureNew),
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.paddingSmall),
              TextField(
                controller: confirmPasswordController,
                obscureText: obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Bevestig wagwoord',
                  suffixIcon: IconButton(
                    icon: Icon(obscureConfirm ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => obscureConfirm = !obscureConfirm),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kanselleer'),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Backend integration for password change
                if (newPasswordController.text != confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Wagwoorde stem nie ooreen nie!'),
                      backgroundColor: AppConstants.errorColor,
                    ),
                  );
                  return;
                }
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Wagwoord verander (mock)!'),
                    backgroundColor: AppConstants.successColor,
                  ),
                );
              },
              child: const Text('Stoor'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Teken uit'),
        content: const Text('Is jy seker jy wil uitteken?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kanselleer'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _authService.logout();
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Teken uit'),
          ),
        ],
      ),
    );
  }
} 