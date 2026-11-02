import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/features/auth/domain/current_user_reader.dart';
import 'package:property_manager/features/properties/domain/entities/photo_upload.dart';
import 'package:property_manager/features/properties/domain/entities/property_photo.dart';
import 'package:property_manager/features/properties/domain/property_access.dart';
import 'package:property_manager/features/properties/domain/repositories/properties_repository.dart';
import 'package:property_manager/features/properties/domain/repositories/property_photos_repository.dart';
import 'package:property_manager/features/properties/domain/rules/photo_rules.dart';

final class AddPropertyPhoto {
  const new(this._properties, this._photos, this._currentUser);

  final PropertiesRepository _properties;
  final PropertyPhotosRepository _photos;
  final CurrentUserReader _currentUser;

  Future<Result<PropertyPhoto>> call(
    String propertyId,
    PhotoUpload upload,
  ) async {
    final actor = _currentUser();
    if (actor == null) return const Err(UnauthorizedFailure());

    final loaded = await loadPhotoEditable(_properties, actor, propertyId);
    final property = loaded.valueOrNull;
    if (property == null) {
      return Err(loaded.failureOrNull ?? const UnknownFailure());
    }

    final invalid = PhotoRules.validate(
      upload,
      existingCount: property.photos.length,
    );
    if (invalid != null) {
      return Err(ValidationFailure({'photo': invalid.name}));
    }

    return await _photos.add(
      propertyId,
      upload,
      position: PhotoRules.nextPosition(property.photos),
    );
  }
}
