# 📱 Push Notifications Setup Guide

This guide will walk you through setting up push notifications for the Spys mobile app using Firebase Cloud Messaging (FCM) and Supabase.

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Firebase Setup](#firebase-setup)
4. [Android Configuration](#android-configuration)
5. [iOS Configuration](#ios-configuration)
6. [Database Migration](#database-migration)
7. [Supabase Edge Function Setup](#supabase-edge-function-setup)
8. [Testing](#testing)
9. [Troubleshooting](#troubleshooting)

## Overview

The push notification system consists of three main components:

1. **Firebase Cloud Messaging (FCM)**: Delivers push notifications to devices
2. **Supabase Realtime**: Provides instant in-app notification updates
3. **Supabase Edge Function**: Sends push notifications via FCM API

### Architecture

```
Admin/System → Supabase DB → Edge Function → FCM → User Device
                    ↓
              Realtime Channel → In-App Notification
```

## Prerequisites

- Firebase account (free)
- Supabase project with CLI installed
- Flutter SDK installed
- Physical Android/iOS device (push notifications don't work on emulators)

## Firebase Setup

### Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"**
3. Enter project name: `spys-mobile` (or your preferred name)
4. Disable Google Analytics (optional)
5. Click **"Create project"**

### Step 2: Add Android App

1. In Firebase Console, click **"Add app"** → Android icon
2. Enter Android package name: `com.reebedmichael.capstone_mobile`
   - Find this in `apps/mobile/android/app/build.gradle.kts` under `applicationId`
3. Enter app nickname: `Spys Mobile Android` (optional)
4. Skip SHA-1 certificate for now (needed later for release)
5. Click **"Register app"**
6. Download `google-services.json`
7. Place it in: `apps/mobile/android/app/google-services.json`
8. Click **"Next"** through remaining steps

### Step 3: Add iOS App

1. In Firebase Console, click **"Add app"** → iOS icon
2. Enter iOS bundle ID: Get from `apps/mobile/ios/Runner.xcodeproj/project.pbxproj`
   - Look for `PRODUCT_BUNDLE_IDENTIFIER`
   - Usually something like `com.reebedmichael.capstoneMobile`
3. Enter app nickname: `Spys Mobile iOS` (optional)
4. Skip App Store ID for now
5. Click **"Register app"**
6. Download `GoogleService-Info.plist`
7. Place it in: `apps/mobile/ios/Runner/GoogleService-Info.plist`
8. Click **"Next"** through remaining steps

### Step 4: Get Firebase Server Key

1. In Firebase Console, go to **Project Settings** (gear icon)
2. Go to **"Cloud Messaging"** tab
3. Scroll to **"Cloud Messaging API (Legacy)"**
4. Copy the **"Server key"** - you'll need this for Supabase Edge Function

## Android Configuration

The Android configuration has already been done! Here's what was set up:

### ✅ Gradle Configuration

- `google-services` plugin added to `settings.gradle.kts`
- Plugin applied in `app/build.gradle.kts`

### ✅ AndroidManifest.xml

Permissions and metadata added for:
- Push notifications
- Internet access
- Notification channel configuration

### Verify Setup

1. Ensure `google-services.json` is in `apps/mobile/android/app/`
2. Run:
   ```bash
   cd apps/mobile
   flutter pub get
   flutter build apk --debug
   ```

## iOS Configuration

### Step 1: Add GoogleService-Info.plist

1. Open Xcode: `open apps/mobile/ios/Runner.xcworkspace`
2. Right-click on `Runner` folder in Xcode
3. Select **"Add Files to Runner"**
4. Select `GoogleService-Info.plist`
5. ✅ Check **"Copy items if needed"**
6. ✅ Check **"Runner" target**
7. Click **"Add"**

### Step 2: Enable Push Notifications Capability

1. In Xcode, select **Runner** project
2. Select **Runner** target
3. Go to **"Signing & Capabilities"** tab
4. Click **"+ Capability"**
5. Add **"Push Notifications"**
6. Add **"Background Modes"**
   - ✅ Check "Remote notifications"

### Step 3: Update Info.plist

The Info.plist already has camera permissions. No additional changes needed.

### Step 4: Configure APNs (Apple Push Notification service)

1. Go to [Apple Developer Portal](https://developer.apple.com/account/)
2. Go to **Certificates, Identifiers & Profiles**
3. Select your App ID
4. Enable **Push Notifications**
5. Create APNs certificates:
   - Development certificate (for testing)
   - Production certificate (for release)
6. Upload certificates to Firebase:
   - Firebase Console → Project Settings → Cloud Messaging → iOS
   - Upload APNs Authentication Key or Certificate

### Verify Setup

```bash
cd apps/mobile
flutter pub get
flutter build ios --debug
```

## Database Migration

Add FCM token storage to the database:

### Step 1: Set Database URL

```bash
export SUPABASE_DB_URL='postgresql://postgres:[password]@[host]:[port]/postgres'
```

Get this from Supabase Dashboard → Project Settings → Database → Connection string

### Step 2: Run Migration

```bash
cd /path/to/Capstone
./scripts/apply_fcm_tokens.sh
```

Or manually:
```bash
psql "$SUPABASE_DB_URL" -f db/migrations/0010_add_fcm_tokens.sql
```

### What This Does

- Adds `fcm_token` column to `gebruikers` table
- Creates index for fast token lookups
- Adds cleanup function for old tokens

## Supabase Edge Function Setup

### Step 1: Install Supabase CLI

```bash
# macOS
brew install supabase/tap/supabase

# Or download from https://github.com/supabase/cli
```

### Step 2: Link Project

```bash
cd /path/to/Capstone
supabase link --project-ref your-project-ref
```

### Step 3: Set Firebase Server Key

```bash
supabase secrets set FIREBASE_SERVER_KEY="your-firebase-server-key"
```

Replace with the Server Key from Firebase Console → Cloud Messaging

### Step 4: Deploy Function

```bash
supabase functions deploy send-push-notification
```

### Step 5: Test Function

```bash
curl -i --location --request POST 'https://your-project.supabase.co/functions/v1/send-push-notification' \
  --header 'Authorization: Bearer YOUR_ANON_KEY' \
  --header 'Content-Type: application/json' \
  --data '{
    "user_ids": ["test-user-id"],
    "title": "Test Notification",
    "body": "This is a test push notification"
  }'
```

## Testing

### Test 1: Local Notifications (No Firebase Required)

This tests the notification display without Firebase:

1. Run the app:
   ```bash
   cd apps/mobile
   flutter run
   ```

2. Log in with a test user
3. The app should request notification permissions
4. Grant permissions

### Test 2: Supabase Realtime (No Firebase Required)

This tests instant in-app notifications:

1. Run the app and log in
2. From admin panel or database, create a new notification:
   ```sql
   INSERT INTO public.kennisgewings (gebr_id, kennis_beskrywing, kennis_titel)
   VALUES ('user-id-here', 'Test realtime notification', 'Test');
   ```
3. The notification should appear immediately in the app

### Test 3: Firebase Push Notifications (Requires Firebase Setup)

This tests true push notifications when app is closed:

1. Complete Firebase setup (steps above)
2. Build and install app on physical device:
   ```bash
   # Android
   flutter run --release
   
   # iOS
   flutter build ios --release
   # Then install via Xcode
   ```

3. Log in and grant notification permissions
4. Check logs for FCM token:
   ```
   📱 FCM Token: [long-token-string]
   ✅ FCM token gestoor in databasis
   ```

5. Close the app completely (swipe away)
6. Send test notification using Edge Function:
   ```bash
   curl -X POST 'https://your-project.supabase.co/functions/v1/send-push-notification' \
     --header 'Authorization: Bearer YOUR_ANON_KEY' \
     --header 'Content-Type: application/json' \
     --data '{
       "user_ids": ["your-user-id"],
       "title": "Test Push",
       "body": "Testing push notifications!"
     }'
   ```

7. Device should receive push notification even when app is closed!

### Test 4: End-to-End Test

1. From admin web panel, send a notification to a user
2. User should receive:
   - Push notification on device (even if app is closed)
   - Realtime update in app (if app is open)
   - Database entry in kennisgewings table

## Troubleshooting

### No FCM Token Generated

**Problem**: Console shows "Firebase nie geïnitialiseer nie"

**Solutions**:
- Verify `google-services.json` / `GoogleService-Info.plist` are in correct locations
- Run `flutter clean && flutter pub get`
- Rebuild app: `flutter run`
- Check Firebase project is properly configured

### Notifications Not Received on Android

**Solutions**:
- Ensure testing on physical device (not emulator)
- Check app has notification permissions: Settings → Apps → Capstone Mobile → Notifications
- Verify `google-services.json` is in `apps/mobile/android/app/`
- Check FCM token is saved in database
- Test with different notification priorities

### Notifications Not Received on iOS

**Solutions**:
- Ensure testing on physical device (not simulator)
- Check APNs certificates are uploaded to Firebase
- Verify Push Notifications capability is enabled in Xcode
- Check app has notification permissions in iOS Settings
- Ensure app is signed with proper provisioning profile

### Edge Function Errors

**Problem**: `FIREBASE_SERVER_KEY not configured`

**Solution**:
```bash
supabase secrets set FIREBASE_SERVER_KEY="your-key-here"
supabase functions deploy send-push-notification
```

**Problem**: `Error sending push notification`

**Solutions**:
- Check Firebase Server Key is correct
- Verify FCM tokens in database are valid
- Check Supabase function logs: `supabase functions logs send-push-notification`

### Database Issues

**Problem**: `column fcm_token does not exist`

**Solution**:
```bash
./scripts/apply_fcm_tokens.sh
```

**Problem**: `permission denied`

**Solution**:
- Check RLS policies allow users to update their own fcm_token
- Verify service_role key is used for admin operations

## Advanced Configuration

### Automatic Push on Notification Creation

Create a database trigger to automatically send push notifications:

```sql
CREATE OR REPLACE FUNCTION trigger_push_notification()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM net.http_post(
    url := 'https://your-project.supabase.co/functions/v1/send-push-notification',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || current_setting('app.supabase_service_role_key')
    ),
    body := jsonb_build_object(
      'user_ids', ARRAY[NEW.gebr_id],
      'title', COALESCE(NEW.kennis_titel, 'Nuwe Kennisgewing'),
      'body', NEW.kennis_beskrywing
    )
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_kennisgewings_insert
AFTER INSERT ON public.kennisgewings
FOR EACH ROW
EXECUTE FUNCTION trigger_push_notification();
```

### Custom Notification Sounds

Add custom sounds to:
- Android: `android/app/src/main/res/raw/notification_sound.mp3`
- iOS: `ios/Runner/notification_sound.aiff`

Update `NotificationService.dart`:
```dart
const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
  'spys_notifications',
  'Spys Notifikasies',
  sound: RawResourceAndroidNotificationSound('notification_sound'),
  // ...
);
```

### Notification Categories

Add different notification channels for different types:
- Orders: High priority, with sound
- Announcements: Default priority
- Allowance: Low priority, no sound

## Next Steps

1. ✅ Complete Firebase project setup
2. ✅ Add configuration files to Android/iOS
3. ✅ Run database migration
4. ✅ Deploy Edge Function
5. ✅ Test on physical devices
6. Configure APNs for iOS production
7. Add notification categories and icons
8. Implement notification action buttons
9. Add analytics for notification engagement

## Support

For issues or questions:
- Check [Firebase Documentation](https://firebase.google.com/docs/cloud-messaging)
- Check [Supabase Documentation](https://supabase.com/docs)
- Review Flutter logs: `flutter logs`
- Check Supabase function logs: `supabase functions logs send-push-notification`

---

**Status**: 🟢 Core implementation complete. Ready for Firebase project setup and testing.

**Last Updated**: October 15, 2025

