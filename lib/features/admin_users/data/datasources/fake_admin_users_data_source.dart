import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/features/admin_users/data/datasources/admin_users_data_source.dart';
import 'package:property_manager/features/auth/data/datasources/fake_auth_data_source.dart';
import 'package:property_manager/features/auth/data/models/profile_model.dart';
import 'package:property_manager/features/auth/domain/entities/role.dart';

/// Independent from the fake auth state (fallback mode only).
final class FakeAdminUsersDataSource implements AdminUsersDataSource {
  new()
    : _profiles = [
        for (final a in fakeAccounts)
          ProfileModel(
            id: a.id,
            email: a.email,
            fullName: a.fullName,
            role: a.role,
          ),
      ];

  final List<ProfileModel> _profiles;

  @override
  Future<List<ProfileModel>> listProfiles() async => List.of(_profiles);

  @override
  Future<ProfileModel> updateRole(String userId, Role role) async {
    final index = _profiles.indexWhere((p) => p.id == userId);
    if (index < 0) throw const NotFoundFailure();
    final old = _profiles[index];
    final updated = ProfileModel(
      id: old.id,
      email: old.email,
      fullName: old.fullName,
      role: role,
    );
    _profiles[index] = updated;
    return updated;
  }
}
