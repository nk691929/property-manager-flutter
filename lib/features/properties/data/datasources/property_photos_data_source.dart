import 'package:property_manager/features/properties/domain/entities/photo_upload.dart';
import 'package:property_manager/features/properties/domain/entities/property_photo.dart';

/// Implementations throw typed `Failure`s, never SDK exceptions.
abstract interface class PropertyPhotosDataSource {
  Future<PropertyPhoto> add(
    String propertyId,
    PhotoUpload upload, {
    required int position,
  });

  Future<void> remove(PropertyPhoto photo);

  Future<PropertyPhoto> setPosition(String photoId, int position);
}
