import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

class OtpVerificationDialog extends StatefulWidget {
  final String email;
  final VoidCallback onSuccess;
  final VoidCallback onCancel;
  final VoidCallback onLogout;

  const OtpVerificationDialog({
    super.key,
    required this.email,
    required this.onSuccess,
    required this.onCancel,
    required this.onLogout,
  });

  @override
  State<OtpVerificationDialog> createState() => _OtpVerificationDialogState();
}

class _OtpVerificationDialogState extends State<OtpVerificationDialog> {
  final TextEditingController _otpController = TextEditingController();
  bool _isVerifying = false;
  bool _isResending = false;
  int _failedAttempts = 0;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Verifieer OTP'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Voer die OTP kode in wat na ${widget.email} gestuur is:',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _otpController,
            decoration: const InputDecoration(
              labelText: 'OTP Kode',
              border: OutlineInputBorder(),
              hintText: 'Voer 6-syfer kode in',
            ),
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            autofocus: true,
            onChanged: (value) {
              if (value.length == 6 && !_isVerifying && !_isResending) {
                _verifyOtp();
              }
            },
          ),
          if (_failedAttempts > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Ongeldige kode. ${3 - _failedAttempts} pogings oor.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isVerifying || _isResending ? null : () {
            Navigator.of(context).pop();
            widget.onCancel();
          },
          child: const Text('Kanselleer'),
        ),
        TextButton(
          onPressed: _isResending ? null : _resendOtp,
          child: _isResending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Stuur Weer'),
        ),
        ElevatedButton(
          onPressed: _isVerifying || _isResending ? null : _verifyOtp,
          child: _isVerifying
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Verifieer'),
        ),
      ],
    );
  }

  void _verifyOtp() async {
    if (_otpController.text.trim().isEmpty) {
      _showSnackBar('Voer asseblief die OTP kode in', Colors.red);
      return;
    }

    if (_isVerifying || _isResending) return;

    setState(() {
      _isVerifying = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.auth.verifyOTP(
        type: OtpType.recovery,
        token: _otpController.text.trim(),
        email: widget.email,
      );

      if (response.user != null) {
        Navigator.of(context).pop();
        widget.onSuccess();
      }
    } catch (e) {
      setState(() {
        _failedAttempts++;
      });

      if (_failedAttempts >= 3) {
        Navigator.of(context).pop();
        widget.onLogout();
        return;
      }

      _showSnackBar('Ongeldige OTP kode. ${3 - _failedAttempts} pogings oor.', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  void _resendOtp() async {
    if (_isResending) return;

    setState(() {
      _isResending = true;
    });

    try {
      final authService = AuthService();
      await authService.resetPassword(email: widget.email);
      _showSnackBar('Nuwe OTP kode gestuur', Colors.green);
    } catch (e) {
      _showSnackBar('Fout met stuur van OTP: ${e.toString()}', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}