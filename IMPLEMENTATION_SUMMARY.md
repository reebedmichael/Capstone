# Admin Approval Workflow & Type Management Implementation

## Branch: `feat/admin-approval-permissions-toelae-default-tierseriy`

## Overview
This implementation provides a comprehensive admin approval workflow with type management, allowance configuration, and audit logging. The system uses admin type names to determine permissions rather than complex permission objects.

## Key Features Implemented

### 1. Registration & Approval Workflow
- **New registrations** are created with:
  - `gebr_tipe_id = Ekstern` (`4b2cadfb-90ee-4f89-931d-2b1e7abbc284`)
  - `is_aktief = false`
  - `admin_tipe_id = Pending` (`f5fde633-eea3-4d58-8509-fb80a74f68a6`)
  - Optional `requested_admin_tipe_id` for future use

- **Primary admins** can approve pending users via comprehensive modal:
  - Select final `gebr_tipe` (Student/Personeel/Ekstern)
  - Select `admin_tipe` (defaults to **Tierseriy** if none selected)
  - Preview permissions for selected admin type
  - Automatic audit logging of approval actions

### 2. Admin Type Permissions (Simple Approach)
Instead of complex permission objects, permissions are determined by admin type names:

- **Primary**: Full access (can approve users, create types, edit allowances, etc.)
- **Tierseriy**: Standard admin access (can manage orders, view reports)
- **Pending**: No admin portal access (redirected to approval page)

### 3. Tabbed Interface
- **Gebruikers Tab**: User management with approval workflow
- **Toelae Tab**: Allowance management per user type

### 4. Type Management Features
- **Change Admin Type**: Primary admins can change approved users' admin types
- **Change User Type**: Primary admins can change users' gebr_tipe with optional allowance override
- **Allowance Management**: Edit monthly allowances per user type
- **Self-Modification Prevention**: Users cannot change their own types/status

### 5. Enhanced UI Features
- **Pending Filter**: Shows users awaiting approval
- **Requested Admin Type Display**: Shows what admin type was requested during registration
- **Permissions Preview**: Shows what permissions each admin type has
- **Audit Trail**: All admin actions are logged with details

## Database Changes

### New Tables
```sql
-- Admin audit logging
CREATE TABLE admin_audit (
  audit_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id uuid NOT NULL REFERENCES gebruikers(gebr_id),
  target_gebr_id uuid NOT NULL REFERENCES gebruikers(gebr_id),
  action text NOT NULL,
  old_values jsonb,
  new_values jsonb,
  details jsonb,
  created_at timestamptz DEFAULT now()
);
```

### New Columns
```sql
-- Track approval workflow
ALTER TABLE gebruikers ADD COLUMN requested_admin_tipe_id uuid REFERENCES admin_tipes(admin_tipe_id);
ALTER TABLE gebruikers ADD COLUMN approved_by uuid REFERENCES gebruikers(gebr_id);
ALTER TABLE gebruikers ADD COLUMN approved_at timestamptz;
```

### Updated View
```sql
-- Enhanced view with approval and audit info
CREATE OR REPLACE VIEW vw_gebruiker_toelae AS
SELECT 
    g.gebr_id, g.gebr_naam, g.gebr_van, g.gebr_epos, g.gebr_selfoon, g.is_aktief,
    gt.gebr_tipe_id, gt.gebr_tipe_naam, gt.gebr_toelaag as tipe_toelaag,
    g.toelaag_override,
    COALESCE(g.toelaag_override, gt.gebr_toelaag) as aktiewe_toelaag,
    at.admin_tipe_id, at.admin_tipe_naam,
    rat.admin_tipe_naam as requested_admin_tipe_naam,
    g.requested_admin_tipe_id, g.approved_by, g.approved_at,
    approver.gebr_naam as approved_by_naam
FROM gebruikers g
LEFT JOIN gebruiker_tipes gt ON g.gebr_tipe_id = gt.gebr_tipe_id
LEFT JOIN admin_tipes at ON g.admin_tipe_id = at.admin_tipe_id
LEFT JOIN admin_tipes rat ON g.requested_admin_tipe_id = rat.admin_tipe_id
LEFT JOIN gebruikers approver ON g.approved_by = approver.gebr_id;
```

## Files Modified

### Core Infrastructure
- `db/migrations/0005_admin_approval_and_audit.sql` - Database schema changes
- `apps/admin_web/lib/shared/utils/admin_permissions.dart` - Permission logic based on admin types

