import 'package:freezed_annotation/freezed_annotation.dart';

part 'property_photo.freezed.dart';

@freezed
abstract class PropertyPhoto with _$PropertyPhoto {
  const factory({
    required String id,

    /// Storage path, `<propertyId>/<file>`. Also the image cache key.
    required String path,

    /// Ready-to-load address, built by the data layer.
    required String url,
    required int position,
  }) = _PropertyPhoto;
}
