import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/features/auth/domain/current_user_reader.dart';
import 'package:property_manager/features/auth/domain/entities/permission.dart';
import 'package:property_manager/features/viewings/domain/entities/viewing.dart';
import 'package:property_manager/features/viewings/domain/repositories/viewings_repository.dart';

/// Lets the detail screen say "Your viewing" instead of "Request viewing".
final class FindActiveViewing {
  const new(this._repository, this._currentUser);

  final ViewingsRepository _repository;
  final CurrentUserReader _currentUser;

  Future<Result<Viewing?>> call(String propertyId) async {
    final actor = _currentUser();
    if (actor == null) return const Err(UnauthorizedFailure());
    if (!actor.can(Permission.requestViewings)) {
      return const Err(ForbiddenFailure());
    }
    return await _repository.findActive(actor.id, propertyId);
  }
}
