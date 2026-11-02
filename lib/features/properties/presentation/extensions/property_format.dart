import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:property_manager/features/properties/domain/entities/property.dart';
import 'package:property_manager/features/properties/presentation/extensions/property_labels.dart';
import 'package:property_manager/l10n/l10n.dart';

String formatPrice(BuildContext context, Property property) {
  final l10n = context.l10n;
  final locale = Localizations.localeOf(context).toString();
  final amount = NumberFormat.decimalPattern(locale).format(property.price);
  final text = l10n.priceWithCurrency(property.currency, amount);
  return property.isRent ? l10n.pricePerMonth(text) : text;
}

String? formatArea(BuildContext context, Property property) {
  final value = property.areaValue;
  final unit = property.areaUnit;
  if (value == null || unit == null) return null;
  final locale = Localizations.localeOf(context).toString();
  final amount = NumberFormat('#,##0.##', locale).format(value);
  return context.l10n.areaValue(amount, unit.label(context.l10n));
}
