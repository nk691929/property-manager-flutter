import 'package:flutter_test/flutter_test.dart';
import 'package:property_manager/features/leases/domain/rules/lease_schedule.dart';

void main() {
  List<DateTime> dates(DateTime start, DateTime end, int dueDay) =>
      LeaseSchedule.dueDates(start: start, end: end, dueDay: dueDay);

  test('a start on the due day gives one charge per month', () {
    final result = dates(DateTime(2027), DateTime(2027, 11, 30), 1);
    expect(result, hasLength(11)); // the same case the SQL test uses
    expect(result.first, DateTime(2027));
    expect(result.last, DateTime(2027, 11));
  });

  test('a start after the due day waits for next month', () {
    final result = dates(DateTime(2027, 1, 15), DateTime(2027, 3, 31), 1);
    expect(result, [DateTime(2027, 2), DateTime(2027, 3)]);
  });

  test('the end date itself is included', () {
    final result = dates(DateTime(2027), DateTime(2027, 3), 1);
    expect(result, hasLength(3));
    expect(result.last, DateTime(2027, 3));
  });

  test('crosses a year boundary', () {
    final result = dates(DateTime(2026, 11, 15), DateTime(2027, 2, 28), 5);
    expect(result, [
      DateTime(2026, 12, 5),
      DateTime(2027, 1, 5),
      DateTime(2027, 2, 5),
    ]);
  });

  test('the last allowed due day works in February', () {
    final result = dates(DateTime(2027), DateTime(2027, 3, 31), 28);
    expect(result, [
      DateTime(2027, 1, 28),
      DateTime(2027, 2, 28),
      DateTime(2027, 3, 28),
    ]);
  });

  test('a range with no due date gives nothing', () {
    expect(dates(DateTime(2027, 1, 2), DateTime(2027, 1, 20), 1), isEmpty);
  });

  test('times of day are ignored', () {
    final result = dates(
      DateTime(2027, 1, 1, 23, 59),
      DateTime(2027, 2, 1, 1),
      1,
    );
    expect(result, [DateTime(2027), DateTime(2027, 2)]);
  });
}