### Mobile App
- `apps/mobile/lib/shared/services/auth_service.dart` - Updated registration to use Pending admin type

### Admin Web App
- `apps/admin_web/lib/features/gebruikers/presentation/gebruikers_bestuur_page.dart` - Complete overhaul with tabs, approval workflow, type management
- `apps/admin_web/lib/shared/providers/auth_providers.dart` - Added approval and Primary admin providers
- `apps/admin_web/lib/shared/widgets/auth_guard.dart` - Updated to check approval status
- `apps/admin_web/lib/features/auth/presentation/wag_vir_goedkeuring_page.dart` - Enhanced waiting page
- `apps/admin_web/lib/features/auth/presentation/registreer_admin_page.dart` - Updated success messaging

## Key UI Components

### 1. Approval Modal
- User information display
- User type selection (Student/Personeel/Ekstern)
- Admin type selection (defaults to Tierseriy)
- Permissions preview for selected admin type
- Audit logging on approval

### 2. Toelae Tab
- Monthly allowance management per user type
- Summary of total monthly payouts
- Primary-only edit controls
- Real-time allowance calculations

### 3. Type Change Dialogs
- **Admin Type Change**: Change admin privileges with permission preview
- **User Type Change**: Change user category with allowance override option
- Both include audit logging and validation

### 4. Enhanced User Cards
- Display requested admin type for pending users
- Action buttons based on user status and admin permissions
- Self-modification prevention with tooltips

## Security Features

### UI-Level Security
- Primary-only controls throughout the interface
- Self-modification prevention (cannot change own type/status)
- Permission-based button visibility
- Tooltips explaining access restrictions

### Server-Side TODOs
All critical operations include TODO comments for server-side enforcement:
```dart
// TODO: SERVER-SIDE ENFORCEMENT REQUIRED
// Server must validate Primary admin status before allowing [action]
```

### Audit Trail
- All admin actions logged to `admin_audit` table
- Includes actor, target, old/new values, and contextual details
- RLS policies ensure proper access control

## Admin Type Hierarchy

1. **Primary** (`ab47ded0-4703-4e7d-8269-f6e5400cbdd8`)
   - Full system access
   - Can approve users, create types, edit allowances
   - Can change admin/user types of others

2. **Tierseriy** (`6afec372-3294-49fd-a79f-fc244406ee57`) - Default for new approvals
   - Standard admin access
   - Can manage orders and view reports
   - Cannot approve users or change types

3. **Pending** (`f5fde633-eea3-4d58-8509-fb80a74f68a6`)
   - No admin portal access
   - Redirected to approval waiting page

## User Type IDs
- **Ekstern**: `4b2cadfb-90ee-4f89-931d-2b1e7abbc284`
- **Student**: `43d3143c-4d52-449d-9b62-5f0f2ca903ca`
- **Personeel**: `61f13af7-cc87-45c1-8cfb-3bf872980a11`

## Usage Instructions

### For Primary Admins
1. **Approve Pending Users**: Use "Wag Goedkeuring" filter → "Keur Goed" button
2. **Change Admin Types**: Purple admin icon on approved user cards
3. **Change User Types**: Teal swap icon on user cards
4. **Manage Allowances**: Switch to "Toelae" tab → "Wysig" buttons
5. **Create New Types**: Three-dot menu at top-right

### For Regular Admins (Tierseriy)
- Can view users and manage orders
- Cannot approve users or change types
- Limited to operational functions

### For Pending Users
- Redirected to approval waiting page
- Can sign out and check status
- Cannot access admin functions

## Migration Notes

1. **Apply Database Migration**: Run `db/migrations/0005_admin_approval_and_audit.sql`
2. **Verify Admin Types**: Ensure Primary, Tierseriy, and Pending admin types exist with correct IDs
3. **Test Approval Flow**: Register new user → appears as pending → Primary approves
4. **Verify Permissions**: Test that non-Primary admins cannot access restricted functions

## Rollback Strategy

If rollback is needed:
1. **Database**: Drop new columns and audit table
2. **Code**: Revert to previous admin registration flow
3. **Users**: Manually activate any pending users if needed

## Future Enhancements

1. **Server-Side API**: Implement proper REST endpoints with validation
2. **Email Notifications**: Notify users when approved/declined
3. **Bulk Operations**: Approve/decline multiple users at once
4. **Advanced Permissions**: Custom permission sets per admin type
5. **Audit Dashboard**: Visual audit log with filtering and search

This implementation provides a solid foundation for admin management while maintaining security and usability.



