import 'package:flutter_test/flutter_test.dart';
import 'package:property_manager/core/money/money.dart';

void main() {
  group('parse (database values)', () {
    test('reads numbers and text exactly', () {
      expect(Money.parse(50000, currency: 'PKR').minorUnits, 5000000);
      expect(Money.parse('50000.00', currency: 'PKR').minorUnits, 5000000);
      expect(Money.parse('0.10', currency: 'PKR').minorUnits, 10);
      expect(Money.parse(12.5, currency: 'PKR').minorUnits, 1250);
      expect(Money.parse('7', currency: 'PKR').minorUnits, 700);
    });

    test('refuses to silently drop decimals', () {
      expect(
        () => Money.parse('1.005', currency: 'PKR'),
        throwsFormatException,
      );
      expect(Money.parse('1.500', currency: 'PKR').minorUnits, 150);
      expect(() => Money.parse('abc', currency: 'PKR'), throwsFormatException);
      expect(() => Money.parse(null, currency: 'PKR'), throwsFormatException);
    });
  });

  group('tryParse (user input)', () {
    test('accepts plain amounts', () {
      expect(Money.tryParse('1,250.50', currency: 'PKR')?.minorUnits, 125050);
      expect(Money.tryParse(' 50000 ', currency: 'PKR')?.minorUnits, 5000000);
      expect(Money.tryParse('0', currency: 'PKR')?.isZero, isTrue);
    });

    test('rejects everything else', () {
      for (final text in ['', 'abc', '-5', '1.234', '1.', '.5', '1e3', null]) {
        expect(Money.tryParse(text, currency: 'PKR'), isNull, reason: '$text');
      }
    });
  });

  test('arithmetic is exact (the point of minor units)', () {
    expect(
      Money.parse('0.10', currency: 'PKR') +
          Money.parse('0.20', currency: 'PKR'),
      Money.parse('0.30', currency: 'PKR'),
    );
    expect(const Money(5000) * 11, const Money(55000));
    expect(const Money(5000) - const Money(1200), const Money(3800));
    expect(
      Money.sum(const [Money(100), Money(250)], currency: 'PKR'),
      const Money(350),
    );
  });

  test('comparison, equality and flags', () {
    expect(const Money(100) < const Money(200), isTrue);
    expect(const Money(200) >= const Money(200), isTrue);
    expect(const Money(100) == const Money(100), isTrue);
    expect(const Money(100) == const Money(100, currency: 'USD'), isFalse);
    expect(const Money.zero().isZero, isTrue);
    expect(const Money(1).isPositive, isTrue);
  });

  test('mixing currencies is a programming error', () {
    expect(
      () => const Money(100) + const Money(100, currency: 'USD'),
      throwsArgumentError,
    );
  });

  test('toDecimalString is what the database expects', () {
    expect(const Money(5000000).toDecimalString(), '50000.00');
    expect(const Money(5).toDecimalString(), '0.05');
    expect(const Money(12345).toDecimalString(), '123.45');
    expect(const Money(-250).toDecimalString(), '-2.50');
  });
}
