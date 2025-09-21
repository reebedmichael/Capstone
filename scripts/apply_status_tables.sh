#!/bin/bash

# Apply the status tables migration
echo "Applying status tables migration..."

# Check if we have the migration file
if [ ! -f "db/migrations/0003_add_status_tables.sql" ]; then
    echo "Error: Migration file not found!"
    exit 1
fi

# Apply the migration (you'll need to replace with your actual Supabase connection details)
echo "Please run the following SQL in your Supabase SQL editor:"
echo "=========================================="
cat db/migrations/0003_add_status_tables.sql
echo "=========================================="
echo ""
echo "Or use the Supabase CLI if you have it configured:"
echo "supabase db reset --linked"
echo ""
echo "Migration completed!"
