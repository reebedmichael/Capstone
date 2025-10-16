# Send Push Notification Edge Function

This Supabase Edge Function sends push notifications to users via Firebase Cloud Messaging (FCM).

## Setup

1. **Get Firebase Service Account Key**:
   - Go to Firebase Console
   - Select your project
   - Go to Project Settings > Service Accounts tab
   - Click "Generate new private key"
   - Download the JSON file (e.g., `spys-xxxxx-firebase-adminsdk-xxxxx.json`)

2. **Set Firebase Service Account as Secret**:
   ```bash
   # Read the entire JSON file content and set it as a secret
   supabase secrets set FIREBASE_SERVICE_ACCOUNT="$(cat path/to/your-service-account.json)"
   ```
   
   Or manually copy the JSON content and set it:
   ```bash
   supabase secrets set FIREBASE_SERVICE_ACCOUNT='{"type":"service_account","project_id":"your-project",...}'
   ```

3. **Deploy the function**:
   ```bash
   supabase functions deploy send-push-notification
   ```

## Usage

### Send to specific users

```bash
curl -i --location --request POST 'https://your-project.supabase.co/functions/v1/send-push-notification' \
  --header 'Authorization: Bearer YOUR_ANON_KEY' \
  --header 'Content-Type: application/json' \
  --data '{
    "user_ids": ["user-uuid-1", "user-uuid-2"],
    "title": "New Order",
    "body": "Your order is ready for pickup",
    "data": {
      "notification_id": "123",
      "type": "order"
    }
  }'
```

### Send to all users

```bash
curl -i --location --request POST 'https://your-project.supabase.co/functions/v1/send-push-notification' \
  --header 'Authorization: Bearer YOUR_ANON_KEY' \
  --header 'Content-Type: application/json' \
  --data '{
    "all_users": true,
    "title": "Important Announcement",
    "body": "The cafeteria will be closed tomorrow",
    "data": {
      "notification_id": "456",
      "type": "announcement"
    }
  }'
```

## From Dart/Flutter

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> sendPushNotification({
  List<String>? userIds,
  bool allUsers = false,
  required String title,
  required String body,
  Map<String, String>? data,
}) async {
  final response = await Supabase.instance.client.functions.invoke(
    'send-push-notification',
    body: {
      if (userIds != null) 'user_ids': userIds,
      if (allUsers) 'all_users': true,
      'title': title,
      'body': body,
      if (data != null) 'data': data,
    },
  );

  if (response.status != 200) {
    throw Exception('Failed to send push notification');
  }
}
```

## Triggering from Database

You can also trigger this function automatically when notifications are created using a PostgreSQL trigger:

```sql
-- Create a function to send push notification when kennisgewings is inserted
CREATE OR REPLACE FUNCTION trigger_push_notification()
RETURNS TRIGGER AS $$
DECLARE
  notification_record RECORD;
BEGIN
  -- Call the edge function
  PERFORM net.http_post(
    url := 'https://your-project.supabase.co/functions/v1/send-push-notification',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || current_setting('app.service_role_key')
    ),
    body := jsonb_build_object(
      'user_ids', ARRAY[NEW.gebr_id],
      'title', COALESCE(NEW.kennis_titel, 'Nuwe Kennisgewing'),
      'body', NEW.kennis_beskrywing,
      'data', jsonb_build_object(
        'notification_id', NEW.kennis_id::text,
        'type', 'notification'
      )
    )
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger
CREATE TRIGGER on_kennisgewings_insert
AFTER INSERT ON public.kennisgewings
FOR EACH ROW
EXECUTE FUNCTION trigger_push_notification();
```

## Response Format

Success:
```json
{
  "success": true,
  "message": "Sent 5 notifications, 0 failed",
  "sent": 5,
  "failed": 0,
  "total": 5
}
```

Error:
```json
{
  "success": false,
  "error": "Error message here"
}
```

## Notes

- Invalid FCM tokens are automatically removed from the database
- The function uses FCM Legacy API for simplicity
- For production, consider rate limiting and batch processing for large numbers of users
- Notifications are sent with high priority for immediate delivery

