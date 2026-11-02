import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/features/properties/domain/entities/photo_upload.dart';
import 'package:property_manager/features/properties/domain/entities/property_photo.dart';

abstract interface class PropertyPhotosRepository {
  Future<Result<PropertyPhoto>> add(
    String propertyId,
    PhotoUpload upload, {
    required int position,
  });

  Future<Result<void>> remove(PropertyPhoto photo);

  Future<Result<PropertyPhoto>> setPosition(String photoId, int position);
}
