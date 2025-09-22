#!/bin/bash

# Apply wallet transaction types migration
echo "Applying wallet transaction types migration..."

# Check if supabase CLI is available
if ! command -v supabase &> /dev/null; then
    echo "Supabase CLI not found. Please install it first."
    exit 1
fi

# Apply the migration
supabase db push --db-url "$DATABASE_URL" --file db/migrations/0004_add_transaction_types.sql

echo "Migration applied successfully!"
echo "Transaction types 'inbetaling' and 'uitbetaling' have been added to the database."
