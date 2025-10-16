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

## Automatic Triggering from Database

The system includes an automatic database trigger that sends push notifications whenever new notifications are created. This is already set up via migration `0011_add_push_notification_trigger.sql`.

### Setup Automatic Triggers

1. **Apply the migration**:
   ```bash
   export SUPABASE_DB_URL='postgresql://postgres:[password]@[host]:[port]/postgres'
   ./scripts/apply_push_notification_trigger.sh
   ```

2. **Configure database settings** (REQUIRED):
   ```bash
   # Set your Supabase URL
   psql "$SUPABASE_DB_URL" -c "ALTER DATABASE postgres SET app.settings.supabase_url = 'https://YOUR-PROJECT.supabase.co';"
   
   # Set your Service Role Key
   psql "$SUPABASE_DB_URL" -c "ALTER DATABASE postgres SET app.settings.service_role_key = 'YOUR-SERVICE-ROLE-KEY';"
   ```
   
   Get these values from:
   - **Supabase URL**: Project Settings → API → Project URL
   - **Service Role Key**: Project Settings → API → service_role key (NOT the anon key!)

3. **How it works**:
   - When a new row is inserted into `kennisgewings` table
   - The trigger `on_kennisgewings_insert_send_push` fires
   - It checks if the user has an FCM token
   - If yes, it calls this Edge Function to send the push notification
   - If no, it skips (user will still get notification via Realtime when app is open)

4. **Testing the trigger**:
   ```sql
   -- Insert a test notification
   INSERT INTO public.kennisgewings (gebr_id, kennis_beskrywing, kennis_titel)
   VALUES ('your-user-uuid', 'Test push notification via trigger!', 'Test');
   
   -- Check Edge Function logs
   -- supabase functions logs send-push-notification
   ```

### Manual Database Trigger (Alternative)

If you prefer to customize the trigger, you can create your own:

```sql
-- Create a custom function to send push notification
CREATE OR REPLACE FUNCTION my_custom_push_trigger()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM extensions.http((
    'POST',
    current_setting('app.settings.supabase_url') || '/functions/v1/send-push-notification',
    ARRAY[
      extensions.http_header('Content-Type', 'application/json'),
      extensions.http_header('Authorization', 'Bearer ' || current_setting('app.settings.service_role_key'))
    ],
    'application/json',
    json_build_object(
      'user_ids', ARRAY[NEW.gebr_id::text],
      'title', COALESCE(NEW.kennis_titel, 'Nuwe Kennisgewing'),
      'body', NEW.kennis_beskrywing,
      'data', json_build_object(
        'notification_id', NEW.kennis_id::text,
        'type', 'notification'
      )
    )::text
  )::extensions.http_request);
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
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
- The function uses **FCM V1 API** (recommended by Google) with OAuth2 authentication
- For production, consider rate limiting and batch processing for large numbers of users
- Notifications are sent with high priority for immediate delivery
- The database trigger is non-blocking - it won't prevent notification insertion if push fails
- Users without FCM tokens will still receive notifications via Realtime when the app is open

## Troubleshooting

### Push notifications not being sent automatically

1. **Check database settings are configured**:
   ```sql
   SHOW app.settings.supabase_url;
   SHOW app.settings.service_role_key;
   ```
   If both return empty, you need to configure them (see "Configure database settings" above)

2. **Check Edge Function logs**:
   ```bash
   supabase functions logs send-push-notification
   ```

3. **Test the Edge Function directly**:
   ```bash
   curl -X POST 'https://your-project.supabase.co/functions/v1/send-push-notification' \
     --header 'Authorization: Bearer YOUR_SERVICE_ROLE_KEY' \
     --header 'Content-Type: application/json' \
     --data '{"user_ids":["test-uuid"],"title":"Test","body":"Test message"}'
   ```

4. **Check user has FCM token**:
   ```sql
   SELECT gebr_id, fcm_token FROM public.gebruikers WHERE gebr_id = 'your-user-uuid';
   ```
   If `fcm_token` is NULL, the user needs to log in to the app to register their device

### Firebase Service Account issues

- Make sure you uploaded the **entire JSON** file content as a secret
- The JSON should include `project_id`, `private_key`, `client_email`, etc.
- Verify with: `supabase secrets list` (it will show the secret name but not the value)

### Database permission errors

- The trigger function runs with `SECURITY DEFINER`, so it has the necessary permissions
- If you see permission errors, check that the `extensions.http` extension is installed:
  ```sql
  CREATE EXTENSION IF NOT EXISTS http WITH SCHEMA extensions;
  ```

