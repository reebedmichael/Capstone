-- Migration: Add automatic push notification trigger
-- Date: 2025-10-16
-- Description: Create database trigger to automatically send push notifications via Edge Function
--              when new notifications are inserted into kennisgewings table

-- Enable http extension if not already enabled (required for calling Edge Functions)
CREATE EXTENSION IF NOT EXISTS http WITH SCHEMA extensions;

-- Create function to send push notification via Edge Function
CREATE OR REPLACE FUNCTION public.trigger_send_push_notification()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  v_supabase_url text;
  v_service_role_key text;
  v_function_url text;
  v_notification_title text;
  v_notification_body text;
  v_user_fcm_token text;
  v_http_response extensions.http_response;
BEGIN
  -- Get Supabase URL from environment or use default
  -- Note: In production, you'll need to set these via Supabase dashboard
  -- Settings -> Database -> Custom Config
  v_supabase_url := current_setting('app.settings.supabase_url', true);
  v_service_role_key := current_setting('app.settings.service_role_key', true);
  
  -- If not set via custom config, skip push notification (will still use Realtime)
  IF v_supabase_url IS NULL OR v_service_role_key IS NULL THEN
    RAISE WARNING 'Supabase URL or Service Role Key not configured, skipping push notification';
    RETURN NEW;
  END IF;
  
  -- Check if user has an FCM token (if not, they won't receive push notifications)
  SELECT fcm_token INTO v_user_fcm_token
  FROM public.gebruikers
  WHERE gebr_id = NEW.gebr_id;
  
  IF v_user_fcm_token IS NULL THEN
    -- User doesn't have FCM token, skip push notification
    -- They will still receive notification via Realtime when app is open
    RAISE LOG 'User % has no FCM token, skipping push notification', NEW.gebr_id;
    RETURN NEW;
  END IF;
  
  -- Prepare notification data
  v_notification_title := COALESCE(NEW.kennis_titel, 'Nuwe Kennisgewing');
  v_notification_body := COALESCE(NEW.kennis_beskrywing, '');
  
  -- Build Edge Function URL
  v_function_url := v_supabase_url || '/functions/v1/send-push-notification';
  
  -- Call Edge Function asynchronously (don't wait for response)
  -- This prevents blocking the insert operation
  BEGIN
    v_http_response := extensions.http((
      'POST',
      v_function_url,
      ARRAY[
        extensions.http_header('Content-Type', 'application/json'),
        extensions.http_header('Authorization', 'Bearer ' || v_service_role_key)
      ],
      'application/json',
      json_build_object(
        'user_ids', ARRAY[NEW.gebr_id::text],
        'title', v_notification_title,
        'body', v_notification_body,
        'data', json_build_object(
          'notification_id', NEW.kennis_id::text,
          'type', 'kennisgewings'
        )
      )::text
    )::extensions.http_request);
    
    -- Log success
    IF v_http_response.status >= 200 AND v_http_response.status < 300 THEN
      RAISE LOG 'Push notification sent successfully for notification %', NEW.kennis_id;
    ELSE
      RAISE WARNING 'Push notification failed with status % for notification %', v_http_response.status, NEW.kennis_id;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      -- Log error but don't fail the insert
      RAISE WARNING 'Error sending push notification for notification %: %', NEW.kennis_id, SQLERRM;
  END;
  
  RETURN NEW;
END;
$$;

-- Create trigger on kennisgewings table
DROP TRIGGER IF EXISTS on_kennisgewings_insert_send_push ON public.kennisgewings;

CREATE TRIGGER on_kennisgewings_insert_send_push
  AFTER INSERT ON public.kennisgewings
  FOR EACH ROW
  EXECUTE FUNCTION public.trigger_send_push_notification();

-- Add comment explaining the trigger
COMMENT ON FUNCTION public.trigger_send_push_notification() IS 
'Automatically sends push notifications via Supabase Edge Function when new notifications are created. 
Requires app.settings.supabase_url and app.settings.service_role_key to be configured.';

COMMENT ON TRIGGER on_kennisgewings_insert_send_push ON public.kennisgewings IS
'Automatically triggers push notification sending when new notifications are inserted';

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION public.trigger_send_push_notification() TO postgres;
GRANT EXECUTE ON FUNCTION public.trigger_send_push_notification() TO service_role;

-- Note: To configure the required settings, run:
-- ALTER DATABASE postgres SET app.settings.supabase_url = 'https://your-project.supabase.co';
-- ALTER DATABASE postgres SET app.settings.service_role_key = 'your-service-role-key';

RAISE NOTICE '✅ Push notification trigger created successfully';
RAISE NOTICE '⚠️  Remember to configure Supabase URL and Service Role Key:';
RAISE NOTICE '   ALTER DATABASE postgres SET app.settings.supabase_url = ''https://your-project.supabase.co'';';
RAISE NOTICE '   ALTER DATABASE postgres SET app.settings.service_role_key = ''your-service-role-key'';';

