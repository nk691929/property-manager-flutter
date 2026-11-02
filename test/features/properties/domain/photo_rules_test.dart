import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:property_manager/features/properties/domain/entities/photo_upload.dart';
import 'package:property_manager/features/properties/domain/rules/photo_rules.dart';

import '../../../helpers/property_test_helpers.dart';

void main() {
  group('detectExtension', () {
    test('recognises JPEG, PNG and WebP by their first bytes', () {
      expect(
        PhotoRules.detectExtension(
          Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]),
        ),
        'jpg',
      );
      expect(
        PhotoRules.detectExtension(
          Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]),
        ),
        'png',
      );
      expect(
        PhotoRules.detectExtension(
          Uint8List.fromList([
            0x52, 0x49, 0x46, 0x46, 0, 0, 0, 0, 0x57, 0x45, 0x42, 0x50, //
          ]),
        ),
        'webp',
      );
    });

    test('rejects anything else, including empty input', () {
      final gif = Uint8List.fromList('GIF89a'.codeUnits);
      expect(PhotoRules.detectExtension(gif), isNull);
      expect(PhotoRules.detectExtension(Uint8List(0)), isNull);
    });
  });

  group('validate', () {
    test('accepts a normal photo', () {
      expect(PhotoRules.validate(jpegUpload(), existingCount: 3), isNull);
    });

    test('flags each problem', () {
      expect(
        PhotoRules.validate(jpegUpload(), existingCount: 10),
        PhotoFieldError.tooMany,
      );
      expect(
        PhotoRules.validate(jpegUpload(0), existingCount: 0),
        PhotoFieldError.empty,
      );
      expect(
        PhotoRules.validate(
          jpegUpload(PhotoRules.maxBytes + 1),
          existingCount: 0,
        ),
        PhotoFieldError.tooLarge,
      );
      expect(
        PhotoRules.validate(
          PhotoUpload(bytes: Uint8List(10), extension: 'gif'),
          existingCount: 0,
        ),
        PhotoFieldError.unsupportedType,
      );
    });
  });

  test('positions: append at the end, cover goes in front', () {
    final photos = [samplePhoto('a', 0), samplePhoto('b', 1)];
    expect(PhotoRules.nextPosition(photos), 2);
    expect(PhotoRules.positionBeforeFirst(photos), -1);
    expect(PhotoRules.nextPosition(const []), 0);
    expect(PhotoRules.positionBeforeFirst(const []), 0);
  });
}
