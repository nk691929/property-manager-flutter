import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/features/auth/domain/current_user_reader.dart';
import 'package:property_manager/features/properties/domain/property_access.dart';
import 'package:property_manager/features/properties/domain/repositories/properties_repository.dart';
import 'package:property_manager/features/properties/domain/repositories/property_photos_repository.dart';

final class RemovePropertyPhoto {
  const new(this._properties, this._photos, this._currentUser);

  final PropertiesRepository _properties;
  final PropertyPhotosRepository _photos;
  final CurrentUserReader _currentUser;

  Future<Result<void>> call(String propertyId, String photoId) async {
    final actor = _currentUser();
    if (actor == null) return const Err(UnauthorizedFailure());

    final loaded = await loadPhotoEditable(_properties, actor, propertyId);
    final property = loaded.valueOrNull;
    if (property == null) {
      return Err(loaded.failureOrNull ?? const UnknownFailure());
    }

    final photo = property.photos.where((p) => p.id == photoId).firstOrNull;
    if (photo == null) return const Err(NotFoundFailure());
    return await _photos.remove(photo);
  }
}
