import 'package:property_manager/core/providers/core_providers.dart';
import 'package:property_manager/core/providers/supabase_provider.dart';
import 'package:property_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:property_manager/features/user_directory/data/datasources/fake_user_directory_data_source.dart';
import 'package:property_manager/features/user_directory/data/datasources/supabase_user_directory_data_source.dart';
import 'package:property_manager/features/user_directory/data/datasources/user_directory_data_source.dart';
import 'package:property_manager/features/user_directory/data/repositories/user_directory_repository_impl.dart';
import 'package:property_manager/features/user_directory/domain/repositories/user_directory_repository.dart';
import 'package:property_manager/features/user_directory/domain/usecases/get_user_names.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_directory_providers.g.dart';

@Riverpod(keepAlive: true)
UserDirectoryDataSource userDirectoryDataSource(Ref ref) {
  final config = ref.watch(appConfigProvider);
  return config.hasBackendConfig
      ? SupabaseUserDirectoryDataSource(ref.watch(supabaseClientProvider))
      : const FakeUserDirectoryDataSource();
}

@Riverpod(keepAlive: true)
UserDirectoryRepository userDirectoryRepository(Ref ref) =>
    UserDirectoryRepositoryImpl(ref.watch(userDirectoryDataSourceProvider));

@riverpod
GetUserNames getUserNames(Ref ref) => GetUserNames(
  ref.watch(userDirectoryRepositoryProvider),
  () => ref.read(currentUserProvider),
);

/// Display name for one user, or null when unknown or hidden from the caller.
/// A missing name must never break a screen, so failures become null.
@riverpod
Future<String?> userName(Ref ref, String userId) async {
  final result = await ref.watch(getUserNamesProvider)({userId});
  return result.fold<String?>(
    onOk: (names) => names[userId],
    onErr: (_) => null,
  );
}
