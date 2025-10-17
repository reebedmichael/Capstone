# 🧪 Test Your Automatic Notifications

**Branch**: `notifications-updates`  
**Status**: ✅ Ready to Test!

---

## ✅ What's Deployed

- ✅ Database triggers applied
- ✅ New APK built (79.8MB)
- ✅ Dependencies installed
- ✅ Everything ready!

---

## 🧪 Quick Tests (Do These Now!)

### Test 1: Order Status Change Notification 🛍️

**Using Admin Panel or SQL:**

```sql
-- Find a test order item
SELECT best_kos_id, best_nommer, gebr_id 
FROM bestelling_kos_item 
LIMIT 1;

-- Get status IDs
SELECT kos_stat_id, kos_stat_naam FROM kos_item_statusse;

-- Insert new status (this triggers notification!)
INSERT INTO best_kos_item_statusse (best_kos_id, kos_stat_id)
VALUES ('best_kos_id_from_above', 'status_id_for_Wag_vir_afhaal');
```

**Expected Result**:
- ✅ User receives push notification: "Jou bestelling #{number} is gereed vir afhaal! 🎉"
- ✅ Check Edge Function logs to see it was sent
- ✅ Notification appears in app

---

### Test 2: Wallet Top-Up Notification 💳

```sql
-- Get transaction type ID for wallet top-up
SELECT trans_tipe_id, trans_tipe_naam FROM transaksie_tipe;

-- Add R50 to Frits's wallet (or any user with FCM token)
INSERT INTO beursie_transaksie (gebr_id, trans_bedrag, trans_tipe_id, trans_beskrywing)
VALUES (
    '1bf61c67-ae1e-4fb9-aeac-a62cbac5ac48', -- Frits
    50.00,
    'wallet-top-up-type-id', -- Use actual ID from query above
    'Test wallet top-up'
);
```

**Expected Result**:
- ✅ User receives push notification: "Jou beursie is opggelaai met R50.00! 💳"
- ✅ Balance updated in database
- ✅ Transaction appears in wallet history

---

### Test 3: Allowance Notification 🎁

```sql
-- Get allowance transaction type ID
SELECT trans_tipe_id FROM transaksie_tipe WHERE trans_tipe_naam = 'toelae_inbetaling';

-- Add R100 allowance to Frits
INSERT INTO beursie_transaksie (gebr_id, trans_bedrag, trans_tipe_id, trans_beskrywing)
VALUES (
    '1bf61c67-ae1e-4fb9-aeac-a62cbac5ac48', -- Frits
    100.00,
    'a1e58a24-1a1d-4940-8855-df4c35ae5d5f', -- toelae_inbetaling
    'Maandelikse toelae'
);
```

**Expected Result**:
- ✅ User receives push notification: "Jy het R100.00 toelae ontvang! 💰"
- ✅ Balance updated
- ✅ Different icon/color for allowance vs wallet

---

### Test 4: User Approval Notification ✅

```sql
-- Find an inactive user
SELECT gebr_id, gebr_naam, is_aktief FROM gebruikers WHERE is_aktief = false LIMIT 1;

-- Approve the user (activate account)
UPDATE gebruikers 
SET is_aktief = true 
WHERE gebr_id = 'inactive-user-id';
```

**Expected Result**:
- ✅ User receives push notification: "Welkom {name}! Jou rekening is goedgekeur..."
- ✅ User can now log in
- ✅ Account is active

---

### Test 5: Custom Notification 📢

```sql
-- Send custom notification to Frits
SELECT send_custom_notification(
    '1bf61c67-ae1e-4fb9-aeac-a62cbac5ac48',
    'Spesiale Aanbieding!',
    'Kry 20% afslag op jou volgende bestelling vandag!',
    'promo'
);
```

**Expected Result**:
- ✅ User receives push notification with custom message
- ✅ Function returns success JSON
- ✅ Can be used by admins for promotional messages

---

## 📱 Test New Notification Settings Page

### On the Mobile App:

1. **Install the new APK** on your test device:
   - Copy `build/app/outputs/flutter-apk/app-release.apk` to your device
   - Install it

2. **Open the app and navigate**:
   - Go to **Settings** (Instellings)
   - Tap **"Kennisgewing Instellings"** (should be first in Kennisgewings section)

3. **You should see**:
   - ✅ Notification permission status card
   - ✅ Push notification registration status
   - ✅ "Konfigueer Toestel Kennisgewings" button
   - ✅ 5 category toggles (Orders, Wallet, Allowance, Approval, General)
   - ✅ Beautiful UI with icons for each category

4. **Test the features**:
   - Toggle a category (should show snackbar feedback)
   - Tap "Konfigueer Toestel Kennisgewings" (should open phone settings)
   - Check that preferences are saved (close and reopen page)

---

## 🔍 Verify Everything Works

### Check Edge Function Logs:

After each test, check:
- Supabase Dashboard → Edge Functions → send-push-notification → Logs

You should see successful deliveries!

### Check Database:

```sql
-- Check notifications were created
SELECT kennis_titel, kennis_beskrywing, kennis_gelees
FROM kennisgewings
ORDER BY kennis_geskep_datum DESC
LIMIT 10;

-- Check which users have FCM tokens
SELECT gebr_naam, fcm_token IS NOT NULL as has_token
FROM gebruikers
ORDER BY gebr_naam;
```

---

## 🎯 Success Criteria

Your notification system is working if:

- ✅ Database triggers fire when events occur
- ✅ Notifications are created in kennisgewings table
- ✅ Push notifications are sent via Edge Function
- ✅ Users receive push notifications on their devices
- ✅ Edge Function logs show successful deliveries
- ✅ Notification Settings page loads and works
- ✅ Category preferences are saved and persisted

---

## 🚀 Production Deployment

Once all tests pass:

1. **Merge to Development**:
   ```bash
   git checkout Development
   git merge notifications-updates
   git push origin Development
   ```

2. **Distribute APK to users**

3. **Monitor Edge Function logs** for the first few days

4. **Collect user feedback** on notification preferences

---

## 📊 Expected Impact

### Users Will Receive Notifications For:

- 📦 **Order Updates**: 5 different statuses
- 💳 **Wallet Changes**: Top-ups, deductions  
- 🎁 **Allowances**: Monthly and manual
- ✅ **Account**: Approvals and activations
- 📢 **Custom**: Admin announcements

### Users Can Control:

- ✅ Enable/disable notifications
- ✅ Per-category preferences
- ✅ Access phone settings
- ✅ View FCM registration status

---

**Ready to test?** Start with Test 1 (Order Status) and work through the list! 🎉

**Questions?** Check `AUTOMATIC_NOTIFICATIONS_IMPLEMENTATION.md` for detailed help.

