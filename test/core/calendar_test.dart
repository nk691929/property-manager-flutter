import 'package:flutter_test/flutter_test.dart';
import 'package:property_manager/core/time/calendar.dart';

void main() {
  test('parse and format round-trip', () {
    final date = Calendar.parse('2027-03-09');
    expect(date, DateTime(2027, 3, 9));
    expect(Calendar.formatIso(date), '2027-03-09');
  });

  test('parse ignores a time part', () {
    expect(Calendar.parse('2027-03-09T00:00:00'), DateTime(2027, 3, 9));
  });

  test('dateOnly drops the time', () {
    expect(
      Calendar.dateOnly(DateTime(2027, 3, 9, 22, 30)),
      DateTime(2027, 3, 9),
    );
  });

  test('addMonths clamps to the last day like Postgres', () {
    expect(Calendar.addMonths(DateTime(2027, 1, 31), 1), DateTime(2027, 2, 28));
    expect(Calendar.addMonths(DateTime(2028, 1, 31), 1), DateTime(2028, 2, 29));
    expect(
      Calendar.addMonths(DateTime(2027, 11, 15), 3),
      DateTime(2028, 2, 15),
    );
    expect(Calendar.addMonths(DateTime(2027), 36), DateTime(2030));
    expect(
      Calendar.addMonths(DateTime(2027, 3, 31), -1),
      DateTime(2027, 2, 28),
    );
  });

  test('addDays crosses month and year ends', () {
    expect(Calendar.addDays(DateTime(2027, 12, 31), 1), DateTime(2028));
    expect(Calendar.addDays(DateTime(2027, 3), -1), DateTime(2027, 2, 28));
  });
}
