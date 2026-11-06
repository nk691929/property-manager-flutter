import 'package:property_manager/core/error/failure.dart';

enum InquiryFieldError { empty, tooLong }

/// Mirrors the CHECK on `inquiry_messages.body` and `create_inquiry`.
abstract final class InquiryRules {
  static const maxLength = 2000;

  static InquiryFieldError? validateBody(String? body) {
    final text = body?.trim() ?? '';
    if (text.isEmpty) return InquiryFieldError.empty;
    if (text.length > maxLength) return InquiryFieldError.tooLong;
    return null;
  }

  static ValidationFailure? validate(String? body) {
    final error = validateBody(body);
    return error == null ? null : ValidationFailure({'message': error.name});
  }
}
