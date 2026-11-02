import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/features/properties/data/datasources/property_photos_data_source.dart';
import 'package:property_manager/features/properties/domain/entities/photo_upload.dart';
import 'package:property_manager/features/properties/domain/entities/property_photo.dart';

final class UnsupportedPropertyPhotosDataSource
    implements PropertyPhotosDataSource {
  const new();

  @override
  Future<PropertyPhoto> add(
    String propertyId,
    PhotoUpload upload, {
    required int position,
  }) => Future.error(const UnknownFailure());

  @override
  Future<void> remove(PropertyPhoto photo) =>
      Future.error(const UnknownFailure());

  @override
  Future<PropertyPhoto> setPosition(String photoId, int position) =>
      Future.error(const UnknownFailure());
}
