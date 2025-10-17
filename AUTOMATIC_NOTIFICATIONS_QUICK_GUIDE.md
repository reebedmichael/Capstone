# 🚀 Automatic Notifications - Quick Reference

**Branch**: `notifications-updates`  
**Status**: ✅ Ready for Deployment

---

## ⚡ Quick Deploy (5 Minutes)

### 1. Apply Database Migration
```bash
export SUPABASE_DB_URL='your-connection-string'
./scripts/apply_automatic_notification_triggers.sh
```

### 2. Build New APK
```bash
cd apps/mobile
flutter pub get
flutter build apk --release
```

**Output**: `build/app/outputs/flutter-apk/app-release.apk`

---

## 🎯 What's New

### Automatic Notifications For:
- ✅ Order status changes (5 different statuses)
- ✅ Wallet transactions (top-ups, deductions)
- ✅ Allowance distribution (monthly/manual)
- ✅ User approval (account activation)

### New Mobile Features:
- ✅ Notification Settings page
- ✅ Per-category notification control
- ✅ Permission management
- ✅ Direct phone settings access

---

## 📱 User Guide

### Access Notification Settings:
1. Open app
2. Tap **Settings** (Instellings)
3. Tap **Kennisgewing Instellings**

### Features:
- View notification permission status
- See FCM token registration
- Enable/disable per category:
  - Orders 🛍️
  - Wallet 💳
  - Allowances 🎁
  - Approvals ✅
  - General ℹ️
- Open phone notification settings

---

## 🧪 Quick Test

### Test Order Notification:
```sql
-- Insert new order status
INSERT INTO best_kos_item_statusse (best_kos_id, kos_stat_id)
VALUES ('order-item-id', 'status-id');
```

### Test Wallet Notification:
```sql
-- Add funds to user wallet
INSERT INTO beursie_transaksie (gebr_id, trans_bedrag, trans_tipe_id)
VALUES ('user-id', 50.00, 'top-up-type-id');
```

### Test User Approval:
```sql
-- Approve user
UPDATE gebruikers SET is_aktief = true WHERE gebr_id = 'user-id';
```

### Test Custom Notification:
```sql
SELECT send_custom_notification(
    'user-id', 
    'Test Title', 
    'Test message',
    'info'
);
```

---

## 🔍 Quick Troubleshoot

### Check Triggers Exist:
```sql
SELECT trigger_name FROM information_schema.triggers 
WHERE trigger_name LIKE '%notify%';
```

### Check User FCM Token:
```sql
SELECT gebr_naam, fcm_token FROM gebruikers 
WHERE gebr_id = 'user-id';
```

### Check Edge Function Logs:
```bash
supabase functions logs send-push-notification --limit 10
```

---

## 📊 Notification Types

| Event | Type | Message Example |
|-------|------|-----------------|
| Order Ready | `order` | "Jou bestelling #123 is gereed vir afhaal! 🎉" |
| Wallet Top-up | `wallet` | "Jou beursie is opggelaai met R50.00! 💳" |
| Allowance | `allowance` | "Jy het R100.00 toelae ontvang! 💰" |
| Approval | `approval` | "Welkom! Jou rekening is geaktiveer 🎉" |

---

## 📁 Files Changed

**Database**:
- `db/migrations/0012_add_automatic_notification_triggers.sql` ✨ NEW
- `scripts/apply_automatic_notification_triggers.sh` ✨ NEW

**Mobile App**:
- `notification_settings_page.dart` ✨ NEW
- `app_router.dart` 🔄 UPDATED
- `settings_page.dart` 🔄 UPDATED
- `pubspec.yaml` 🔄 UPDATED (+2 packages)

**Documentation**:
- `AUTOMATIC_NOTIFICATIONS_IMPLEMENTATION.md` ✨ NEW
- `AUTOMATIC_NOTIFICATIONS_QUICK_GUIDE.md` ✨ NEW (this file)

---

## 🎉 That's It!

Your notification system is now **fully automatic** for all major events!

**Questions?** See `AUTOMATIC_NOTIFICATIONS_IMPLEMENTATION.md` for detailed guide.

**Ready to deploy?** Follow the Quick Deploy steps above! 🚀

