#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${SUPABASE_DB_URL:-}" ]]; then
  echo "SUPABASE_DB_URL is not set. Export it or create a .env.local and source it."
  exit 1
fi

psql "$SUPABASE_DB_URL" -f db/migrations/0000_drop_public.sql
psql "$SUPABASE_DB_URL" -f db/migrations/0001_init_spys.sql 