import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../shared/models/qr_payload.dart';

class QrPage extends StatefulWidget {
  final Map<String, dynamic>? order;
  const QrPage({super.key, this.order});

  @override
  State<QrPage> createState() => _QrPageState();
}

class _QrPageState extends State<QrPage> {
  Timer? _refreshTimer;
  int _refreshCountdown = 10;
  Map<String, QrPayload> _qrPayloads = {};

  @override
  void initState() {
    super.initState();
    if (widget.order != null) {
      _generateQrPayloads();
      _startRefreshTimer();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _generateQrPayloads() {
    final items = widget.order!['bestelling_kos_item'] as List? ?? [];
    final Map<String, QrPayload> payloads = {};

    for (final item in items) {
      final bestKosId = item['best_kos_id']?.toString();
      if (bestKosId != null) {
        payloads[bestKosId] = QrPayload.create(
          bestKosId: bestKosId,
          bestId: widget.order!['best_id']?.toString() ?? '',
          kosItemId: item['kos_item_id']?.toString() ?? '',
        );
      }
    }

    setState(() {
      _qrPayloads = payloads;
    });
  }

  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      setState(() {
        _refreshCountdown--;
        if (_refreshCountdown <= 0) {
          _refreshCountdown = 10;
          _generateQrPayloads();
        }
      });
    });
  }

  String _getItemStatus(Map<String, dynamic> item) {
    final statuses = (item['best_kos_item_statusse'] as List? ?? []);
    if (statuses.isEmpty) return 'Wag vir afhaal';

    final lastStatus = statuses.last;
    final statusInfo =
        lastStatus['kos_item_statusse'] as Map<String, dynamic>? ?? {};
    return statusInfo['kos_stat_naam'] as String? ?? 'Wag vir afhaal';
  }

  bool _canShowQr(String status) {
    // Only show QR for items that are waiting or in preparation
    return status != 'Afgehandel' &&
        status != 'Gekanselleer' &&
        status != 'Ontvang';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('QR Kode')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.qr_code, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
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

    final items = widget.order!['bestelling_kos_item'] as List? ?? [];
    final kampus = widget.order!['kampus'] as Map<String, dynamic>?;
    final kampusName = kampus?['kampus_naam'] as String? ?? 'Onbekende lokasie';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(FeatherIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('QR Kodes vir Afhaal'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Order info card
          Card(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(FeatherIcons.info, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Bestelling Besonderhede',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(FeatherIcons.mapPin, size: 16),
                      const SizedBox(width: 6),
                      Text('Afhaal lokasie: $kampusName'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(FeatherIcons.dollarSign, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Totaal: R${widget.order!['best_volledige_prys']?.toStringAsFixed(2) ?? '0.00'}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Refresh info
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    FeatherIcons.refreshCw,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'QR kodes verfris outomaties elke 10 sekondes vir sekuriteit',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_refreshCountdown}s',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Items with QR codes
          ...items.map((item) {
            final food = item['kos_item'] as Map<String, dynamic>? ?? {};
            final itemName =
                food['kos_item_naam'] as String? ?? 'Onbekende item';
            final itemPrice = food['kos_item_koste'] as num? ?? 0.0;
            final itemQty = item['item_hoev'] as int? ?? 1;
            final itemImage = food['kos_item_prentjie'] as String?;
            final bestKosId = item['best_kos_id']?.toString();
            final status = _getItemStatus(item);
            final canShowQr = _canShowQr(status);

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item header
                    Row(
                      children: [
                        if (itemImage != null && itemImage.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              itemImage,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 60,
                                height: 60,
                                color: Theme.of(context).colorScheme.surfaceVariant,
                                child: const Icon(Icons.fastfood),
                              ),
                            ),
                          )
                        else
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.fastfood, size: 30),
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                itemName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$itemQty x R${itemPrice.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor(status),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // QR Code or status message
                    if (canShowQr &&
                        bestKosId != null &&
                        _qrPayloads.containsKey(bestKosId))
                      Center(
                        child: Column(
                          children: [
                            const Text(
                              'Wys hierdie QR kode by afhaal',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Theme.of(context).colorScheme.outline),
                              ),
                              child: QrImageView(
                                data: _qrPayloads[bestKosId]!.toQrString(),
                                version: QrVersions.auto,
                                size: 200,
                                backgroundColor: Theme.of(context).colorScheme.surface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Item ID: ${bestKosId.substring(0, 8)}...',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Icon(
                                status == 'Afgehandel' || status == 'Ontvang'
                                    ? FeatherIcons.checkCircle
                                    : FeatherIcons.xCircle,
                                size: 48,
                                color:
                                    status == 'Afgehandel' ||
                                        status == 'Ontvang'
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                status == 'Afgehandel' || status == 'Ontvang'
                                    ? 'Item reeds afgehaal'
                                    : 'Nie beskikbaar vir afhaal nie',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 16),

          // Instructions card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(FeatherIcons.helpCircle, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Instruksies',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInstruction('1', 'Gaan na die afhaallokasie'),
                  _buildInstruction('2', 'Wys die QR kode vir jou item'),
                  _buildInstruction(
                    '3',
                    'Wag vir die admin om dit te skandeer',
                  ),
                  _buildInstruction('4', 'Geniet jou ete!'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstruction(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface))),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Wag vir afhaal':
        return Theme.of(context).colorScheme.errorContainer;
      case 'In voorbereiding':
        return Theme.of(context).colorScheme.primaryContainer;
      case 'Afgehandel':
      case 'Ontvang':
        return Theme.of(context).colorScheme.tertiaryContainer;
      case 'Gekanselleer':
        return Theme.of(context).colorScheme.errorContainer;
      default:
        return Theme.of(context).colorScheme.surfaceVariant;
    }
  }
}
