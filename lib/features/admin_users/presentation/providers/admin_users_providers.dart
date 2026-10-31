import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/providers/core_providers.dart';
import 'package:property_manager/core/providers/supabase_provider.dart';
import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/features/admin_users/data/datasources/admin_users_data_source.dart';
import 'package:property_manager/features/admin_users/data/datasources/fake_admin_users_data_source.dart';
import 'package:property_manager/features/admin_users/data/datasources/supabase_admin_users_data_source.dart';
import 'package:property_manager/features/admin_users/data/repositories/admin_users_repository_impl.dart';
import 'package:property_manager/features/admin_users/domain/repositories/admin_users_repository.dart';
import 'package:property_manager/features/admin_users/domain/usecases/change_user_role.dart';
import 'package:property_manager/features/admin_users/domain/usecases/list_users.dart';
import 'package:property_manager/features/auth/domain/entities/app_user.dart';
import 'package:property_manager/features/auth/domain/entities/role.dart';
import 'package:property_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'admin_users_providers.g.dart';

@Riverpod(keepAlive: true)
AdminUsersDataSource adminUsersDataSource(Ref ref) {
  final config = ref.watch(appConfigProvider);
  return config.hasBackendConfig
      ? SupabaseAdminUsersDataSource(ref.watch(supabaseClientProvider))
      : FakeAdminUsersDataSource();
}

@Riverpod(keepAlive: true)
AdminUsersRepository adminUsersRepository(Ref ref) =>
    AdminUsersRepositoryImpl(ref.watch(adminUsersDataSourceProvider));

@riverpod
ListUsers listUsers(Ref ref) => ListUsers(
  ref.watch(adminUsersRepositoryProvider),
  () => ref.read(currentUserProvider),
);

@riverpod
ChangeUserRole changeUserRole(Ref ref) => ChangeUserRole(
  ref.watch(adminUsersRepositoryProvider),
  () => ref.read(currentUserProvider),
);

@riverpod
class AdminUsers extends _$AdminUsers {
  @override
  Future<List<AppUser>> build() async {
    final result = await ref.watch(listUsersProvider)();
    return result.fold<List<AppUser>>(
      onOk: (users) => users,
      onErr: (failure) => throw failure,
    );
  }

  /// Returns null on success, or the failure to show.
  Future<Failure?> changeRole(AppUser user, Role role) async {
    final result = await ref.read(changeUserRoleProvider)(
      userId: user.id,
      role: role,
    );
    if (!ref.mounted) return null;
    switch (result) {
      case Ok(:final value):
        final current = state.value ?? const <AppUser>[];
        state = AsyncData([
          for (final u in current)
            if (u.id == value.id) value else u,
        ]);
        return null;
      case Err(:final failure):
        return failure;
    }
  }
}
