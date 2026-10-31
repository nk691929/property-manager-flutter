/// Codes, not messages: the presentation layer localizes them.
enum FieldError {
  empty,
  invalidEmail,
  passwordTooShort,
  passwordsMismatch,
  emailTaken,
  weakPassword,
}

abstract final class AuthValidators {
  static const minPasswordLength = 8;

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static FieldError? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return FieldError.empty;
    if (!_emailPattern.hasMatch(v)) return FieldError.invalidEmail;
    return null;
  }

  /// Sign-up rules. Sign-in only requires non-empty (see [signInPassword]).
  static FieldError? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return FieldError.empty;
    if (v.length < minPasswordLength) return FieldError.passwordTooShort;
    return null;
  }

  static FieldError? signInPassword(String? value) =>
      (value ?? '').isEmpty ? FieldError.empty : null;

  static FieldError? confirmPassword(String? password, String? confirm) {
    if ((confirm ?? '').isEmpty) return FieldError.empty;
    if (password != confirm) return FieldError.passwordsMismatch;
    return null;
  }
}
