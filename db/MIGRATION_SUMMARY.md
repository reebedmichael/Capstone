# Toelae Migration Summary

## Overview
Successfully migrated from custom `toelae` table back to using the existing `gebr_tipe.gebr_toelaag` field with optional per-user overrides.

## Migration Strategy
- **Approach**: Option B (per-user overrides)
- **Reason**: Maintains flexibility for per-user allowances while using gebr_tipe as default

## Database Changes

### New Schema
1. **Added column**: `gebruikers.toelaag_override` (numeric, nullable)
   - When NULL: Use `gebr_tipe.gebr_toelaag` 
   - When set: Override the type default

2. **Created view**: `vw_gebruiker_toelae`
   - Combines `gebr_tipe.gebr_toelaag` with user overrides
   - Shows active allowance and source information
   - Includes user type information

3. **Dropped**: `toelae` table and all related objects
   - Policies: `p_toelae_select_self`, `p_toelae_admin_all`
   - Indexes: `idx_toelae_gebruiker_id`, `idx_toelae_periode`, `idx_toelae_aktief`

### Migration Process
1. Backup existing `toelae` data (if any)
2. Add `toelaag_override` column to `gebruikers`
3. Migrate active allowances to user overrides
4. Drop `toelae` table
5. Create unified view

## Code Changes

### Removed Files
- `packages/spys_api_client/lib/src/toelae_repository.dart`
- `db/migrations/0003_add_toelae_table.sql`

### New Files
- `packages/spys_api_client/lib/src/allowance_repository.dart`
- `db/migrations/0004_migrate_toelae_to_gebr_tipe.sql`

### Updated Files
- `packages/spys_api_client/lib/spys_api_client.dart` - Export new repository
- `apps/admin_web/lib/locator.dart` - Register AllowanceRepository
- `apps/mobile/lib/locator.dart` - Register AllowanceRepository
- `apps/admin_web/lib/features/gebruikers/presentation/gebruikers_bestuur_page.dart` - New allowance management UI
- `apps/mobile/lib/features/allowance/presentation/pages/allowance_page.dart` - Use real data from new system

## New Allowance System Features

### Admin Web Interface
- View current allowance (type default + any override)
- Set per-user allowance overrides
- Remove overrides (revert to type default)
- Clear indication of allowance source
- Live statistics showing users with allowances

### Mobile Interface
- Display active allowance amount
- Show allowance source (type default vs override)
- Show user type information
- Real-time data from database

### API Methods (AllowanceRepository)
- `getUserAllowance(userId)` - Get combined allowance info
- `setUserAllowanceOverride(userId, amount)` - Set/remove override
- `updateGebrTipeAllowance(typeId, amount)` - Update type default
- `getUsersWithAllowancesCount()` - Statistics
- `getAllowanceSummary()` - Admin dashboard data

## Benefits
1. **Simplified**: Uses existing `gebr_tipe.gebr_toelaag` as foundation
2. **Flexible**: Supports per-user overrides when needed
3. **Consistent**: All users of same type get same default allowance
4. **Maintainable**: Single source of truth with optional overrides
5. **Performant**: Uses database view for efficient queries

## Usage Examples

### Set Type Default Allowance
```dart
await allowanceRepo.updateGebrTipeAllowance(
  gebrTipeId: 'student-type-id',
  bedrag: 1000.0,
);
```

### Set Per-User Override
```dart
await allowanceRepo.setUserAllowanceOverride(
  gebruikerId: 'user-id',
  bedrag: 1200.0, // Override to R1200
);
```

### Remove Override (Use Type Default)
```dart
await allowanceRepo.setUserAllowanceOverride(
  gebruikerId: 'user-id',
  bedrag: null, // Revert to type default
);
```

### Get User Allowance
```dart
final info = await allowanceRepo.getUserAllowance('user-id');
// Returns: {
//   'aktiewe_toelaag': 1000.0,
//   'tipe_toelaag': 1000.0,
//   'toelaag_override': null,
//   'toelaag_bron': 'From user type',
//   'gebr_tipe_naam': 'Student'
// }
```

