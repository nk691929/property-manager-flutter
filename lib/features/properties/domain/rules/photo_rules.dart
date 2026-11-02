import 'dart:math' as math;
import 'dart:typed_data';

import 'package:property_manager/features/properties/domain/entities/photo_upload.dart';
import 'package:property_manager/features/properties/domain/entities/property_photo.dart';

enum PhotoFieldError { empty, tooLarge, unsupportedType, tooMany }

// Mirrors the bucket settings `guard_photo_insert` in 0003_property_photos.sql.
abstract final class PhotoRules {
  static const maxPerProperty = 10;
  static const maxMegabytes = 5;
  static const int maxBytes = maxMegabytes * 1024 * 1024;
  static const allowedExtensions = {'jpg', 'png', 'webp'};

  static PhotoFieldError? validate(
    PhotoUpload upload, {
    required int existingCount,
  }) {
    if (existingCount >= maxPerProperty) return PhotoFieldError.tooMany;
    if (upload.bytes.isEmpty) return PhotoFieldError.empty;
    if (upload.bytes.length > maxBytes) return PhotoFieldError.tooLarge;
    if (!allowedExtensions.contains(upload.extension)) {
      return PhotoFieldError.unsupportedType;
    }
    return null;
  }

  /// Identifies JPEG, PNG and WebP from their first bytes. File names and
  /// content types from a picker can be wrong or missing; the bytes are not.
  static String? detectExtension(Uint8List b) {
    if (b.length >= 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF) {
      return 'jpg';
    }
    if (b.length >= 8 &&
        b[0] == 0x89 &&
        b[1] == 0x50 &&
        b[2] == 0x4E &&
        b[3] == 0x47) {
      return 'png';
    }
    if (b.length >= 12 &&
        b[0] == 0x52 && // R
        b[1] == 0x49 && // I
        b[2] == 0x46 && // F
        b[3] == 0x46 && // F
        b[8] == 0x57 && // W
        b[9] == 0x45 && // E
        b[10] == 0x42 && // B
        b[11] == 0x50) {
      // P
      return 'webp';
    }
    return null;
  }

  /// Position for a new photo: after the last one.
  static int nextPosition(List<PropertyPhoto> photos) =>
      photos.isEmpty ? 0 : photos.map((p) => p.position).reduce(math.max) + 1;

  /// Position that puts a photo in front of all others (the cover).
  static int positionBeforeFirst(List<PropertyPhoto> photos) =>
      photos.isEmpty ? 0 : photos.map((p) => p.position).reduce(math.min) - 1;
}
