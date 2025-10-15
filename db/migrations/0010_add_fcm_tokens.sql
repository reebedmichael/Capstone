-- Migration: Add FCM token support for push notifications
-- Date: 2025-10-15
-- Description: Add fcm_token column to gebruikers table to store Firebase Cloud Messaging tokens

-- Add fcm_token column to gebruikers table
ALTER TABLE public.gebruikers
ADD COLUMN IF NOT EXISTS fcm_token TEXT DEFAULT NULL;

-- Add index for faster token lookups
CREATE INDEX IF NOT EXISTS idx_gebruikers_fcm_token ON public.gebruikers(fcm_token);

-- Add comment to explain the column
COMMENT ON COLUMN public.gebruikers.fcm_token IS 'Firebase Cloud Messaging token for push notifications';

-- Optional: Add a function to clean up old/invalid tokens
CREATE OR REPLACE FUNCTION public.cleanup_invalid_fcm_tokens()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Remove tokens that are older than 60 days and haven't been updated
  UPDATE public.gebruikers
  SET fcm_token = NULL
  WHERE fcm_token IS NOT NULL
  AND gebr_laaste_aanmelding < NOW() - INTERVAL '60 days';
END;
$$;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION public.cleanup_invalid_fcm_tokens() TO authenticated;
GRANT EXECUTE ON FUNCTION public.cleanup_invalid_fcm_tokens() TO service_role;

-- Note: Users should be able to update their own FCM token through RLS policies
-- The existing RLS policies on gebruikers table should handle this

