import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:property_manager/core/money/money.dart';
import 'package:property_manager/l10n/l10n.dart';

/// "PKR 50,000", with decimals only when there are some.
String formatMoney(BuildContext context, Money money) {
  final locale = Localizations.localeOf(context).toString();
  final pattern = money.minorUnits % 100 == 0 ? '#,##0' : '#,##0.00';
  final amount = NumberFormat(pattern, locale).format(money.minorUnits / 100);
  return context.l10n.priceWithCurrency(money.currency, amount);
}

String formatDate(BuildContext context, DateTime date) {
  final locale = Localizations.localeOf(context).toString();
  return DateFormat.yMMMd(locale).format(date);
}
