import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/core/result/run_catching.dart';
import 'package:property_manager/features/admin_users/data/datasources/admin_users_data_source.dart';
import 'package:property_manager/features/admin_users/domain/repositories/admin_users_repository.dart';
import 'package:property_manager/features/auth/domain/entities/app_user.dart';
import 'package:property_manager/features/auth/domain/entities/role.dart';

final class AdminUsersRepositoryImpl implements AdminUsersRepository {
  const new(this._dataSource);

  final AdminUsersDataSource _dataSource;

  @override
  Future<Result<List<AppUser>>> listUsers() => runCatching(() async {
    final profiles = await _dataSource.listProfiles();
    return profiles.map((p) => p.toEntity()).toList();
  });

  @override
  Future<Result<AppUser>> changeRole({
    required String userId,
    required Role role,
  }) => runCatching(() async {
    final profile = await _dataSource.updateRole(userId, role);
    return profile.toEntity();
  });
}
