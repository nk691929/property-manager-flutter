import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/features/auth/domain/current_user_reader.dart';
import 'package:property_manager/features/properties/domain/entities/property_enums.dart';
import 'package:property_manager/features/properties/domain/property_access.dart';
import 'package:property_manager/features/properties/domain/repositories/properties_repository.dart';
import 'package:property_manager/features/properties/domain/repositories/property_photos_repository.dart';

/// Only drafts can be deleted; everything else is archived instead.
final class DeleteProperty {
  const new(this._repository, this._photos, this._currentUser);

  final PropertiesRepository _repository;
  final PropertyPhotosRepository _photos;
  final CurrentUserReader _currentUser;

  Future<Result<void>> call(String propertyId) async {
    final actor = _currentUser();
    if (actor == null) return const Err(UnauthorizedFailure());

    final loaded = await loadManageable(_repository, actor, propertyId);
    final property = loaded.valueOrNull;
    if (property == null) {
      return Err(loaded.failureOrNull ?? const UnknownFailure());
    }
    if (property.status != PropertyStatus.draft) {
      return const Err(ForbiddenFailure());
    }

    // Files first: after the property row is gone, storage policies can no
    // longer tell who owned the folder and would refuse the deletes.
    for (final photo in property.photos) {
      final removed = await _photos.remove(photo);
      if (!removed.isOk) return removed;
    }
    return await _repository.delete(propertyId);
  }
}
