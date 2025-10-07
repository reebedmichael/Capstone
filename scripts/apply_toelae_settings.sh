#!/bin/bash

# Script to apply toelae settings migration
# This adds system settings table and functions to configure allowance distribution day

echo "🔧 Applying toelae settings migration..."

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Path to migration file
MIGRATION_FILE="$PROJECT_ROOT/db/migrations/0008_add_toelae_settings.sql"

# Check if migration file exists
if [ ! -f "$MIGRATION_FILE" ]; then
    echo "❌ Error: Migration file not found at $MIGRATION_FILE"
    exit 1
fi

# Load environment variables if .env file exists
if [ -f "$PROJECT_ROOT/.env" ]; then
    echo "📄 Loading environment variables..."
    export $(cat "$PROJECT_ROOT/.env" | grep -v '^#' | xargs)
fi

# Check if SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are set
if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_SERVICE_ROLE_KEY" ]; then
    echo "❌ Error: SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY must be set in .env file"
    exit 1
fi

# Extract the database connection string
DB_URL="${SUPABASE_URL/https:\/\//}"
DB_URL="${DB_URL%%/rest*}"

echo "📊 Connecting to database..."

# Apply migration using psql
PGPASSWORD="$SUPABASE_SERVICE_ROLE_KEY" psql \
    -h "$DB_URL" \
    -U postgres \
    -d postgres \
    -f "$MIGRATION_FILE"

if [ $? -eq 0 ]; then
    echo "✅ Migration applied successfully!"
    echo ""
    echo "📝 Next steps:"
    echo "   1. The allowance distribution day is set to default (day 1)"
    echo "   2. Use the admin web interface to change the distribution day"
    echo "   3. The cron job will automatically update when you change the day"
    echo ""
else
    echo "❌ Migration failed!"
    exit 1
fi

