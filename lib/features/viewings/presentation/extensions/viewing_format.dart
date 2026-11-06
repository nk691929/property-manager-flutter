import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Stored in UTC, shown in the device's local time.
String formatViewingTime(BuildContext context, DateTime value) {
  final locale = Localizations.localeOf(context).toString();
  return DateFormat.yMMMEd(locale).add_jm().format(value.toLocal());
}
