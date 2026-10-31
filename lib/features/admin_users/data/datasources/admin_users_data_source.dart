import 'package:property_manager/features/auth/data/models/profile_model.dart';
import 'package:property_manager/features/auth/domain/entities/role.dart';

abstract interface class AdminUsersDataSource {
  Future<List<ProfileModel>> listProfiles();

  Future<ProfileModel> updateRole(String userId, Role role);
}
