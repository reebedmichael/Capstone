#!/bin/bash

# Apply FCM tokens migration
# This script adds support for Firebase Cloud Messaging tokens to the database

set -e

echo "🚀 Applying FCM tokens migration..."

# Check if SUPABASE_DB_URL is set
if [ -z "$SUPABASE_DB_URL" ]; then
    echo "❌ Error: SUPABASE_DB_URL environment variable is not set"
    echo "Please set it with: export SUPABASE_DB_URL='your-database-url'"
    exit 1
fi

# Apply migration
psql "$SUPABASE_DB_URL" -f db/migrations/0010_add_fcm_tokens.sql

echo "✅ FCM tokens migration applied successfully!"
echo ""
echo "📱 Next steps:"
echo "1. Set up Firebase project in Firebase Console"
echo "2. Download google-services.json and place in apps/mobile/android/app/"
echo "3. Download GoogleService-Info.plist and place in apps/mobile/ios/Runner/"
echo "4. Run 'cd apps/mobile && flutter pub get' to install dependencies"
echo "5. Test push notifications on a physical device"

