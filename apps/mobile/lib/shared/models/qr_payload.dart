import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Model for QR code payload used for food item pickup
class QrPayload {
  final String bestKosId;
  final String bestId;
  final String kosItemId;
  final DateTime timestamp;
  final String signature;

  QrPayload({
    required this.bestKosId,
    required this.bestId,
    required this.kosItemId,
    required this.timestamp,
    required this.signature,
  });

  /// Creates a QR payload with automatic signature generation
  factory QrPayload.create({
    required String bestKosId,
    required String bestId,
    required String kosItemId,
    String? secret,
  }) {
    final timestamp = DateTime.now();
    final signature = _generateSignature(
      bestKosId: bestKosId,
      bestId: bestId,
      kosItemId: kosItemId,
      timestamp: timestamp,
      secret: secret ?? _defaultSecret,
    );

    return QrPayload(
      bestKosId: bestKosId,
      bestId: bestId,
      kosItemId: kosItemId,
      timestamp: timestamp,
      signature: signature,
    );
  }

  /// Convert to JSON for encoding in QR code
  Map<String, dynamic> toJson() {
    return {
      'best_kos_id': bestKosId,
      'best_id': bestId,
      'kos_item_id': kosItemId,
      'timestamp': timestamp.toIso8601String(),
      'signature': signature,
    };
  }

  /// Create from JSON when scanning QR code
  factory QrPayload.fromJson(Map<String, dynamic> json) {
    return QrPayload(
      bestKosId: json['best_kos_id'] as String,
      bestId: json['best_id'] as String,
      kosItemId: json['kos_item_id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String? ?? DateTime.now().toIso8601String()),
      signature: json['signature'] as String,
    );
  }

  /// Convert to JSON string for QR code
  String toQrString() {
    return jsonEncode(toJson());
  }

  /// Parse from QR code string
  static QrPayload fromQrString(String qrString) {
    try {
      final json = jsonDecode(qrString) as Map<String, dynamic>;
      return QrPayload.fromJson(json);
    } catch (e) {
      throw FormatException('Invalid QR code format: $e');
    }
  }

  /// Validate the signature of the QR code
  bool isValidSignature({String? secret}) {
    final expectedSignature = _generateSignature(
      bestKosId: bestKosId,
      bestId: bestId,
      kosItemId: kosItemId,
      timestamp: timestamp,
      secret: secret ?? _defaultSecret,
    );
    return signature == expectedSignature;
  }

  /// Check if the QR code has expired (10 minutes window)
  bool isExpired({Duration expiryDuration = const Duration(minutes: 10)}) {
    final now = DateTime.now();
    final expiryTime = timestamp.add(expiryDuration);
    return now.isAfter(expiryTime);
  }

  /// Generate HMAC signature for the QR payload
  static String _generateSignature({
    required String bestKosId,
    required String bestId,
    required String kosItemId,
    required DateTime timestamp,
    required String secret,
  }) {
    final data = '$bestKosId:$bestId:$kosItemId:${timestamp.toIso8601String()}';
    final key = utf8.encode(secret);
    final bytes = utf8.encode(data);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);
    return digest.toString();
  }

  // Default secret - in production, this should be stored securely
  // and synced with the backend
  static const String _defaultSecret = 'spys_qr_secret_2024';
}

