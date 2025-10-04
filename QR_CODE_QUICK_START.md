# QR Code Pickup - Quick Start Guide

## 🚀 Setup Instructions

### 1. Apply Database Migration

Run the migration to add the "Ontvang" (Received) status:

```bash
cd /Users/michaeldebeerhome/Capstone/Capstone
./scripts/apply_ontvang_status.sh
```

Or manually:
```bash
psql $SUPABASE_DB_URL -f db/migrations/0007_add_ontvang_status.sql
```

### 2. Install Dependencies

Dependencies have already been added to `pubspec.yaml`:
- `qr_flutter: ^4.1.0`
- `mobile_scanner: ^5.2.3`
- `crypto: ^3.0.3`

Run to ensure all packages are installed:
```bash
cd apps/mobile
flutter pub get
```

### 3. Configure Camera Permissions

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.CAMERA" />
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access to scan QR codes for food pickup</string>
```

### 4. Set Up Admin User

Ensure you have a tertiary admin user in the database:

```sql
-- 1. Get or create admin type
INSERT INTO public.admin_tipes (admin_tipe_naam) 
VALUES ('Tersiêr')
ON CONFLICT DO NOTHING;

-- 2. Assign admin type to a user
UPDATE public.gebruikers 
SET admin_tipe_id = (
  SELECT admin_tipe_id 
  FROM public.admin_tipes 
  WHERE admin_tipe_naam = 'Tersiêr'
)
WHERE gebr_epos = 'admin@example.com';  -- Replace with your admin email
```

## 📱 How to Use

### For Users (Students)

1. **Place an Order**
   - Browse menu and add items to cart
   - Complete checkout

2. **View QR Codes**
   - Go to **Bestellings** (Orders) page
   - Find your active order
   - Tap **"Wys QR Kode"** button
   - Each food item will have its own QR code

3. **Show QR at Pickup**
   - Go to pickup location
   - Show the QR code to the admin
   - Wait for confirmation

### For Admins (Tertiary)

1. **Access Scanner**
   - Go to **Instellings** (Settings) page
   - Look for **"Admin Gereedskap"** section
   - Tap **"Skandeer QR Kode"**

2. **Scan QR Codes**
   - Point camera at student's QR code
   - System automatically scans and validates
   - Success/error message appears
   - Item status updates to "Ontvang"

## 🔍 Testing the Feature

### Test as User
```dart
// 1. Login as regular user
// 2. Navigate to Orders page (/orders)
// 3. Create a test order if none exist
// 4. Click "Wys QR Kode" button
// 5. Verify QR codes display for each item
// 6. Check that codes refresh every 10 seconds
```

### Test as Admin
```dart
// 1. Login as tertiary admin user
// 2. Navigate to Settings page (/settings)
// 3. Verify "Admin Gereedskap" section appears
// 4. Click "Skandeer QR Kode"
// 5. Scan a user's QR code
// 6. Verify success message and database update
```

## 🔒 Security Features

✅ **HMAC Signature** - Prevents QR code tampering  
✅ **Time Expiration** - Codes expire after 10 minutes  
✅ **Permission Checking** - Only tertiary admins can scan  
✅ **Duplicate Prevention** - Can't scan same item twice  
✅ **Database Validation** - Verifies items exist  

## 📊 What Gets Updated

When a QR code is scanned:

1. **best_kos_item_statusse** table gets a new record:
   ```sql
   best_kos_id: <scanned_item_id>
   kos_stat_id: <ontvang_status_id>
   best_kos_wysig_datum: <current_timestamp>
   ```

2. **Item status** changes to "Ontvang"

3. **User's order view** updates to show item as collected

## 🛠️ Troubleshooting

### "QR Kode het verval" Error
**Solution:** QR codes expire after 10 minutes. User should refresh the QR page.

### "Geen Toestemming" (No Permission)
**Solution:** User is not a tertiary admin. Check admin_tipe_id in database.

### Camera Not Opening
**Solution:** 
- Check camera permissions in device settings
- Verify manifest/plist entries
- Restart the app

### "Item reeds afgehaal" (Already Collected)
**Solution:** This item was already scanned. This is expected behavior.

## 📁 Key Files

```
Mobile App:
├── lib/shared/models/qr_payload.dart          # QR data model
├── lib/shared/services/qr_service.dart        # Validation logic
├── lib/features/qr/presentation/pages/qr_page.dart      # User QR display
├── lib/features/scan/presentation/pages/scan_page.dart  # Admin scanner
└── lib/features/settings/presentation/pages/settings_page.dart  # Admin access

Database:
├── db/migrations/0007_add_ontvang_status.sql  # Migration file
└── scripts/apply_ontvang_status.sh            # Migration script
```

## 📚 Additional Documentation

For more detailed information, see:
- **QR_CODE_PICKUP_FEATURE.md** - Complete technical documentation
- **db/scheme.sql** - Database schema reference
- Code comments in implementation files

## ✅ Verification Checklist

- [ ] Database migration applied successfully
- [ ] Camera permissions configured
- [ ] At least one tertiary admin user exists
- [ ] Dependencies installed (`flutter pub get`)
- [ ] Can view QR codes as regular user
- [ ] Can scan QR codes as admin
- [ ] Status updates in database correctly

## 🎉 You're Ready!

The QR code pickup system is now fully implemented and ready for use. Users can display QR codes for their orders, and tertiary admins can scan them to mark items as collected.

---
**Need Help?** Check the detailed documentation in `QR_CODE_PICKUP_FEATURE.md`

