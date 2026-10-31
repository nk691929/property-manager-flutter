import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/features/admin_users/domain/repositories/admin_users_repository.dart';
import 'package:property_manager/features/auth/domain/current_user_reader.dart';
import 'package:property_manager/features/auth/domain/entities/app_user.dart';
import 'package:property_manager/features/auth/domain/entities/permission.dart';

final class ListUsers {
  const new(this._repository, this._currentUser);

  final AdminUsersRepository _repository;
  final CurrentUserReader _currentUser;

  Future<Result<List<AppUser>>> call() async {
    final actor = _currentUser();
    if (actor == null) return const Err(UnauthorizedFailure());
    if (!actor.can(Permission.manageUsers)) {
      return const Err(ForbiddenFailure());
    }
    return await _repository.listUsers();
  }
}
