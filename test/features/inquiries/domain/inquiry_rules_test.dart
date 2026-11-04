import 'package:flutter_test/flutter_test.dart';
import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/features/inquiries/domain/rules/inquiry_rules.dart';

void main() {
  test('blank messages are empty', () {
    expect(InquiryRules.validateBody(null), InquiryFieldError.empty);
    expect(InquiryRules.validateBody(''), InquiryFieldError.empty);
    expect(InquiryRules.validateBody('   '), InquiryFieldError.empty);
  });

  test('length is checked after trimming', () {
    expect(InquiryRules.validateBody('a' * 2000), isNull);
    expect(InquiryRules.validateBody(' ${'a' * 2000} '), isNull);
    expect(InquiryRules.validateBody('a' * 2001), InquiryFieldError.tooLong);
  });

  test('validate wraps the code in a ValidationFailure', () {
    final failure = InquiryRules.validate('');
    expect(failure, isA<ValidationFailure>());
    expect(failure?.fieldErrors['message'], 'empty');
    expect(InquiryRules.validate('Hello'), isNull);
  });
}
