import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:property_manager/features/auth/domain/entities/permission.dart';
import 'package:property_manager/features/auth/domain/entities/role.dart';
import 'package:property_manager/features/auth/domain/entities/role_permissions.dart';

part 'app_user.freezed.dart';

@freezed
abstract class AppUser with _$AppUser {
  const factory({
    required String id,
    required String email,
    required Role role,
    String? fullName,
  }) = _AppUser;
  const new _();

  bool can(Permission permission) => permissionsFor(role).contains(permission);

  String get displayName {
    final name = fullName?.trim();
    return (name == null || name.isEmpty) ? email : name;
  }
}
