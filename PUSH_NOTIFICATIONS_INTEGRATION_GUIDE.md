# 🚀 Push Notifications - Complete Integration Guide

**Date**: October 16, 2025  
**Status**: ✅ Ready for Production Setup  
**Difficulty**: ⭐⭐⭐ (Medium - requires multiple services)

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Prerequisites](#prerequisites)
4. [Step-by-Step Setup](#step-by-step-setup)
5. [Testing & Verification](#testing--verification)
6. [Troubleshooting](#troubleshooting)
7. [Production Deployment](#production-deployment)

---

## Overview

This guide walks you through the complete setup of the automatic push notification system. The system is fully implemented and includes:

- ✅ **Flutter/Dart Client** - FCM integration, token management, local notifications
- ✅ **Database Schema** - FCM token storage and automatic cleanup
- ✅ **Supabase Edge Function** - Send notifications via Firebase Cloud Messaging V1 API
- ✅ **Database Triggers** - Automatically send push notifications when notifications are created
- ✅ **Realtime Subscriptions** - Instant in-app updates
- ✅ **Android Configuration** - Complete setup with permissions and channels
- ✅ **iOS Configuration** - Base setup ready (requires Xcode steps)

### What's Already Done

The code is **100% complete**. You just need to:
1. Set up Firebase project and download config files
2. Deploy the Edge Function with Firebase credentials
3. Apply database migrations
4. Configure database settings
5. Test!

---

## Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                     Admin Creates Notification                   │
│                  (via Admin Web or API Client)                   │
└─────────────────────────┬──────────────────────────────────────┘
                          │
                          ▼
              ┌───────────────────────┐
              │   Supabase Database   │
              │                       │
              │  INSERT INTO          │
              │  kennisgewings        │
              └───────┬───────┬───────┘
                      │       │
        ┌─────────────┘       └─────────────┐
        │                                    │
        ▼                                    ▼
┌───────────────┐                  ┌─────────────────┐
│   Database    │                  │    Realtime     │
│   Trigger     │                  │    Channel      │
│   (Auto)      │                  │  (Instant UI)   │
└───────┬───────┘                  └────────┬────────┘
        │                                   │
        │ Check if user                     │ App open?
        │ has FCM token                     │ Update instantly
        │                                   │
        ▼                                   ▼
┌──────────────────┐              ┌─────────────────┐
│  Supabase Edge   │              │  Mobile App UI  │
│    Function      │              │   (In-app)      │
│  send-push-      │              └─────────────────┘
│  notification    │
└────────┬─────────┘
         │
         │ Call FCM V1 API
         │ with OAuth2
         │
         ▼
┌──────────────────┐
│  Firebase Cloud  │
│   Messaging      │
│   (FCM)          │
└────────┬─────────┘
         │
         │ Deliver to device
         │
         ▼
┌──────────────────┐
│   User Device    │
│  (Push Notif)    │
│  Even when app   │
│  is closed!      │
└──────────────────┘
```

### Flow Explanation

1. **Admin creates notification** - Inserts row into `kennisgewings` table
2. **Database trigger fires** - Automatically calls Edge Function (if user has FCM token)
3. **Edge Function calls Firebase** - Uses FCM V1 API with OAuth2 authentication
4. **Firebase delivers to device** - Push notification appears even if app is closed
5. **Realtime updates UI** - If app is open, UI updates instantly via Supabase Realtime
6. **User taps notification** - App opens and navigates to notification details

---

## Prerequisites

Before starting, ensure you have:

- ✅ Firebase account (free tier is fine)
- ✅ Supabase project (already set up)
- ✅ Supabase CLI installed (`brew install supabase/tap/supabase`)
- ✅ PostgreSQL client (`psql`) installed
- ✅ Flutter SDK (3.8.1+)
- ✅ Physical Android or iOS device (push notifications don't work on emulators)
- ✅ macOS with Xcode (for iOS configuration)

---

## Step-by-Step Setup

### Phase 1: Firebase Configuration (15 minutes)

#### 1.1 Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"**
3. Enter project name: `spys-mobile` (or your preferred name)
4. Disable Google Analytics (optional for now)
5. Click **"Create project"**
6. Wait for project creation (~30 seconds)

#### 1.2 Add Android App to Firebase

1. In Firebase Console, click the Android icon (Add Android app)
2. **Android package name**: `com.reebedmichael.capstone_mobile`
   - ⚠️ This must match exactly what's in `apps/mobile/android/app/build.gradle.kts`
3. **App nickname**: `Spys Mobile Android` (optional)
4. **Debug signing certificate SHA-1**: Leave blank for now
5. Click **"Register app"**
6. **Download `google-services.json`**
7. **Place file in**: `apps/mobile/android/app/google-services.json`
8. Click **"Next"** → **"Next"** → **"Continue to console"**

#### 1.3 Add iOS App to Firebase

1. In Firebase Console, click the iOS icon (Add iOS app)
2. **iOS bundle ID**: Open `apps/mobile/ios/Runner.xcodeproj/project.pbxproj` and find `PRODUCT_BUNDLE_IDENTIFIER`
   - Usually: `com.reebedmichael.capstoneMobile`
3. **App nickname**: `Spys Mobile iOS` (optional)
4. Click **"Register app"**
5. **Download `GoogleService-Info.plist`**
6. **Save file** (we'll add it to Xcode in Phase 3)
7. Click **"Next"** → **"Next"** → **"Continue to console"**

#### 1.4 Get Firebase Service Account Key

1. In Firebase Console, go to **Project Settings** (⚙️ gear icon)
2. Go to **"Service accounts"** tab
3. Click **"Generate new private key"**
4. Click **"Generate key"** in the confirmation dialog
5. A JSON file will download (e.g., `spys-mobile-firebase-adminsdk-xxxxx.json`)
6. **Keep this file safe!** You'll need it in Phase 2

---

### Phase 2: Supabase Edge Function Setup (5 minutes)

#### 2.1 Link Supabase Project (if not already linked)

```bash
cd /Users/michaeldebeer/Projects/capstone
supabase link --project-ref YOUR_PROJECT_REF
```

Get your project ref from: Supabase Dashboard → Project Settings → General → Reference ID

#### 2.2 Set Firebase Service Account Secret

```bash
# Set the entire JSON file as a secret
supabase secrets set FIREBASE_SERVICE_ACCOUNT="$(cat path/to/your-firebase-adminsdk-xxxxx.json)"
```

⚠️ **Important**: Replace `path/to/your-firebase-adminsdk-xxxxx.json` with the actual path to your downloaded JSON file.

Verify it was set:
```bash
supabase secrets list
# Should show: FIREBASE_SERVICE_ACCOUNT
```

#### 2.3 Deploy the Edge Function

```bash
supabase functions deploy send-push-notification
```

You should see:
```
Deploying send-push-notification...
✅ Deployed successfully
```

#### 2.4 Test the Edge Function

```bash
# Get a test user ID from your database
psql "$SUPABASE_DB_URL" -c "SELECT gebr_id FROM gebruikers LIMIT 1;"

# Test the function (replace YOUR_PROJECT and YOUR_SERVICE_ROLE_KEY)
curl -X POST 'https://YOUR_PROJECT.supabase.co/functions/v1/send-push-notification' \
  --header 'Authorization: Bearer YOUR_SERVICE_ROLE_KEY' \
  --header 'Content-Type: application/json' \
  --data '{
    "user_ids": ["user-uuid-here"],
    "title": "Test Notification",
    "body": "Testing Edge Function"
  }'
```

Expected response:
```json
{
  "success": true,
  "message": "Sent 0 notifications, 0 failed",
  "sent": 0,
  "failed": 0,
  "total": 0
}
```

(It's okay if it says 0 sent - this means no FCM tokens are registered yet. We'll fix that in Phase 4.)

---

### Phase 3: iOS Xcode Configuration (10 minutes)

⚠️ **Required for iOS push notifications**. Skip if you're only targeting Android.

#### 3.1 Add GoogleService-Info.plist to Xcode

1. Open Xcode:
   ```bash
   open /Users/michaeldebeer/Projects/capstone/apps/mobile/ios/Runner.xcworkspace
   ```

2. In Xcode's left sidebar, right-click on **"Runner"** folder
3. Select **"Add Files to Runner..."**
4. Navigate to and select the `GoogleService-Info.plist` file you downloaded
5. ✅ Check **"Copy items if needed"**
6. ✅ Ensure **"Runner"** target is checked
7. Click **"Add"**

#### 3.2 Enable Push Notifications Capability

1. In Xcode, select **"Runner"** project (blue icon at top of sidebar)
2. Select **"Runner"** target (under TARGETS)
3. Go to **"Signing & Capabilities"** tab
4. Click **"+ Capability"** button
5. Add **"Push Notifications"**
6. Add **"Background Modes"**
   - ✅ Check **"Remote notifications"**

#### 3.3 Configure Apple Push Notification service (APNs)

For production iOS push notifications, you need APNs certificates:

1. Go to [Apple Developer Portal](https://developer.apple.com/account/)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Select **"Keys"** → Click **"+"** to create new key
4. Name it: `Spys Mobile APNs Key`
5. ✅ Check **"Apple Push Notifications service (APNs)"**
6. Click **"Continue"** → **"Register"**
7. Download the `.p8` key file
8. **Note the Key ID** (you'll need this)

Upload to Firebase:
1. Firebase Console → Project Settings → Cloud Messaging → iOS
2. Upload your APNs Auth Key `.p8` file
3. Enter Key ID and Team ID
4. Click **"Upload"**

---

### Phase 4: Database Setup (10 minutes)

#### 4.1 Set Database Connection String

```bash
export SUPABASE_DB_URL='postgresql://postgres:[YOUR_PASSWORD]@db.[YOUR_PROJECT].supabase.co:5432/postgres'
```

Get this from: Supabase Dashboard → Project Settings → Database → Connection string (Direct connection)

⚠️ Replace `[YOUR_PASSWORD]` and `[YOUR_PROJECT]` with your actual values.

#### 4.2 Apply FCM Token Migration

```bash
cd /Users/michaeldebeer/Projects/capstone
./scripts/apply_fcm_tokens.sh
```

This creates the `fcm_token` column in the `gebruikers` table.

#### 4.3 Apply Push Notification Trigger Migration

```bash
./scripts/apply_push_notification_trigger.sh
```

This creates the automatic trigger that sends push notifications when notifications are created.

#### 4.4 Configure Database Settings (CRITICAL!)

```bash
# Get your values from Supabase Dashboard
# Project Settings → API

# Set Supabase URL
psql "$SUPABASE_DB_URL" -c "ALTER DATABASE postgres SET app.settings.supabase_url = 'https://YOUR_PROJECT.supabase.co';"

# Set Service Role Key (NOT the anon key!)
psql "$SUPABASE_DB_URL" -c "ALTER DATABASE postgres SET app.settings.service_role_key = 'YOUR_SERVICE_ROLE_KEY';"
```

⚠️ **Replace**:
- `YOUR_PROJECT` with your actual Supabase project reference
- `YOUR_SERVICE_ROLE_KEY` with your actual service_role key (keep it secret!)

Verify settings:
```bash
psql "$SUPABASE_DB_URL" -c "SHOW app.settings.supabase_url;"
psql "$SUPABASE_DB_URL" -c "SHOW app.settings.service_role_key;"
```

Both should return your configured values (not empty).

---

### Phase 5: Mobile App Testing (15 minutes)

#### 5.1 Clean and Rebuild the App

```bash
cd /Users/michaeldebeer/Projects/capstone/apps/mobile
flutter clean
flutter pub get
```

#### 5.2 Build and Run on Physical Device

⚠️ **Important**: Push notifications only work on physical devices, not emulators!

**For Android:**
```bash
# Connect Android device via USB (enable USB debugging)
flutter devices  # Verify device is connected
flutter run --release
```

**For iOS:**
```bash
# Connect iPhone via USB
flutter devices  # Verify device is connected
flutter build ios --release
# Then deploy via Xcode to your physical device
```

#### 5.3 Grant Notification Permissions

1. App should launch and show login screen
2. Log in with a test user
3. App will request notification permissions - **Allow/Grant**
4. Watch the console logs

You should see:
```
✅ Gebruiker het notifikasie toestemmings gegee
📱 FCM Token: [long-token-string]
✅ FCM token gestoor in databasis
✅ Notifikasie service geïnitialiseer (lokale + FCM + Realtime)
```

#### 5.4 Verify FCM Token is Stored

```bash
# Check if FCM token was stored (use your user's UUID)
psql "$SUPABASE_DB_URL" -c "SELECT gebr_id, fcm_token FROM gebruikers WHERE gebr_id = 'your-user-uuid';"
```

You should see your user ID with a non-null `fcm_token` value.

---

## Testing & Verification

### Test 1: Manual Push Notification via Edge Function

Test the Edge Function directly:

```bash
curl -X POST 'https://YOUR_PROJECT.supabase.co/functions/v1/send-push-notification' \
  --header 'Authorization: Bearer YOUR_SERVICE_ROLE_KEY' \
  --header 'Content-Type: application/json' \
  --data '{
    "user_ids": ["your-user-uuid"],
    "title": "Test Push Notification",
    "body": "This is a manual test from the Edge Function!",
    "data": {
      "notification_id": "test-123",
      "type": "test"
    }
  }'
```

Expected result:
- ✅ Your device receives a push notification
- ✅ Response: `{"success":true,"sent":1,...}`

### Test 2: Automatic Push via Database Trigger

This is the main feature! Test the automatic trigger:

```bash
# Get your user UUID
psql "$SUPABASE_DB_URL" -c "SELECT gebr_id FROM gebruikers WHERE gebr_epos = 'your-email@example.com';"

# Insert a test notification
psql "$SUPABASE_DB_URL" -c "
INSERT INTO public.kennisgewings (gebr_id, kennis_beskrywing, kennis_titel)
VALUES ('your-user-uuid', 'This notification was sent automatically via database trigger!', 'Auto Test');
"
```

Expected result:
- ✅ Your device receives a push notification **automatically**
- ✅ No manual API call needed!
- ✅ The trigger handled everything

Check the logs:
```bash
supabase functions logs send-push-notification --limit 10
```

### Test 3: Push Notification When App is Closed

The ultimate test:

1. **Close the app completely** (swipe away from recent apps)
2. Insert a notification:
   ```bash
   psql "$SUPABASE_DB_URL" -c "
   INSERT INTO public.kennisgewings (gebr_id, kennis_beskrywing, kennis_titel)
   VALUES ('your-user-uuid', 'Testing background delivery!', 'Background Test');
   "
   ```
3. Wait a few seconds
4. ✅ Push notification should appear on lock screen
5. **Tap the notification**
6. ✅ App should open to the notification details

### Test 4: Realtime Update When App is Open

1. Keep the app **open** and on the notifications screen
2. Insert a notification:
   ```bash
   psql "$SUPABASE_DB_URL" -c "
   INSERT INTO public.kennisgewings (gebr_id, kennis_beskrywing, kennis_titel)
   VALUES ('your-user-uuid', 'Testing realtime update!', 'Realtime Test');
   "
   ```
3. ✅ Notification should appear **instantly** in the app UI
4. ✅ Push notification also shown locally

---

## Troubleshooting

### Problem: "Firebase nie geïnitialiseer nie"

**Cause**: Firebase config files not in correct location

**Solution**:
- Verify `google-services.json` is in `apps/mobile/android/app/`
- Verify `GoogleService-Info.plist` is added to Xcode Runner target
- Run `flutter clean && flutter pub get`
- Rebuild app

### Problem: No FCM Token Generated

**Cause**: Firebase not initialized or permissions denied

**Solution**:
```bash
# Check logs when app starts
flutter logs | grep -i fcm

# Look for:
# ✅ "FCM Token: ..."  → Success!
# ❌ "Firebase nie geïnitialiseer" → Config missing
# ❌ "Gebruiker het notifikasie toestemmings geweier" → Permissions denied
```

If permissions denied:
- Android: Settings → Apps → Spys Mobile → Notifications → Allow
- iOS: Settings → Spys Mobile → Notifications → Allow

### Problem: Push Notifications Not Received

**Check 1: User has FCM token**
```sql
SELECT gebr_id, fcm_token FROM gebruikers WHERE gebr_id = 'your-user-uuid';
```
If NULL → User needs to log in to register device

**Check 2: Database settings configured**
```sql
SHOW app.settings.supabase_url;
SHOW app.settings.service_role_key;
```
If empty → Run Phase 4.4 again

**Check 3: Edge Function logs**
```bash
supabase functions logs send-push-notification --limit 20
```
Look for errors

**Check 4: Firebase Service Account**
```bash
supabase secrets list
# Should show: FIREBASE_SERVICE_ACCOUNT
```
If missing → Run Phase 2.2 again

### Problem: Trigger Not Firing

**Check if trigger exists**:
```sql
SELECT trigger_name, event_manipulation, event_object_table 
FROM information_schema.triggers 
WHERE trigger_name = 'on_kennisgewings_insert_send_push';
```

Should return 1 row. If not:
```bash
./scripts/apply_push_notification_trigger.sh
```

### Problem: iOS Push Notifications Not Working

**Check APNs configuration**:
- Firebase Console → Project Settings → Cloud Messaging → iOS
- Ensure APNs Auth Key is uploaded
- Key ID and Team ID are correct

**Check Xcode capabilities**:
- Push Notifications capability enabled ✅
- Background Modes → Remote notifications ✅

### Problem: "FIREBASE_SERVICE_ACCOUNT not configured"

**Solution**:
```bash
# Re-upload the service account JSON
supabase secrets set FIREBASE_SERVICE_ACCOUNT="$(cat path/to/firebase-adminsdk.json)"

# Redeploy function
supabase functions deploy send-push-notification
```

---

## Production Deployment

### Checklist Before Going Live

- [ ] Firebase project created for production
- [ ] Production `google-services.json` and `GoogleService-Info.plist` added
- [ ] Firebase Service Account JSON uploaded to Supabase secrets
- [ ] Edge Function deployed to production Supabase project
- [ ] Database migrations applied to production database
- [ ] Database settings configured with production values
- [ ] APNs certificates configured for iOS production
- [ ] Tested push notifications on production devices
- [ ] Custom notification icons added (optional)
- [ ] Notification categories configured (optional)

### Security Best Practices

1. **Never commit secrets**:
   - ❌ Don't commit `google-services.json`
   - ❌ Don't commit `GoogleService-Info.plist`
   - ❌ Don't commit Firebase service account JSON
   - ❌ Don't commit service_role keys

2. **Use environment-specific Firebase projects**:
   - Development: `spys-mobile-dev`
   - Production: `spys-mobile-prod`

3. **Rotate service_role keys** periodically

4. **Monitor Edge Function logs** for unauthorized access attempts

5. **Rate limit** the Edge Function in production (Supabase Dashboard)

### Monitoring & Analytics

Track notification effectiveness:

```sql
-- Count notifications sent per day
SELECT 
  DATE(kennis_geskep_datum) as date,
  COUNT(*) as total_notifications
FROM kennisgewings
GROUP BY DATE(kennis_geskep_datum)
ORDER BY date DESC;

-- Check notification read rates
SELECT 
  COUNT(*) as total,
  COUNT(*) FILTER (WHERE kennis_gelees = true) as read,
  ROUND(100.0 * COUNT(*) FILTER (WHERE kennis_gelees = true) / COUNT(*), 2) as read_percentage
FROM kennisgewings
WHERE kennis_geskep_datum >= NOW() - INTERVAL '7 days';
```

Check Edge Function usage:
```bash
supabase functions logs send-push-notification --limit 100
```

---

## Summary

### What You've Accomplished

✅ **Complete push notification system** with:
- Automatic sending via database triggers
- Firebase Cloud Messaging V1 API integration
- Supabase Realtime for instant in-app updates
- Android & iOS support
- Background notification delivery
- Notification tap handling
- FCM token management

### System Capabilities

- 📱 **Push notifications** when app is closed
- ⚡ **Instant updates** when app is open (Realtime)
- 🔔 **Local notifications** for in-app display
- 🎯 **Target specific users** or broadcast to all
- 📊 **Track read status** and analytics
- 🔄 **Automatic token refresh** and cleanup
- 🛡️ **Secure** with RLS policies and service role authentication

### Next Steps

1. **Customize notification appearance** (icons, sounds, colors)
2. **Add notification categories** (orders, announcements, allowances)
3. **Implement deep linking** for better navigation
4. **Add notification actions** (quick reply, mark as read)
5. **Set up analytics** to track engagement

---

**Questions or Issues?**

Check these resources:
- `PUSH_NOTIFICATIONS_SETUP.md` - Detailed setup guide
- `supabase/functions/send-push-notification/README.md` - Edge Function docs
- `PUSH_NOTIFICATIONS_STATUS.md` - Implementation status
- [Firebase Documentation](https://firebase.google.com/docs/cloud-messaging)
- [Supabase Documentation](https://supabase.com/docs)

---

**Last Updated**: October 16, 2025  
**Version**: 2.0.0  
**Status**: 🟢 Production Ready

