import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:math';

class QrPage extends StatefulWidget {
  final Map<String, dynamic>? order;
  const QrPage({super.key, this.order});

  @override
  State<QrPage> createState() => _QrPageState();
}

class _QrPageState extends State<QrPage> {
  bool isScanned = false;
  String timeRemaining = '';
  Timer? _timer;
  late List<List<bool>> qrPattern;
  late String qrCode;

  @override
  void initState() {
    super.initState();
    if (widget.order != null) {
      qrCode = "ORDER-${widget.order!['id']}";
      qrPattern = _generateQRPattern(qrCode);
      _startCountdown();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  List<List<bool>> _generateQRPattern(String code) {
    const size = 15;
    final pattern = List.generate(size, (_) => List<bool>.filled(size, false));
    for (int i = 0; i < size; i++) {
      for (int j = 0; j < size; j++) {
        final index = (i * size + j) % code.length;
        final charCode = code.codeUnitAt(index);
        pattern[i][j] = charCode % 2 == 0;
      }
    }
    return pattern;
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final orderTime = widget.order!['orderDate'] as DateTime;
      final pickupEnd = orderTime.add(const Duration(hours: 5));
      final now = DateTime.now();

      if (now.isAfter(pickupEnd)) {
        setState(() => timeRemaining = 'Afhaalvenster verstreke');
      } else {
        final diff = pickupEnd.difference(now);
        final hours = diff.inHours;
        final minutes = diff.inMinutes % 60;
        setState(() {
          timeRemaining = hours > 0
              ? '${hours}u ${minutes}m oor'
              : '${minutes}m oor';
        });
      }
    });
  }

  void _simulateScan() {
    setState(() => isScanned = true);

    // Update the order status locally and return it to the caller
    if (widget.order != null) {
      widget.order!['status'] = 'Afgehaal';
      // you can also add a timestamp or other fields if desired:
      widget.order!['orderDate'] = DateTime.now();
    }

    Fluttertoast.showToast(msg: 'Bestelling suksesvol afgehaal!');

    // wait a moment so user sees the success UI, then pop with the updated order
    Future.delayed(const Duration(seconds: 1), () {
      Navigator.pop(context, widget.order);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.order == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.qr_code, size: 64, color: Colors.grey),
              const SizedBox(height: 12),
              const Text(
                'Geen bestelling gekies',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text("Kies 'n bestelling om die QR kode te sien"),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Terug na Bestellings'),
              ),
            ],
          ),
        ),
      );
    }

    if (isScanned) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(FeatherIcons.arrowLeft),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Afgehaal'),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.green.shade100,
                child: const Icon(
                  FeatherIcons.checkCircle,
                  size: 48,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Bestelling Afgehaal!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Jou bestelling #${widget.order!['id']} is suksesvol afgehaal.\nGeniet jou ete!',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(FeatherIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('QR Kode'),
        // actions: [
        //   IconButton(icon: const Icon(FeatherIcons.copy), onPressed: _copyQR),
        // ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
            child: ListTile(
              leading: const Icon(FeatherIcons.clock),
              title: Text('Status: ${widget.order!['status']}'),
              subtitle: Text('Afhaalvenster: $timeRemaining'),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Wys hierdie QR kode',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Wys hierdie kode by die afhaalpunt om jou bestelling te kry',
                  ),
                  const SizedBox(height: 16),
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: qrPattern
                          .map(
                            (row) => Row(
                              mainAxisSize: MainAxisSize.min,
                              children: row
                                  .map(
                                    (cell) => Container(
                                      width: 10,
                                      height: 10,
                                      color: cell ? Colors.black : Colors.white,
                                    ),
                                  )
                                  .toList(),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    qrCode,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              title: const Text('Bestelling Besonderhede'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bestelling #: ${widget.order!['id']}'),
                  Text('Totaal: R${widget.order!['total']}'),
                  Text('Afhaal lokasie: ${widget.order!['pickupLocation']}'),
                  Text(
                    'Gereed vir afhaal Tyd: ${(widget.order!['orderDate'] as DateTime).hour.toString().padLeft(2, '0')}:${(widget.order!['orderDate'] as DateTime).minute.toString().padLeft(2, '0')}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Items Bestel',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ...(widget.order!['items'] as List).map((item) {
                    final food = item['foodItem'];
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${item['quantity']}x ${food['name']}'),
                        Text(
                          'R${(item['quantity'] * food['price']).toStringAsFixed(2)}',
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(FeatherIcons.mapPin),
              title: const Text('Instruksies'),
              subtitle: const Text(
                '1. Gaan na die afhaallokasie\n2. Wys hierdie QR kode\n3. Wag vir bevestiging\n4. Geniet jou ete!',
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _simulateScan,
            icon: const Icon(FeatherIcons.checkCircle),
            label: const Text('Simuleer Afhaal'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
