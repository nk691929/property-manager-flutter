import 'package:property_manager/features/auth/domain/entities/app_user.dart';
import 'package:property_manager/features/auth/domain/entities/role.dart';

/// Row of `public.profiles`. Shared with admin_users (see ADR-009).
final class ProfileModel {
  const new({
    required this.id,
    required this.email,
    required this.role,
    this.fullName,
  });

  factory fromJson(Map<String, dynamic> json) => ProfileModel(
    id: json['id'] as String,
    email: json['email'] as String,
    fullName: json['full_name'] as String?,
    role: Role.fromWire(json['role'] as String),
  );

  final String id;
  final String email;
  final String? fullName;
  final Role role;

  AppUser toEntity() =>
      AppUser(id: id, email: email, fullName: fullName, role: role);
}
