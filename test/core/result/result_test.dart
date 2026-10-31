import 'package:flutter_test/flutter_test.dart';
import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/result/result.dart';

void main() {
  group('Result', () {
    test('Ok exposes value and no failure', () {
      const result = Ok(42);
      expect(result.isOk, isTrue);
      expect(result.valueOrNull, 42);
      expect(result.failureOrNull, isNull);
    });

    test('Err exposes failure and no value', () {
      const result = Err<int>(NetworkFailure());
      expect(result.isOk, isFalse);
      expect(result.valueOrNull, isNull);
      expect(result.failureOrNull, isA<NetworkFailure>());
    });

    test('map transforms Ok and passes Err through', () {
      expect(const Ok(2).map((v) => v * 2).valueOrNull, 4);
      final err = const Err<int>(NotFoundFailure()).map((v) => v * 2);
      expect(err.failureOrNull, isA<NotFoundFailure>());
    });

    test('fold calls the matching branch', () {
      final text = const Ok(1).fold(onOk: (v) => 'ok$v', onErr: (_) => 'err');
      expect(text, 'ok1');
    });
  });
}
