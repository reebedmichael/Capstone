#!/bin/bash

# Script to apply allowance system migration to Supabase
# 
# Usage:
#   ./scripts/apply_allowance_migration.sh
#
# Prerequisites:
#   - Supabase CLI installed OR
#   - Direct PostgreSQL access to your Supabase database

echo "🚀 Applying Allowance System Migration..."
echo ""
echo "Option 1: Using Supabase CLI"
echo "  supabase db push"
echo ""
echo "Option 2: Using SQL Editor in Supabase Dashboard"
echo "  1. Go to https://supabase.com/dashboard/project/YOUR_PROJECT/sql/new"
echo "  2. Copy the contents of db/migrations/0006_add_allowance_system.sql"
echo "  3. Run the SQL"
echo ""
echo "Option 3: Using psql (if you have connection details)"
echo "  psql -h YOUR_HOST -p YOUR_PORT -d postgres -U postgres.YOUR_USER -f db/migrations/0006_add_allowance_system.sql"
echo ""

read -p "Do you want to view the migration file? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    cat db/migrations/0006_add_allowance_system.sql
fi

