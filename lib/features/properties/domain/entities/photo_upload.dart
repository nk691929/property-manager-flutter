import 'dart:typed_data';

/// Bytes picked on the device, ready to upload.
final class PhotoUpload {
  const new({required this.bytes, required this.extension});

  final Uint8List bytes;

  /// Lowercase, no dot. Detected from the bytes, not trusted from file names.
  final String extension;

  String get contentType => switch (extension) {
    'png' => 'image/png',
    'webp' => 'image/webp',
    _ => 'image/jpeg',
  };
}
