#!/bin/bash

# Script to apply the Ontvang status migration
# This adds the 'Ontvang' status for the QR code pickup flow

set -e

echo "=========================================="
echo "Applying Ontvang Status Migration"
echo "=========================================="

# Source environment variables if .env exists
if [ -f .env ]; then
  export $(cat .env | grep -v '^#' | xargs)
fi

# Check if SUPABASE_DB_URL is set
if [ -z "$SUPABASE_DB_URL" ]; then
  echo "Error: SUPABASE_DB_URL is not set"
  echo "Please set it in your .env file or environment"
  exit 1
fi

# Apply the migration
echo "Applying migration: 0007_add_ontvang_status.sql"
psql "$SUPABASE_DB_URL" -f db/migrations/0007_add_ontvang_status.sql

echo "=========================================="
echo "Migration applied successfully!"
echo "=========================================="

