# Admin Buttons and Ekstern Toelae Fixes

## Issues Fixed

### 1. ✅ Duplicate "Verander Admin Tipe" Buttons
**Problem**: There were two separate "Verander Admin Tipe" buttons showing for the same user, causing UI clutter and confusion.

**Solution**: Removed the duplicate button that was in a separate Consumer widget, keeping only the one in the main user action buttons section.

**Code Removed**:
```dart
// Admin type change button (Primary admin only, for approved users)
Consumer(
  builder: (context, ref, child) {
    final isPrimaryAsync = ref.watch(isPrimaryAdminProvider);
    return isPrimaryAsync.when(
      data: (isPrimary) {
        if (!isPrimary) return const SizedBox.shrink();
        
        final userId = u['gebr_id'].toString();
        final isSelf = userId == currentUserId;
        final hasAdminType = admin.isNotEmpty && admin != 'Pending';
        
        // Don't show for self or users without admin types
        if (isSelf || !hasAdminType) return const SizedBox.shrink();
        
        return IconButton(
          icon: const Icon(Icons.admin_panel_settings, color: Colors.purple),
          onPressed: () => _showChangeAdminTypeDialog(u),
          tooltip: 'Verander Admin Tipe',
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  },
),
```

### 2. ✅ Removed Ekstern Toelae from Management
**Problem**: Ekstern users were showing up in the toelae management section, which shouldn't have allowances.

**Solution**: Completely removed Ekstern from all toelae-related displays and calculations.

#### Changes Made:

**A. Toelae Cards Display**:
```dart
// Before
...(_gebrTipes.map((gebrTipe) => _buildToelaeCard(gebrTipe))),

// After
...(_gebrTipes.where((gebrTipe) => gebrTipe['gebr_tipe_id'] != AdminPermissions.eksternTypeId).map((gebrTipe) => _buildToelaeCard(gebrTipe))),
```

**B. Summary Count**:
```dart
// Before
Text('Totaal Gebruiker Tipes: ${_gebrTipes.length}'),

// After
Text('Totaal Gebruiker Tipes: ${_gebrTipes.where((gebrTipe) => gebrTipe['gebr_tipe_id'] != AdminPermissions.eksternTypeId).length}'),
```

**C. Monthly Payout Calculation**:
```dart
// Before
double _calculateTotalMonthlyPayout() {
  double total = 0.0;
  for (final gebrTipe in _gebrTipes) {
    final allowance = gebrTipe['gebr_toelaag']?.toDouble() ?? 0.0;
    final userCount = _rows.where((u) => u['gebr_tipe_id'] == gebrTipe['gebr_tipe_id']).length;
    total += allowance * userCount;
  }
  return total;
}

// After
double _calculateTotalMonthlyPayout() {
  double total = 0.0;
  for (final gebrTipe in _gebrTipes) {
    // Exclude Ekstern from payout calculation
    if (gebrTipe['gebr_tipe_id'] == AdminPermissions.eksternTypeId) continue;
    
    final allowance = gebrTipe['gebr_toelaag']?.toDouble() ?? 0.0;
    final userCount = _rows.where((u) => u['gebr_tipe_id'] == gebrTipe['gebr_tipe_id']).length;
    total += allowance * userCount;
  }
  return total;
}
```

## Current UI State

### ✅ User Action Buttons (Per User Row)
- **Primary Admins**: See all buttons (Approve/Reject, Deactivate, Change Admin Type, Change User Type)
- **Non-Primary Admins**: See limited buttons based on role permissions
- **No Duplicates**: Only one "Verander Admin Tipe" button per user

### ✅ Toelae Management Tab
- **Student**: Shows allowance card with edit button
- **Personeel**: Shows allowance card with edit button  
- **Ekstern**: Completely hidden from toelae management
- **Summary**: Only counts non-Ekstern types

### ✅ Individual User Allowance Management
- **Student/Personeel**: Show "Bestuur Toelae" button
- **Ekstern**: No allowance management button (already excluded)

## Benefits

1. **Cleaner UI**: No duplicate buttons cluttering the interface
2. **Logical Toelae Management**: Only user types that should have allowances are shown
3. **Accurate Calculations**: Monthly payout totals exclude Ekstern users
4. **Consistent Experience**: Primary admins have clear, non-duplicated access to all features

## Files Modified

- `apps/admin_web/lib/features/gebruikers/presentation/gebruikers_bestuur_page.dart`

## Testing Recommendations

1. **Verify No Duplicate Buttons**: Check that each user row shows only one "Verander Admin Tipe" button
2. **Verify Ekstern Exclusion**: Confirm Ekstern users don't appear in toelae management tab
3. **Verify Calculations**: Check that monthly payout totals don't include Ekstern users
4. **Verify Primary Admin Access**: Ensure Primary admins can still access all features without duplicates
