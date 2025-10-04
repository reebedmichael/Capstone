# QR Code Pickup Feature Documentation

## Overview
This document describes the QR code-based food item pickup system implemented for the Spys project. The system allows users to display unique QR codes for each ordered food item, which tertiary admins can scan to mark items as collected.

## Architecture

### Components

1. **QR Code Generation** (`qr_payload.dart`, `qr_service.dart`)
   - Generates unique, time-limited QR codes for each food item
   - Includes HMAC signature for security
   - Auto-expires after 10 minutes

2. **User QR Display** (`qr_page.dart`)
   - Shows QR codes for all items in an order
   - Auto-refreshes codes every 10 seconds for security
   - Displays item details and status

3. **Admin Scanner** (`scan_page.dart`)
   - Camera-based QR code scanner
   - Real-time validation and processing
   - Admin permission checking

4. **Backend Integration** (`qr_service.dart`)
   - Database validation
   - Status updates
   - Duplicate scan prevention

## Database Schema

### New Status
A new status `'Ontvang'` (Received) has been added to `kos_item_statusse` table to track picked-up items.

### Status Flow
1. **Wag vir afhaal** (Waiting for pickup) - Initial state
2. **In voorbereiding** (In preparation) - Food being prepared
3. **Ontvang** (Received) - ✅ Scanned via QR code
4. **Afgehandel** (Completed) - Final state
5. **Gekanselleer** (Cancelled) - Cancelled by user

## Security Features

### 1. HMAC Signature
Each QR code includes an HMAC-SHA256 signature that prevents tampering:
```dart
signature = HMAC(SHA256, secret_key, "best_kos_id:best_id:kos_item_id:timestamp")
```

### 2. Time-Limited QR Codes
- QR codes expire after 10 minutes
- Auto-refresh every 10 seconds
- Prevents replay attacks

### 3. Permission Checking
- Only users with `admin_tipe_id` linked to "Tersiêr" admin type can scan
- Permission checked on both frontend and backend

### 4. Duplicate Prevention
- System checks if item was already collected
- Shows appropriate error message

## QR Code Payload Structure

```json
{
  "best_kos_id": "<uuid>",      // Unique food item order ID
  "best_id": "<uuid>",           // Parent order ID
  "kos_item_id": "<uuid>",       // Food item template ID
  "timestamp": "<ISO8601>",      // Generation timestamp
  "signature": "<hmac_sha256>"   // Security signature
}
```

## User Flow

### For Regular Users
1. Navigate to **Bestellings** (Orders)
2. Click **"Wys QR Kode"** (Show QR Code) on an active order
3. Display the QR code for each food item to the admin
4. Wait for admin to scan and confirm pickup

### For Tertiary Admins
1. Navigate to **Instellings** (Settings)
2. Click **"Skandeer QR Kode"** (Scan QR Code) in Admin Tools section
3. Point camera at user's QR code
4. System automatically validates and processes the scan
5. Success or error dialog is displayed

## API Integration

### Key Methods

#### `QrService.generateQrPayload()`
```dart
QrPayload generateQrPayload({
  required String bestKosId,
  required String bestId,
  required String kosItemId,
})
```

#### `QrService.processScannedQr()`
```dart
Future<Map<String, dynamic>> processScannedQr(String qrString)
```

Returns:
```dart
{
  'success': bool,
  'message': String,
  'itemName': String?,      // Only on success
  'alreadyCollected': bool? // Only on duplicate scan
}
```

#### `QrService.isTertiaryAdmin()`
```dart
Future<bool> isTertiaryAdmin(String userId)
```

## Database Migration

Run the migration to add the "Ontvang" status:

```bash
cd /Users/michaeldebeerhome/Capstone/Capstone
./scripts/apply_ontvang_status.sh
```

Or manually with psql:
```bash
psql $SUPABASE_DB_URL -f db/migrations/0007_add_ontvang_status.sql
```

## Dependencies Added

```yaml
dependencies:
  qr_flutter: ^4.1.0          # QR code generation
  mobile_scanner: ^5.2.3      # QR code scanning
  crypto: ^3.0.3              # HMAC signatures
```

## File Structure

```
apps/mobile/lib/
├── shared/
│   ├── models/
│   │   └── qr_payload.dart           # QR code data model
│   └── services/
│       └── qr_service.dart           # QR validation & processing
├── features/
│   ├── qr/
│   │   └── presentation/
│   │       └── pages/
│   │           └── qr_page.dart      # User QR display
│   └── scan/
│       └── presentation/
│           └── pages/
│               └── scan_page.dart     # Admin scanner
└── core/
    └── routes/
        └── app_router.dart            # Navigation routes

db/
└── migrations/
    └── 0007_add_ontvang_status.sql    # Database migration

scripts/
└── apply_ontvang_status.sh            # Migration script
```

## Testing Checklist

### User Side
- [ ] Can view orders with active items
- [ ] QR codes display correctly for each item
- [ ] QR codes refresh every 10 seconds
- [ ] Cannot see QR for completed/cancelled items
- [ ] Item status badges display correctly

### Admin Side
- [ ] Only tertiary admins see scanner option
- [ ] Scanner opens camera successfully
- [ ] Can scan valid QR codes
- [ ] Invalid/expired codes show error
- [ ] Already collected items show warning
- [ ] Status updates in database

### Security
- [ ] QR codes expire after 10 minutes
- [ ] Signature validation works
- [ ] Cannot forge QR codes
- [ ] Duplicate scans prevented

## Troubleshooting

### Camera Permission Issues
On Android, add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA" />
```

On iOS, add to `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access to scan QR codes</string>
```

### Admin Not Seeing Scanner Option
1. Check user's `admin_tipe_id` in database
2. Verify admin_tipes table has "Tersiêr" or "Tersier" entry
3. Check QrService.isTertiaryAdmin() logic

### QR Code Not Scanning
1. Ensure good lighting
2. Hold phone steady
3. Check if QR code has expired (regenerate)
4. Verify QR payload JSON is valid

## Future Enhancements

1. **Analytics Dashboard**
   - Track pickup times
   - Popular items
   - Peak hours

2. **Notifications**
   - Notify user when item is ready
   - Notify admin of pending pickups

3. **Batch Scanning**
   - Scan multiple items from one order at once

4. **Offline Mode**
   - Queue scans when offline
   - Sync when connection restored

5. **Enhanced Security**
   - Rotate secret keys periodically
   - Add geolocation validation
   - Implement rate limiting

## Support

For issues or questions:
1. Check this documentation
2. Review code comments
3. Check database schema in `db/scheme.sql`
4. Contact system administrator

---
**Last Updated:** October 3, 2024
**Version:** 1.0.0
**Author:** AI Assistant

