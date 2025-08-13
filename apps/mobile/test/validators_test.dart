import 'package:flutter_test/flutter_test.dart';
import 'package:capstone_mobile/shared/utils/validators.dart';

void main() {
  group('Validators', () {
    group('validateEmail', () {
      test('should return null for valid email addresses', () {
        expect(Validators.validateEmail('test@example.com'), isNull);
        expect(Validators.validateEmail('user.name@domain.co.za'), isNull);
        expect(Validators.validateEmail('test+tag@example.org'), isNull);
      });

      test('should return error for invalid email addresses', () {
        expect(Validators.validateEmail(''), isNotNull);
        expect(Validators.validateEmail('invalid-email'), isNotNull);
        expect(Validators.validateEmail('test@'), isNotNull);
        expect(Validators.validateEmail('@example.com'), isNotNull);
        expect(Validators.validateEmail('test..test@example.com'), isNotNull);
        expect(Validators.validateEmail('test@test'), isNotNull); // Missing TLD
      });

      test('should return error for null input', () {
        expect(Validators.validateEmail(null), isNotNull);
      });
    });

    group('validatePasswordLogin', () {
      test('should return null for valid passwords (6+ characters)', () {
        expect(Validators.validatePasswordLogin('123456'), isNull);
        expect(Validators.validatePasswordLogin('password'), isNull);
        expect(Validators.validatePasswordLogin('verylongpassword123'), isNull);
      });

      test('should return error for short passwords', () {
        expect(Validators.validatePasswordLogin('12345'), isNotNull);
        expect(Validators.validatePasswordLogin('abc'), isNotNull);
      });

      test('should return error for empty or null passwords', () {
        expect(Validators.validatePasswordLogin(''), isNotNull);
        expect(Validators.validatePasswordLogin(null), isNotNull);
      });
    });

    group('validatePasswordRegister', () {
      test('should return null for valid passwords (8+ chars with number/special)', () {
        expect(Validators.validatePasswordRegister('password1'), isNull);
        expect(Validators.validatePasswordRegister('mypass@word'), isNull);
        expect(Validators.validatePasswordRegister('SecurePass123'), isNull);
      });

      test('should return error for short passwords', () {
        expect(Validators.validatePasswordRegister('pass'), isNotNull);
        expect(Validators.validatePasswordRegister('1234567'), isNotNull);
      });

      test('should return error for passwords without numbers or special chars', () {
        expect(Validators.validatePasswordRegister('password'), isNotNull);
        expect(Validators.validatePasswordRegister('onlyletters'), isNotNull);
      });

      test('should return error for empty or null passwords', () {
        expect(Validators.validatePasswordRegister(''), isNotNull);
        expect(Validators.validatePasswordRegister(null), isNotNull);
      });
    });

    group('validateConfirmPassword', () {
      test('should return null when passwords match', () {
        expect(Validators.validateConfirmPassword('password123', 'password123'), isNull);
        expect(Validators.validateConfirmPassword('test@123', 'test@123'), isNull);
      });

      test('should return error when passwords do not match', () {
        expect(Validators.validateConfirmPassword('password123', 'password456'), isNotNull);
        expect(Validators.validateConfirmPassword('test', 'test123'), isNotNull);
      });

      test('should return error for empty or null confirm password', () {
        expect(Validators.validateConfirmPassword('', 'password123'), isNotNull);
        expect(Validators.validateConfirmPassword(null, 'password123'), isNotNull);
      });
    });

    group('validateRequired', () {
      test('should return null for non-empty strings', () {
        expect(Validators.validateRequired('test'), isNull);
        expect(Validators.validateRequired('John'), isNull);
        expect(Validators.validateRequired('123'), isNull);
      });

      test('should return error for empty strings', () {
        expect(Validators.validateRequired(''), isNotNull);
        expect(Validators.validateRequired('   '), isNotNull);
      });

      test('should return error for null input', () {
        expect(Validators.validateRequired(null), isNotNull);
      });
    });
  });
}
