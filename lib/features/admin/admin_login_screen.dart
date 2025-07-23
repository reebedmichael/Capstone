import 'package:flutter/material.dart';
import '../../core/constants.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Login'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Superadmin approval status (mock)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified_user, color: Color(0xFFE64A19), size: 20),
                        SizedBox(width: 8),
                        Text('Superadmin approval: Pending (mock)', style: TextStyle(color: Color(0xFFE64A19), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const Text('Admin Login', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppConstants.paddingLarge),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'E-pos',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Wagwoord',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _mockLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingMedium),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Teken in'),
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingSmall),
                  TextButton(
                    onPressed: () {
                      // TODO: Forgot password
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Wagwoord herstel (mock)')),
                      );
                    },
                    child: const Text('Wagwoord vergeet?'),
                  ),
                  const SizedBox(height: AppConstants.paddingSmall),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AdminRegisterScreen()),
                      );
                    },
                    child: const Text('Nog nie geregistreer nie? Registreer as admin'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _mockLogin() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);
    Navigator.pushReplacementNamed(context, '/admin');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Welkom, admin! (mock)'), backgroundColor: AppConstants.successColor),
    );
  }
}

class AdminRegisterScreen extends StatelessWidget {
  const AdminRegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Register'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Superadmin approval status (mock)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified_user, color: Color(0xFFE64A19), size: 20),
                        SizedBox(width: 8),
                        Text('Superadmin approval: Pending (mock)', style: TextStyle(color: Color(0xFFE64A19), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const Text('Admin Register', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppConstants.paddingLarge),
                  const TextField(
                    decoration: InputDecoration(
                      labelText: 'E-pos',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  const TextField(
                    decoration: InputDecoration(
                      labelText: 'Wagwoord',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  const TextField(
                    decoration: InputDecoration(
                      labelText: 'Bevestig wagwoord',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Admin geregistreer (mock)!'), backgroundColor: AppConstants.successColor),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingMedium),
                      ),
                      child: const Text('Registreer'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 
