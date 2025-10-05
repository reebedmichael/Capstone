import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/services/auth_service.dart';

class PasswordResetPage extends ConsumerStatefulWidget {
  const PasswordResetPage({super.key});

  @override
  ConsumerState<PasswordResetPage> createState() => _PasswordResetPageState();
}

class _PasswordResetPageState extends ConsumerState<PasswordResetPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isCheckingSession = true;

  @override
  void initState() {
    super.initState();
    _checkPasswordResetSession();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _checkPasswordResetSession() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user != null) {
        // User is authenticated, they can proceed with password reset
        if (mounted) {
          setState(() {
            _isCheckingSession = false;
          });
        }
        return;
      }

      // If no authenticated user, redirect to login
      if (mounted) {
        setState(() {
          _isCheckingSession = false;
        });
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          context.go('/auth/login');
        }
      }
    } catch (e) {
      // Redirect to login on error
      if (mounted) {
        setState(() {
          _isCheckingSession = false;
        });
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          context.go('/auth/login');
        }
      }
    }
  }

  Future<void> _handlePasswordUpdate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Validate passwords match
    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wagwoorde stem nie ooreen nie'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate password strength
    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wagwoord moet ten minste 8 karakters wees'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = AuthService();
      final response = await authService.updatePassword(password: password);

      if (response.user != null) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wagwoord suksesvol verander!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to home page
        if (mounted) {
          context.go('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout met wagwoord verandering: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingSession) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Kontroleer sessie...',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wagwoord Herstel'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Text(
                'Stel jou nuwe wagwoord in',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Kies \'n sterk wagwoord vir jou rekening',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Password field
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nuwe Wagwoord',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Voer asseblief \'n wagwoord in';
                  }
                  if (value.length < 8) {
                    return 'Wagwoord moet ten minste 8 karakters wees';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Confirm password field
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Bevestig Wagwoord',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Bevestig asseblief jou wagwoord';
                  }
                  if (value != _passwordController.text) {
                    return 'Wagwoorde stem nie ooreen nie';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              
              // Update password button
              ElevatedButton(
                onPressed: _isLoading ? null : _handlePasswordUpdate,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Verander Wagwoord'),
              ),
              const SizedBox(height: 16),
              
              // Back to login link
              TextButton(
                onPressed: () => context.go('/auth/login'),
                child: const Text('Terug na Teken In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
