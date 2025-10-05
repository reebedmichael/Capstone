import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SimpleOtpDialog extends StatefulWidget {
  final String email;
  final VoidCallback onSuccess;
  final VoidCallback onCancel;

  const SimpleOtpDialog({
    super.key,
    required this.email,
    required this.onSuccess,
    required this.onCancel,
  });

  @override
  State<SimpleOtpDialog> createState() => _SimpleOtpDialogState();
}

class _SimpleOtpDialogState extends State<SimpleOtpDialog> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Voer OTP Kode In'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Voer die 6-syfer kode in wat na ${widget.email} gestuur is:'),
          const SizedBox(height: 16),
          TextField(
            controller: _otpController,
            decoration: const InputDecoration(
              labelText: 'OTP Kode',
              border: OutlineInputBorder(),
              hintText: '123456',
            ),
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () {
            Navigator.of(context).pop();
            widget.onCancel();
          },
          child: const Text('Kanselleer'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _verifyOtp,
          child: _isLoading
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
    if (_otpController.text.trim().length != 6) {
      _showMessage('Voer \'n 6-syfer kode in', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.auth.verifyOTP(
        type: OtpType.recovery,
        token: _otpController.text.trim(),
        email: widget.email,
      );

      if (response.user != null) {
        _showMessage('OTP suksesvol verifieer!', Colors.green);
        Navigator.of(context).pop();
        widget.onSuccess();
      } else {
        _showMessage('OTP verifikasie het gefaal', Colors.red);
      }
    } catch (e) {
      _showMessage('Ongeldige OTP kode. Probeer weer.', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
