import 'dart:math' as math;

/// Calendar dates (no time of day) as local-midnight [DateTime]s, so a due
/// date never shifts with the time zone. Pure Dart.
abstract final class Calendar {
  static DateTime dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  /// Reads `YYYY-MM-DD` (what a database `date` column sends).
  static DateTime parse(String iso) {
    final parts = iso.substring(0, 10).split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  static String formatIso(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// Calendar arithmetic, not 24-hour blocks (those drift across DST changes).
  static DateTime addDays(DateTime value, int days) =>
      DateTime(value.year, value.month, value.day + days);

  /// Like Postgres: 31 Jan + 1 month = 28 (or 29) Feb, not 3 March.
  static DateTime addMonths(DateTime value, int months) {
    final index = value.year * 12 + (value.month - 1) + months;
    final year = index ~/ 12;
    final month = index % 12 + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, math.min(value.day, lastDay));
  }
}
