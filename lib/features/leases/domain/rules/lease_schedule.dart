import 'package:property_manager/core/time/calendar.dart';

/// The rent schedule. MUST mirror the loop in `create_lease` in
/// supabase/migrations/0005_leases_and_rent.sql. The database is the
/// authority; this copy powers the form preview and the offline fake.
abstract final class LeaseSchedule {
  /// First due date on or after [start], then one per month while on or
  /// before [end]. Safe for any [dueDay] up to 28.
  static List<DateTime> dueDates({
    required DateTime start,
    required DateTime end,
    required int dueDay,
  }) {
    final first = Calendar.dateOnly(start);
    final last = Calendar.dateOnly(end);
    var due = DateTime(first.year, first.month, dueDay);
    if (due.isBefore(first)) {
      due = DateTime(first.year, first.month + 1, dueDay);
    }

    final dates = <DateTime>[];
    while (!due.isAfter(last)) {
      dates.add(due);
      due = DateTime(due.year, due.month + 1, dueDay);
    }
    return dates;
  }
}
