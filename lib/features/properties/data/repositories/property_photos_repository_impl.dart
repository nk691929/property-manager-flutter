import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/core/result/run_catching.dart';
import 'package:property_manager/features/properties/data/datasources/property_photos_data_source.dart';
import 'package:property_manager/features/properties/domain/entities/photo_upload.dart';
import 'package:property_manager/features/properties/domain/entities/property_photo.dart';
import 'package:property_manager/features/properties/domain/repositories/property_photos_repository.dart';

final class PropertyPhotosRepositoryImpl implements PropertyPhotosRepository {
  const new(this._dataSource);

  final PropertyPhotosDataSource _dataSource;

  @override
  Future<Result<PropertyPhoto>> add(
    String propertyId,
    PhotoUpload upload, {
    required int position,
  }) => runCatching(
    () => _dataSource.add(propertyId, upload, position: position),
  );

  @override
  Future<Result<void>> remove(PropertyPhoto photo) =>
      runCatching(() => _dataSource.remove(photo));

  @override
  Future<Result<PropertyPhoto>> setPosition(String photoId, int position) =>
      runCatching(() => _dataSource.setPosition(photoId, position));
}
