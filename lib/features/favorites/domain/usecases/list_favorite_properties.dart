import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/features/auth/domain/current_user_reader.dart';
import 'package:property_manager/features/auth/domain/entities/permission.dart';
import 'package:property_manager/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:property_manager/features/properties/domain/entities/property.dart';
import 'package:property_manager/features/properties/domain/repositories/properties_repository.dart';

/// The Saved screen's data: saved ids (newest first), then the properties
/// behind them. Listings that were unpublished since are hidden by the
/// database and are therefore simply skipped.
final class ListFavoriteProperties {
  const new(this._favorites, this._properties, this._currentUser);

  final FavoritesRepository _favorites;
  final PropertiesRepository _properties;
  final CurrentUserReader _currentUser;

  Future<Result<List<Property>>> call() async {
    final actor = _currentUser();
    if (actor == null) return const Err(UnauthorizedFailure());
    if (!actor.can(Permission.favoriteProperties)) {
      return const Err(ForbiddenFailure());
    }

    final idsResult = await _favorites.listIds(actor.id);
    final ids = idsResult.valueOrNull;
    if (ids == null) {
      return Err(idsResult.failureOrNull ?? const UnknownFailure());
    }
    if (ids.isEmpty) return const Ok(<Property>[]);

    final loaded = await _properties.listByIds(ids);
    return loaded.map((items) {
      final byId = {for (final p in items) p.id: p};
      return [for (final id in ids) ?byId[id]];
    });
  }
}
