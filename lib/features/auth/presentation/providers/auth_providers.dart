import 'package:property_manager/core/providers/core_providers.dart';
import 'package:property_manager/core/providers/supabase_provider.dart';
import 'package:property_manager/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:property_manager/features/auth/data/datasources/fake_auth_data_source.dart';
import 'package:property_manager/features/auth/data/datasources/supabase_auth_data_source.dart';
import 'package:property_manager/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:property_manager/features/auth/domain/entities/app_user.dart';
import 'package:property_manager/features/auth/domain/repositories/auth_repository.dart';
import 'package:property_manager/features/auth/domain/usecases/observe_auth_state.dart';
import 'package:property_manager/features/auth/domain/usecases/sign_in_with_email.dart';
import 'package:property_manager/features/auth/domain/usecases/sign_out.dart';
import 'package:property_manager/features/auth/domain/usecases/sign_up_with_email.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_providers.g.dart';

// Composition root for auth: the one presentation file allowed to see data/.

@Riverpod(keepAlive: true)
AuthRemoteDataSource authRemoteDataSource(Ref ref) {
  final config = ref.watch(appConfigProvider);
  if (config.hasBackendConfig) {
    return SupabaseAuthDataSource(ref.watch(supabaseClientProvider));
  }
  final fake = FakeAuthDataSource.seeded();
  ref.onDispose(fake.dispose);
  return fake;
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) => AuthRepositoryImpl(
  dataSource: ref.watch(authRemoteDataSourceProvider),
  logger: ref.watch(appLoggerProvider),
);

@Riverpod(keepAlive: true)
SignInWithEmail signInWithEmail(Ref ref) =>
    SignInWithEmail(ref.watch(authRepositoryProvider));

@Riverpod(keepAlive: true)
SignUpWithEmail signUpWithEmail(Ref ref) =>
    SignUpWithEmail(ref.watch(authRepositoryProvider));

@Riverpod(keepAlive: true)
SignOut signOut(Ref ref) => SignOut(ref.watch(authRepositoryProvider));

@Riverpod(keepAlive: true)
ObserveAuthState observeAuthState(Ref ref) =>
    ObserveAuthState(ref.watch(authRepositoryProvider));

/// loading = restoring the session; data(null) = signed out.
@Riverpod(keepAlive: true)
Stream<AppUser?> authState(Ref ref) => ref.watch(observeAuthStateProvider)();

@Riverpod(keepAlive: true)
AppUser? currentUser(Ref ref) => ref.watch(authStateProvider).value;
