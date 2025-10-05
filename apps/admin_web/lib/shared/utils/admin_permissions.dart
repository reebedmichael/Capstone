/// Admin permissions based on admin type names
/// Simple approach: permissions are determined by the admin type name
class AdminPermissions {
  static const String primaryAdminType = 'Primary';
  static const String secondaryAdminType = 'Secondary';
  static const String tierseriyAdminType = 'Tierseriy';
  static const String pendingAdminType = 'Pending';
  static const String noneAdminType = 'None';
  
  // Admin type IDs (use exact IDs from requirements)
  static const String primaryAdminId = 'ab47ded0-4703-4e7d-8269-f6e5400cbdd8';
  static const String secondaryAdminId = 'ea9be0db-f762-45a6-8f78-84084ba4751d';
  static const String tierseriyAdminId = '6afec372-3294-49fd-a79f-fc244406ee57';
  static const String pendingAdminId = 'f5fde633-eea3-4d58-8509-fb80a74f68a6';
  
  // User type IDs
  static const String eksternTypeId = '4b2cadfb-90ee-4f89-931d-2b1e7abbc284';
  static const String studentTypeId = '43d3143c-4d52-449d-9b62-5f0f2ca903ca';
  static const String personeelTypeId = '61f13af7-cc87-45c1-8cfb-3bf872980a11';
  
  /// Check if admin type can accept/approve users
  static bool canAcceptUsers(String? adminTypeName) {
    return adminTypeName == primaryAdminType;
  }
  
  /// Check if admin type can create new admin/user types
  static bool canCreateTypes(String? adminTypeName) {
    return adminTypeName == primaryAdminType;
  }
  
  /// Check if admin type can edit allowances
  static bool canEditAllowances(String? adminTypeName) {
    return adminTypeName == primaryAdminType;
  }
  
  /// Check if admin type can modify user types (change Student <-> Personeel)
  static bool canModifyUserTypes(String? adminTypeName) {
    // Allow Secondary to edit regular users (handled in UI logic to restrict targets)
    return adminTypeName == primaryAdminType || adminTypeName == secondaryAdminType;
  }
  
  /// Check if admin type can change admin types of other users
  static bool canChangeAdminTypes(String? adminTypeName) {
    return adminTypeName == primaryAdminType;
  }
  
  /// Check if admin type can manage orders/menus
  /// Secondary can manage orders and spyskaart, Tertiary cannot
  static bool canManageOrders(String? adminTypeName) {
    return adminTypeName == primaryAdminType || adminTypeName == secondaryAdminType;
  }
  
  /// Check if admin type can view reports
  static bool canViewReports(String? adminTypeName) {
    return adminTypeName == primaryAdminType || adminTypeName == secondaryAdminType;
  }
  
  /// Check if admin type can access admin portal at all
  static bool canAccessAdminPortal(String? adminTypeName) {
    return adminTypeName != null && adminTypeName != pendingAdminType;
  }
  
  /// Get default admin type ID for new approvals (Tierseriy)
  static String getDefaultAdminTypeId() {
    return tierseriyAdminId;
  }
  
  /// Get admin type name from ID
  static String? getAdminTypeName(String? adminTypeId) {
    switch (adminTypeId) {
      case primaryAdminId:
        return primaryAdminType;
      case secondaryAdminId:
        return secondaryAdminType;
      case tierseriyAdminId:
        return tierseriyAdminType;
      case pendingAdminId:
        return pendingAdminType;
      default:
        return null;
    }
  }
  
  /// Get user type name from ID
  static String? getUserTypeName(String? userTypeId) {
    switch (userTypeId) {
      case eksternTypeId:
        return 'Ekstern';
      case studentTypeId:
        return 'Student';
      case personeelTypeId:
        return 'Personeel';
      default:
        return null;
    }
  }
  
  /// Check if user is pending approval
  static bool isPendingApproval(Map<String, dynamic> user) {
    final isActive = user['is_aktief'] == true;
    final adminTipeId = user['admin_tipe_id'];
    
    // Show approve only for users where is_aktief = false AND admin_tipe_id = Pending
    return !isActive && adminTipeId == pendingAdminId;
  }
  
  /// Get permissions summary for display
  static Map<String, bool> getPermissionsSummary(String? adminTypeName) {
    return {
      'canAcceptUsers': canAcceptUsers(adminTypeName),
      'canCreateTypes': canCreateTypes(adminTypeName),
      'canEditAllowances': canEditAllowances(adminTypeName),
      'canModifyUserTypes': canModifyUserTypes(adminTypeName),
      'canChangeAdminTypes': canChangeAdminTypes(adminTypeName),
      'canManageOrders': canManageOrders(adminTypeName),
      'canViewReports': canViewReports(adminTypeName),
      'canAccessAdminPortal': canAccessAdminPortal(adminTypeName),
    };
  }
}

