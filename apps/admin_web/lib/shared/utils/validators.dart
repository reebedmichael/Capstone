import '../constants/strings_af_admin.dart';

class Validators {
  /// Validates email format using a simple regex pattern
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return StringsAfAdmin.errRequired;
    }
    
    // Simple email regex pattern - more permissive but still valid
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    
    // Additional check for consecutive dots
    if (value.contains('..')) {
      return StringsAfAdmin.errEmailInvalid;
    }
    
    if (!emailRegex.hasMatch(value.trim())) {
      return StringsAfAdmin.errEmailInvalid;
    }
    
    return null;
  }

  /// Validates email format using a simple regex pattern
  static String? validateCellphone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return StringsAfAdmin.errRequired;
    }
    
    // Simple cellphone regex pattern - more permissive but still valid
    final cellphoneRegex = RegExp(r'^(?:\+27|0)(6|7|8)(?:[-\s]?\d){8}$');
    
    
    if (!cellphoneRegex.hasMatch(value.trim())) {
      return StringsAfAdmin.errCellphoneInvalid;
    }
    
    return null;
  }
  
  /// Validates password for login (minimum 6 characters)
  static String? validatePasswordLogin(String? value) {
    if (value == null || value.trim().isEmpty) {
      return StringsAfAdmin.errRequired;
    }
    
    if (value.length < 6) {
      return StringsAfAdmin.errPwdShort;
    }
    
    return null;
  }
  
  /// Validates password for registration (minimum 8 characters with number or special char)
  static String? validatePasswordRegister(String? value) {
    if (value == null || value.trim().isEmpty) {
      return StringsAfAdmin.errRequired;
    }
    
    if (value.length < 8) {
      return StringsAfAdmin.errPwdStrong;
    }
    
    // Check if password contains at least one digit or special character
    final hasDigitOrSpecial = RegExp(r'[0-9!@#$%^&*(),.?":{}|<>]').hasMatch(value);
    
    if (!hasDigitOrSpecial) {
      return StringsAfAdmin.errPwdStrong;
    }
    
    return null;
  }
  
  /// Validates password confirmation
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.trim().isEmpty) {
      return StringsAfAdmin.errRequired;
    }
    
    if (value != password) {
      return StringsAfAdmin.errPwdMismatch;
    }
    
    return null;
  }
  
  /// Validates required text fields (first name, last name)
  static String? validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return StringsAfAdmin.errRequired;
    }
    
    return null;
  }
}
