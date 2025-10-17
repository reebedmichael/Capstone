#!/bin/bash

# =============================================================================
# Script: Apply Automatic Notification Triggers Migration
# Description: Deploys database triggers for automatic notifications on all system events
# =============================================================================

set -e  # Exit on error

echo "🔔 Applying Automatic Notification Triggers Migration..."
echo ""

# Check if SUPABASE_DB_URL is set
if [ -z "$SUPABASE_DB_URL" ]; then
    echo "❌ Error: SUPABASE_DB_URL environment variable is not set"
    echo ""
    echo "Please set it using:"
    echo "  export SUPABASE_DB_URL='your-connection-string'"
    echo ""
    exit 1
fi

echo "✅ Database URL configured"
echo ""

# Apply migration
echo "📝 Applying migration..."
psql "$SUPABASE_DB_URL" -f db/migrations/0012_add_automatic_notification_triggers.sql

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Migration applied successfully!"
    echo ""
    echo "🎉 Automatic notifications are now enabled for:"
    echo "   ✅ Order status changes"
    echo "   ✅ Wallet/Balance updates"
    echo "   ✅ Allowance distribution"
    echo "   ✅ User approval/activation"
    echo ""
    echo "📱 Push notifications will be sent automatically for all these events!"
    echo ""
    echo "🧪 Test it by:"
    echo "   1. Updating an order status in admin panel"
    echo "   2. Adding funds to a user's wallet"
    echo "   3. Approving a new user"
    echo "   4. Distributing monthly allowances"
    echo ""
else
    echo ""
    echo "❌ Migration failed!"
    echo ""
    exit 1
fi

