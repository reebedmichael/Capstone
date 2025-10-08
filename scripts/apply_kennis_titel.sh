#!/bin/bash

# Apply kennisgewings titel migration

echo "Applying kennisgewings titel migration..."

psql 'postgresql://postgres.fdtjqpkrgstoobgkmvva:TRV#r7ghWe569XluhkXnV@aws-0-eu-central-1.pooler.supabase.com:6543/postgres' -f db/migrations/0009_add_kennis_titel.sql

echo "Migration completed!"

