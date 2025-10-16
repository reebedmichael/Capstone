# 🚀 Push Notifications Quick Start

**TL;DR**: 5-minute guide to get push notifications working.

## 📋 Checklist

### 1. Firebase Setup (5 min)
- [ ] Create Firebase project at [console.firebase.google.com](https://console.firebase.google.com/)
- [ ] Add Android app → Download `google-services.json` → Place in `apps/mobile/android/app/`
- [ ] Add iOS app → Download `GoogleService-Info.plist` → Place in `apps/mobile/ios/Runner/`
- [ ] Copy Firebase Server Key from Cloud Messaging settings

### 2. iOS Configuration (3 min)
- [ ] Open `apps/mobile/ios/Runner.xcworkspace` in Xcode
- [ ] Add `GoogleService-Info.plist` to Runner target
- [ ] Enable "Push Notifications" capability
- [ ] Enable "Background Modes" → Check "Remote notifications"

### 3. Database Setup (1 min)
```bash
export SUPABASE_DB_URL='your-connection-string'
./scripts/apply_fcm_tokens.sh
```

### 4. Edge Function Setup (2 min)
```bash
supabase secrets set FIREBASE_SERVER_KEY="your-firebase-server-key"
supabase functions deploy send-push-notification
```

### 5. Install & Test (5 min)
```bash
cd apps/mobile
flutter pub get
flutter run --release  # Must use physical device!
```

## 🧪 Quick Test

1. **Log in** to the app
2. **Grant** notification permissions when prompted
3. **Check logs** for: `✅ FCM token gestoor in databasis`
4. **Send test** notification:
```bash
curl -X POST 'https://YOUR-PROJECT.supabase.co/functions/v1/send-push-notification' \
  --header 'Authorization: Bearer YOUR-ANON-KEY' \
  --header 'Content-Type: application/json' \
  --data '{
    "user_ids": ["YOUR-USER-ID"],
    "title": "Test",
    "body": "It works! 🎉"
  }'
```
5. **Close app** completely (swipe away)
6. **Receive** notification! 📱

## 📱 Features Included

✅ **Firebase Cloud Messaging** - Push notifications to devices  
✅ **Supabase Realtime** - Instant in-app updates  
✅ **Token Management** - Automatic token storage & cleanup  
✅ **Android Support** - Full Android 13+ notification support  
✅ **iOS Support** - APNs integration ready  
✅ **Edge Function** - Server-side notification sending  
✅ **Background Handling** - Receive notifications when app is closed  
✅ **Notification Tapping** - Handle notification tap events  

## 🔧 Already Configured

- ✅ `pubspec.yaml` - Firebase packages added
- ✅ Android Gradle - Google services plugin configured
- ✅ AndroidManifest.xml - Permissions and metadata added
- ✅ NotificationService - Full FCM integration
- ✅ Database migration - FCM token column added
- ✅ Supabase Edge Function - Push notification sender
- ✅ Realtime subscriptions - Instant notification updates

## ⚠️ Important Notes

1. **Physical Device Required**: Push notifications don't work on emulators/simulators
2. **iOS APNs**: Need Apple Developer account for production
3. **Release Build**: Test with `--release` build for best results
4. **Permissions**: Users must grant notification permissions
5. **Internet Required**: Device needs internet for FCM

## 🐛 Common Issues

| Issue | Solution |
|-------|----------|
| No FCM token | Check Firebase config files are in place |
| No notifications on iOS | Enable Push Notifications capability in Xcode |
| Edge function fails | Verify FIREBASE_SERVER_KEY secret is set |
| Token not saved | Run database migration script |
| Notifications not received | Test on physical device, check permissions |

## 📚 Full Documentation

For detailed setup and troubleshooting, see: **PUSH_NOTIFICATIONS_SETUP.md**

## 🎯 What's Next?

After basic setup works:
1. Configure APNs for iOS production
2. Customize notification icons & sounds
3. Add notification categories (orders, announcements, etc.)
4. Implement notification action buttons
5. Add analytics tracking

## 💡 Usage Examples

### From Admin Panel
```dart
// Send to specific user
await NotificationService().stuurNotifikasie(
  gebrId: 'user-123',
  titel: 'Order Ready',
  boodskap: 'Your food is ready for pickup',
  tipe: 'order',
);

// Send to all users
await NotificationService().stuurAanAlleGebruikers(
  titel: 'Important',
  boodskap: 'Cafeteria closes early today',
  tipe: 'announcement',
);
```

### Via Edge Function
```typescript
// Send via API
const response = await supabase.functions.invoke('send-push-notification', {
  body: {
    user_ids: ['user-123'],
    title: 'New Menu Item',
    body: 'Check out today\'s special!',
    data: { type: 'menu', item_id: '456' }
  }
});
```

---

**Ready to go!** 🚀 Follow the checklist above and you'll have push notifications working in 15 minutes.

For help: See PUSH_NOTIFICATIONS_SETUP.md or check Firebase/Supabase docs.

