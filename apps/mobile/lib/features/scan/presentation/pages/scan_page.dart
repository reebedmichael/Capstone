import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/services/qr_service.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> with WidgetsBindingObserver {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  
  bool _isProcessing = false;
  bool _hasPermission = true;
  String? _lastScannedCode;
  late QrService _qrService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _qrService = QrService(Supabase.instance.client);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes
    if (!_scannerController.value.isInitialized) {
      return;
    }

    switch (state) {
      case AppLifecycleState.resumed:
        _scannerController.start();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _scannerController.stop();
        break;
    }
  }

  Future<void> _checkPermissions() async {
    // Check if user is a tertiary admin
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() => _hasPermission = false);
      return;
    }

    final isAdmin = await _qrService.isTertiaryAdmin(user.id);
    setState(() => _hasPermission = isAdmin);

    if (!isAdmin) {
      Future.delayed(Duration.zero, () {
        if (mounted) {
          Fluttertoast.showToast(
            msg: 'Jy het nie toestemming om QR kodes te skandeer nie',
            backgroundColor: Theme.of(context).colorScheme.error,
          );
        }
      });
    }
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    final String? code = barcode.rawValue;

    if (code == null || code == _lastScannedCode) return;

    setState(() {
      _isProcessing = true;
      _lastScannedCode = code;
    });

    try {
      // Process the QR code
      final result = await _qrService.processScannedQr(code);

      if (!mounted) return;

      if (result['success'] == true) {
        // Show success dialog
        _showResultDialog(
          success: true,
          title: 'Bestelling Afgehandel',
          message: result['message'] as String? ?? 'Bestelling suksesvol afgehandel',
          icon: FeatherIcons.checkCircle,
          iconColor: Theme.of(context).colorScheme.tertiary,
        );
      } else {
        // Show error dialog
        final isAlreadyCollected = result['alreadyCollected'] == true;
        _showResultDialog(
          success: false,
          title: isAlreadyCollected ? 'Reeds Afgehaal' : 'Fout',
          message: result['message'] as String? ?? 'Kon nie QR kode verwerk nie',
          icon: isAlreadyCollected ? FeatherIcons.info : FeatherIcons.xCircle,
          iconColor: isAlreadyCollected ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.error,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showResultDialog(
        success: false,
        title: 'Fout',
        message: 'Kon nie QR kode verwerk nie: $e',
        icon: FeatherIcons.xCircle,
        iconColor: Theme.of(context).colorScheme.error,
      );
    } finally {
      // Allow scanning again after a delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _lastScannedCode = null;
          });
        }
      });
    }
  }

  void _showResultDialog({
    required bool success,
    required String title,
    required String message,
    required IconData icon,
    required Color iconColor,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPermission) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/settings'),
          ),
          title: Text(
            'Skandeer QR Kode',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  FeatherIcons.alertCircle,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Geen Toestemming',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Slegs Tersiêr Admins kan QR kodes skandeer. Kontak jou stelsel administrateur as jy glo dit is \'n fout.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Terug'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/settings'),
        ),
        title: Text(
          'Skandeer QR Kode',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_scannerController.torchEnabled
                ? FeatherIcons.zap
                : FeatherIcons.zapOff),
            onPressed: () => _scannerController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(FeatherIcons.rotateCw),
            onPressed: () => _scannerController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Scanner view
          MobileScanner(
            controller: _scannerController,
            onDetect: _handleBarcode,
            errorBuilder: (context, error) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        FeatherIcons.camera,
                        size: 64,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Kamera Fout: $error',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Scanning overlay
          if (!_isProcessing)
            Center(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    // Corner decorations
                    Positioned(
                      top: 0,
                      left: 0,
                      child: _buildCorner(0),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: _buildCorner(90),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: _buildCorner(180),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: _buildCorner(270),
                    ),
                  ],
                ),
              ),
            ),

          // Instructions overlay
          if (!_isProcessing)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      FeatherIcons.alignCenter,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Rig die QR kode binne die raam',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Die skandering sal outomaties gebeur',
                      style: TextStyle(
                        color: Colors.grey.shade300,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

          // Processing overlay
          if (_isProcessing)
            Container(
              color: Colors.black87,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Verwerk QR kode...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCorner(double rotation) {
    return Transform.rotate(
      angle: rotation * 3.14159 / 180,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Theme.of(context).colorScheme.primary, width: 5),
            left: BorderSide(color: Theme.of(context).colorScheme.primary, width: 5),
          ),
        ),
      ),
    );
  }
}
