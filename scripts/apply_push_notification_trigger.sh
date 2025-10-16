#!/bin/bash

# Script to apply push notification trigger migration
# This sets up automatic push notification sending via database triggers

set -e

echo "================================================"
echo "🚀 Applying Push Notification Trigger Migration"
echo "================================================"
echo ""

# Check if SUPABASE_DB_URL is set
if [ -z "$SUPABASE_DB_URL" ]; then
    echo "❌ Error: SUPABASE_DB_URL environment variable is not set"
    echo ""
    echo "Please set it with:"
    echo "  export SUPABASE_DB_URL='postgresql://postgres:[password]@[host]:[port]/postgres'"
    echo ""
    echo "You can find this in Supabase Dashboard:"
    echo "  Project Settings → Database → Connection string (Direct connection)"
    exit 1
fi

echo "✅ Database URL configured"
echo ""

# Apply migration
echo "📝 Applying migration..."
psql "$SUPABASE_DB_URL" -f "$(dirname "$0")/../db/migrations/0011_add_push_notification_trigger.sql"

if [ $? -eq 0 ]; then
    echo ""
    echo "================================================"
    echo "✅ Push Notification Trigger Migration Applied!"
    echo "================================================"
    echo ""
    echo "📋 Next Steps:"
    echo ""
    echo "1. Configure Supabase settings (REQUIRED):"
    echo "   Run these commands with your actual values:"
    echo ""
    echo "   psql \"\$SUPABASE_DB_URL\" -c \"ALTER DATABASE postgres SET app.settings.supabase_url = 'https://YOUR-PROJECT.supabase.co';\""
    echo "   psql \"\$SUPABASE_DB_URL\" -c \"ALTER DATABASE postgres SET app.settings.service_role_key = 'YOUR-SERVICE-ROLE-KEY';\""
    echo ""
    echo "   Get these values from:"
    echo "   - Supabase URL: Project Settings → API → Project URL"
    echo "   - Service Role Key: Project Settings → API → service_role key"
    echo ""
    echo "2. Deploy the Edge Function (if not already done):"
    echo "   supabase secrets set FIREBASE_SERVICE_ACCOUNT='{\"type\":\"service_account\",...}'"
    echo "   supabase functions deploy send-push-notification"
    echo ""
    echo "3. Test the trigger:"
    echo "   - Insert a test notification into kennisgewings table"
    echo "   - Check your device for push notification"
    echo "   - Check Edge Function logs: supabase functions logs send-push-notification"
    echo ""
    echo "================================================"
else
    echo ""
    echo "❌ Migration failed!"
    exit 1
fi

