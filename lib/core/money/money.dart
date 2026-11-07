// import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';

/// An amount of money in whole minor units (paisa for PKR), never a double.
@immutable
final class Money implements Comparable<Money> {
  const new(this.minorUnits, {this.currency = 'PKR'});

  factory sum(Iterable<Money> values, {required String currency}) =>
      values.fold(Money.zero(currency), (total, value) => total + value);

  const new zero([this.currency = 'PKR']) : minorUnits = 0;

  /// Reads a database `numeric` (it arrives as a number or as text).
  factory parse(Object? raw, {required String currency}) => switch (raw) {
    final int whole => Money(whole * 100, currency: currency),
    final num value => Money((value * 100).round(), currency: currency),
    final String text => Money(_minorFromDecimal(text), currency: currency),
    _ => throw FormatException('Not an amount: $raw'),
  };

  /// Reads user input like `1,250.50`. Returns null when it isn't a plain
  /// amount with at most two decimals.
  static Money? tryParse(String? text, {required String currency}) {
    final cleaned = (text ?? '').replaceAll(',', '').replaceAll(' ', '');
    if (!RegExp(r'^\d{1,12}(\.\d{1,2})?$').hasMatch(cleaned)) return null;
    return Money(_minorFromDecimal(cleaned), currency: currency);
  }

  /// 12345 minor units = 123.45.
  final int minorUnits;
  final String currency;

  bool get isPositive => minorUnits > 0;
  bool get isZero => minorUnits == 0;

  Money operator +(Money other) =>
      Money(minorUnits + _same(other).minorUnits, currency: currency);

  Money operator -(Money other) =>
      Money(minorUnits - _same(other).minorUnits, currency: currency);

  Money operator *(int times) => Money(minorUnits * times, currency: currency);

  bool operator <(Money other) => compareTo(other) < 0;
  bool operator <=(Money other) => compareTo(other) <= 0;
  bool operator >(Money other) => compareTo(other) > 0;
  bool operator >=(Money other) => compareTo(other) >= 0;

  @override
  int compareTo(Money other) => minorUnits.compareTo(_same(other).minorUnits);

  /// `50000.00`: what the database expects (exact, never a double).
  String toDecimalString() {
    final absolute = minorUnits.abs();
    final sign = minorUnits < 0 ? '-' : '';
    final cents = (absolute % 100).toString().padLeft(2, '0');
    return '$sign${absolute ~/ 100}.$cents';
  }

  Money _same(Money other) {
    if (other.currency != currency) {
      throw ArgumentError('Currency mismatch: $currency vs ${other.currency}');
    }
    return other;
  }

  static int _minorFromDecimal(String text) {
    final match = RegExp(r'^(-?)(\d+)(?:\.(\d+))?$').firstMatch(text.trim());
    if (match == null) throw FormatException('Not an amount: $text');
    final whole = int.parse(match.group(2)!);
    final padded = (match.group(3) ?? '').padRight(2, '0');
    // Silent truncation of money is a bug, so extra decimals must be zeros.
    if (padded.substring(2).replaceAll('0', '').isNotEmpty) {
      throw FormatException('More than two decimals: $text');
    }
    final minor = whole * 100 + int.parse(padded.substring(0, 2));
    return match.group(1) == '-' ? -minor : minor;
  }

  @override
  bool operator ==(Object other) =>
      other is Money &&
      other.minorUnits == minorUnits &&
      other.currency == currency;

  @override
  int get hashCode => Object.hash(minorUnits, currency);

  @override
  String toString() => 'Money($currency ${toDecimalString()})';
}
