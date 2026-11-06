import 'package:flutter_test/flutter_test.dart';
import 'package:property_manager/features/viewings/domain/rules/viewing_rules.dart';

void main() {
  final now = DateTime.utc(2026, 11, 3, 9);

  group('time window', () {
    test('at least one hour ahead, at most 90 days', () {
      expect(
        ViewingRules.validateTime(
          now.add(const Duration(minutes: 59)),
          now: now,
        ),
        ViewingFieldError.tooSoon,
      );
      expect(
        ViewingRules.validateTime(now.add(const Duration(hours: 1)), now: now),
        isNull,
      );
      expect(
        ViewingRules.validateTime(now.add(const Duration(days: 90)), now: now),
        isNull,
      );
      expect(
        ViewingRules.validateTime(
          now.add(const Duration(days: 90, minutes: 1)),
          now: now,
        ),
        ViewingFieldError.tooFar,
      );
    });

    test('the past is too soon', () {
      expect(
        ViewingRules.validateTime(
          now.subtract(const Duration(days: 1)),
          now: now,
        ),
        ViewingFieldError.tooSoon,
      );
    });
  });

  group('decline reason', () {
    test('required, trimmed, at most 300 characters', () {
      expect(ViewingRules.validateReason(null), ViewingFieldError.reasonEmpty);
      expect(ViewingRules.validateReason('   '), ViewingFieldError.reasonEmpty);
      expect(ViewingRules.validateReason('a' * 300), isNull);
      expect(
        ViewingRules.validateReason('a' * 301),
        ViewingFieldError.reasonTooLong,
      );
    });
  });
}
