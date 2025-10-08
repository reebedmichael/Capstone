import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_providers.dart';
import 'otp_verification_dialog.dart';

class EmailInputDialog extends ConsumerStatefulWidget {
  const EmailInputDialog({super.key});

  @override
  ConsumerState<EmailInputDialog> createState() => _EmailInputDialogState();
}

class _EmailInputDialogState extends ConsumerState<EmailInputDialog> {
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  bool _isChecking = false;

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleEmailSubmit() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voer asseblief jou e-pos adres in'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Basic email validation
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voer asseblief \'n geldige e-pos adres in'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isChecking = true;
    });

    try {
      final authService = ref.read(authServiceProvider);

      // Check if user exists in database
      final userExists = await authService.userExistsByEmail(email: email);

      if (!userExists) {
        // User doesn't exist, show registration prompt
        if (mounted) {
          Navigator.of(context).pop(); // Close email dialog
          _showRegistrationPrompt(email);
        }
        return;
      }

      // User exists, proceed with password reset
      await _proceedWithPasswordReset(email);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout met verifikasie: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  Future<void> _proceedWithPasswordReset(String email) async {
    try {
      final authService = ref.read(authServiceProvider);

      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text("Stuur herstel e-pos..."),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      // Send password reset email
      await authService.resetPassword(email: email);

      // Hide loading snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Close email dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show OTP verification dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => OtpVerificationDialog(
            email: email,
            onSuccess: () {
              // Navigate to password reset page
              context.go('/wagwoord_herstel');
            },
            onCancel: () {
              // Just close the dialog and stay on login page
              Navigator.of(context).pop();
            },
            onLogout: () {
              // User was logged out due to too many failed attempts
              context.go('/teken_in');
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Fout met stuur van herstel e-pos: ${e.toString()}"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _showRegistrationPrompt(String email) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rekening Nie Gevind'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Die e-pos adres "$email" is nie geregistreer nie.'),
            const SizedBox(height: 16),
            const Text('Wil jy \'n nuwe admin rekening registreer?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kanselleer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/registreer_admin');
            },
            child: const Text('Registreer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_reset,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Wagwoord Herstel',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Voer jou e-pos adres in om te begin',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Email Input
            TextField(
              controller: _emailController,
              focusNode: _emailFocusNode,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'E-pos Adres',
                hintText: 'jou@epos.com',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                prefixIcon: const Icon(Icons.email),
              ),
              onSubmitted: (_) => _handleEmailSubmit(),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isChecking
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Kanselleer'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isChecking ? null : _handleEmailSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isChecking
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text('Stuur Herstel E-pos'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Help text
            Text(
              'Ons sal jou e-pos stuur met instruksies om jou wagwoord te herstel.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
