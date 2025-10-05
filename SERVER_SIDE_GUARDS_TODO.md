# Server-Side Guards Required

## Admin Endpoints Security

The following endpoints require server-side validation to enforce role-based access control:

### 1. User Approval Endpoint
**Endpoint:** `PATCH /api/users/:id/approve`
**Required Guards:**
- Verify calling user is authenticated
- Verify calling user has Primary admin role
- Prevent self-approval (calling user ID != target user ID)
- Validate target user exists and is pending approval

**SQL Guard Example:**
```sql
-- Check if calling user is Primary admin
SELECT admin_tipe_id FROM gebruikers 
WHERE gebr_id = :currentUserId 
AND admin_tipe_id = 'ab47ded0-4703-4e7d-8269-f6e5400cbdd8' -- Primary admin ID
AND is_aktief = true;

-- If no result, return 403 Forbidden
```

### 2. Change Admin Type Endpoint
**Endpoint:** `PATCH /api/users/:id/admin-type`
**Required Guards:**
- Verify calling user is Primary admin
- Prevent changing own admin type
- Validate target admin type exists

**SQL Guard Example:**
```sql
-- Check if calling user is Primary admin
SELECT admin_tipe_id FROM gebruikers 
WHERE gebr_id = :currentUserId 
AND admin_tipe_id = 'ab47ded0-4703-4e7d-8269-f6e5400cbdd8' -- Primary admin ID
AND is_aktief = true;

-- Check if target user is not the same as calling user
IF :currentUserId = :targetUserId THEN
  RETURN 403; -- Cannot change own admin type
END IF;
```

### 3. Change User Type Endpoint
**Endpoint:** `PATCH /api/users/:id/user-type`
**Required Guards:**
- Verify calling user is Primary OR Secondary admin
- If Secondary: prevent changing admin users (users with non-None admin_tipe_id)
- Validate target user type exists

**SQL Guard Example:**
```sql
-- Check if calling user is Primary or Secondary admin
SELECT admin_tipe_id FROM gebruikers 
WHERE gebr_id = :currentUserId 
AND admin_tipe_id IN ('ab47ded0-4703-4e7d-8269-f6e5400cbdd8', 'ea9be0db-f762-45a6-8f78-84084ba4751d') -- Primary or Secondary
AND is_aktief = true;

-- If Secondary, check target is not an admin
IF calling_user_admin_type = 'ea9be0db-f762-45a6-8f78-84084ba4751d' THEN -- Secondary
  SELECT admin_tipe_id FROM gebruikers 
  WHERE gebr_id = :targetUserId 
  AND admin_tipe_id IS NOT NULL 
  AND admin_tipe_id != '902397b6-c835-44c2-80cb-d6ad93407048'; -- Not None
  
  IF FOUND THEN
    RETURN 403; -- Secondary cannot change admin users
  END IF;
END IF;
```

### 4. User Activation/Deactivation Endpoint
**Endpoint:** `PATCH /api/users/:id/active`
**Required Guards:**
- Verify calling user is Primary admin
- Prevent deactivating self
- Validate target user exists

**SQL Guard Example:**
```sql
-- Check if calling user is Primary admin
SELECT admin_tipe_id FROM gebruikers 
WHERE gebr_id = :currentUserId 
AND admin_tipe_id = 'ab47ded0-4703-4e7d-8269-f6e5400cbdd8' -- Primary admin ID
AND is_aktief = true;

-- Check if target user is not the same as calling user
IF :currentUserId = :targetUserId THEN
  RETURN 403; -- Cannot deactivate self
END IF;
```

### 5. Allowance Management Endpoint
**Endpoint:** `PATCH /api/user-types/:id/allowance`
**Required Guards:**
- Verify calling user is Primary admin
- Validate user type exists

**SQL Guard Example:**
```sql
-- Check if calling user is Primary admin
SELECT admin_tipe_id FROM gebruikers 
WHERE gebr_id = :currentUserId 
AND admin_tipe_id = 'ab47ded0-4703-4e7d-8269-f6e5400cbdd8' -- Primary admin ID
AND is_aktief = true;
```

## Implementation Notes

1. **Authentication Required:** All endpoints must verify the calling user is authenticated
2. **Role Validation:** Use the provided UUIDs for role checking
3. **Self-Protection:** Prevent users from modifying their own admin status
4. **Secondary Limitations:** Secondary admins cannot modify admin users
5. **Error Responses:** Return 403 Forbidden for unauthorized access attempts
6. **Logging:** Log all admin actions for audit purposes

## UUIDs Reference
- Primary Admin: `ab47ded0-4703-4e7d-8269-f6e5400cbdd8`
- Secondary Admin: `ea9be0db-f762-45a6-8f78-84084ba4751d`
- Tertiary Admin: `6afec372-3294-49fd-a79f-fc244406ee57`
- None Admin: `902397b6-c835-44c2-80cb-d6ad93407048`
- Pending Admin: `f5fde633-eea3-4d58-8509-fb80a74f68a6`
