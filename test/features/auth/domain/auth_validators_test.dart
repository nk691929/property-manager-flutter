import 'package:flutter_test/flutter_test.dart';
import 'package:property_manager/features/auth/domain/validators/auth_validators.dart';

void main() {
  test('email', () {
    expect(AuthValidators.email(''), FieldError.empty);
    expect(AuthValidators.email('nope'), FieldError.invalidEmail);
    expect(AuthValidators.email(' a@b.co '), isNull);
  });

  test('password (sign-up rules)', () {
    expect(AuthValidators.password(''), FieldError.empty);
    expect(AuthValidators.password('short'), FieldError.passwordTooShort);
    expect(AuthValidators.password('longenough'), isNull);
  });

  test('sign-in password only needs to be non-empty', () {
    expect(AuthValidators.signInPassword(''), FieldError.empty);
    expect(AuthValidators.signInPassword('x'), isNull);
  });

  test('confirmPassword', () {
    expect(AuthValidators.confirmPassword('a', ''), FieldError.empty);
    expect(
      AuthValidators.confirmPassword('a', 'b'),
      FieldError.passwordsMismatch,
    );
    expect(AuthValidators.confirmPassword('a', 'a'), isNull);
  });
}
