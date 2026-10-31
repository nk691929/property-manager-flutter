import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/features/admin_users/domain/repositories/admin_users_repository.dart';
import 'package:property_manager/features/auth/domain/current_user_reader.dart';
import 'package:property_manager/features/auth/domain/entities/app_user.dart';
import 'package:property_manager/features/auth/domain/entities/permission.dart';
import 'package:property_manager/features/auth/domain/entities/role.dart';

final class ChangeUserRole {
  const new(this._repository, this._currentUser);

  final AdminUsersRepository _repository;
  final CurrentUserReader _currentUser;

  Future<Result<AppUser>> call({
    required String userId,
    required Role role,
  }) async {
    final actor = _currentUser();
    if (actor == null) return const Err(UnauthorizedFailure());
    if (!actor.can(Permission.manageUsers)) {
      return const Err(ForbiddenFailure());
    }
    // Business rule: an admin can't change their own role, so the system
    // can't be left with no admin by accident.
    if (actor.id == userId) return const Err(ForbiddenFailure());
    return await _repository.changeRole(userId: userId, role: role);
  }
}
