import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/features/auth/domain/current_user_reader.dart';
import 'package:property_manager/features/auth/domain/entities/permission.dart';
import 'package:property_manager/features/favorites/domain/repositories/favorites_repository.dart';

final class AddFavorite {
  const new(this._repository, this._currentUser);

  final FavoritesRepository _repository;
  final CurrentUserReader _currentUser;

  Future<Result<void>> call(String propertyId) async {
    final actor = _currentUser();
    if (actor == null) return const Err(UnauthorizedFailure());
    if (!actor.can(Permission.favoriteProperties)) {
      return const Err(ForbiddenFailure());
    }
    return await _repository.add(actor.id, propertyId);
  }
}
