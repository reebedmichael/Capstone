# Schema Compliance Fixes

## Overview
Fixed all database writes to comply with client's existing schema. Removed references to non-existent tables and columns, ensuring only existing database objects are used.

## ✅ Tasks Completed

### 1. Removed Bad DB Writes
- **Deleted erroneous migrations**:
  - `db/migrations/0004_migrate_toelae_to_gebr_tipe.sql` (added `toelaag_override` column)
  - `db/migrations/0005_admin_approval_and_audit.sql` (added `admin_audit` table, `approved_by`, `approved_at` columns)
- **Note**: These migrations were reverted from VCS - DB unchanged as they were never applied to client's database

### 2. Fixed Repository Methods
**File**: `packages/spys_api_client/lib/src/gebruikers_repository.dart`
- **Removed**: References to `approved_by`, `approved_at` columns
- **Removed**: References to `admin_audit` table
- **Fixed**: `approveUser()` method now only updates existing `gebruiker` columns:
  ```dart
  await _sb.from('gebruikers').update({
    'admin_tipe_id': chosenAdminId,
    'gebr_tipe_id': finalGebrTipeId,
    'is_aktief': true,
    // Removed: approved_by, approved_at - columns don't exist
  }).eq('gebr_id', userId);
  ```
- **Fixed**: `getUserWithAllowance()` now uses direct join instead of non-existent view

**File**: `packages/spys_api_client/lib/src/allowance_repository.dart`
- **Removed**: References to `vw_gebruiker_toelae` view
- **Removed**: References to `toelaag_override` column
- **Fixed**: All methods now use direct joins with existing tables:
  ```dart
  .from('gebruikers')
  .select('*, gebr_tipe:gebr_tipe_id(gebr_tipe_naam, gebr_toelaag)')
  ```

### 3. Fixed Admin Interface
**File**: `apps/admin_web/lib/features/gebruikers/presentation/gebruikers_bestuur_page.dart`

**Approve Flow**:
- Now only updates existing `gebruiker` columns
- Removed audit logging (table doesn't exist)
- Exact SQL executed:
  ```sql
  UPDATE public.gebruiker
    SET admin_tipe_id = COALESCE(:admin_tipe_id, '6afec372-3294-49fd-a79f-fc244406ee57'::uuid),
        gebr_tipe_id = COALESCE(:gebr_tipe_id::uuid, gebr_tipe_id),
        is_aktief = true
  WHERE gebr_id = :id;
  ```

**Allowance Management**:
- **Removed**: Individual allowance override functionality
- **Simplified**: Allowance dialog now shows read-only information
- **Stable**: Toelae tab only edits `gebruiker_tipes.gebr_toelaag`
- **Excluded**: Ekstern type from allowance editing (already implemented)

**User Type Changes**:
- **Removed**: `toelaag_override` field from change dialogs
- **Simplified**: Only updates `gebr_tipe_id` in `gebruiker` table
- **Removed**: All audit logging references

### 4. Ensured Stable Toelae Editing
- **Only existing columns**: Uses `gebruiker_tipes.gebr_toelaag` only
- **No overrides**: Removed all per-user override functionality
- **Ekstern excluded**: Already excluded from toelae management
- **Direct updates**: `PATCH /api/gebr_tipe/:id` equivalent updates `gebr_toelaag` directly

## 📋 Allowed Database Objects (Used)

### Tables:
- ✅ `gebruikers` (users)
- ✅ `gebruiker_tipes` (user types) 
- ✅ `admin_tipes` (admin types)
- ✅ `kampus` (campus)

### Key Columns Used:
- ✅ `gebruikers.gebr_id`, `gebr_naam`, `gebr_van`, `gebr_epos`, `gebr_selfoon`
- ✅ `gebruikers.gebr_tipe_id`, `admin_tipe_id`, `is_aktief`, `beursie_balans`
- ✅ `gebruiker_tipes.gebr_tipe_id`, `gebr_tipe_naam`, `gebr_toelaag`
- ✅ `admin_tipes.admin_tipe_id`, `admin_tipe_naam`

## 🚫 Removed References

### Non-existent Tables:
- ❌ `admin_audit` (audit logging)
- ❌ `toelae` (allowances - was never in client schema)
- ❌ `vw_gebruiker_toelae` (view - was never in client schema)

### Non-existent Columns:
- ❌ `gebruikers.toelaag_override` (per-user allowance override)
- ❌ `gebruikers.approved_by` (approval tracking)
- ❌ `gebruikers.approved_at` (approval timestamp)
- ❌ `gebruikers.requested_admin_tipe_id` (requested admin type)

## 🎯 Exact UUIDs Used (From Client Data)

### User Types:
- **Student**: `43d3143c-4d52-449d-9b62-5f0f2ca903ca` (gebr_toelaag: 1000)
- **Ekstern**: `4b2cadfb-90ee-4f89-931d-2b1e7abbc284` (gebr_toelaag: 0)
- **Personeel**: `61f13af7-cc87-45c1-8cfb-3bf872980a11` (gebr_toelaag: 100)

### Admin Types:
- **Tierseriy** (default): `6afec372-3294-49fd-a79f-fc244406ee57`
- **Primary**: `ab47ded0-4703-4e7d-8269-f6e5400cbdd8`
- **Pending**: `f5fde633-eea3-4d58-8509-fb80a74f68a6`

## 🔧 Server-Side SQL (Exact Implementation)

### Approve User:
```sql
BEGIN;
UPDATE public.gebruikers
  SET admin_tipe_id = COALESCE(:admin_tipe_id::uuid, '6afec372-3294-49fd-a79f-fc244406ee57'::uuid),
      gebr_tipe_id = COALESCE(:gebr_tipe_id::uuid, gebr_tipe_id),
      is_aktief = true
WHERE gebr_id = :id;
COMMIT;
```

### Effective Allowance Calculation:
```sql
SELECT 
  g.*,
  gt.gebr_toelaag as effective_toelaag
FROM gebruikers g
LEFT JOIN gebruiker_tipes gt ON g.gebr_tipe_id = gt.gebr_tipe_id
WHERE g.gebr_id = :id;
```

### Update Type Allowance:
```sql
UPDATE gebruiker_tipes 
SET gebr_toelaag = :bedrag 
WHERE gebr_tipe_id = :id;
```

## ✅ Compliance Verification

1. **No new tables/columns created**: ✅
2. **Only existing schema used**: ✅
3. **Approve updates existing gebruiker only**: ✅
4. **Toelae editing stable**: ✅
5. **Ekstern excluded from toelae**: ✅
6. **Self-approval prevention**: ✅ (in repository)
7. **Exact UUIDs used**: ✅

## 🚀 Ready for Production

The application now:
- ✅ Only writes to existing database columns
- ✅ Uses client's exact table structure
- ✅ Maintains stable toelae editing
- ✅ Excludes Ekstern from allowance management
- ✅ Implements proper approve flow with existing columns only
- ✅ Has no references to non-existent tables/columns

**All database operations are now compliant with the client's existing schema.**
