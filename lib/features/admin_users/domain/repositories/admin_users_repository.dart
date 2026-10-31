import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/features/auth/domain/entities/app_user.dart';
import 'package:property_manager/features/auth/domain/entities/role.dart';

abstract interface class AdminUsersRepository {
  Future<Result<List<AppUser>>> listUsers();

  Future<Result<AppUser>> changeRole({
    required String userId,
    required Role role,
  });
}
