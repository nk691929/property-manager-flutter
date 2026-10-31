import 'package:property_manager/core/backend/supabase_failure_mapper.dart';
import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:property_manager/features/auth/data/models/profile_model.dart';
import 'package:property_manager/features/auth/domain/validators/auth_validators.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final class SupabaseAuthDataSource implements AuthRemoteDataSource {
  const new(this._client);

  final SupabaseClient _client;

  @override
  Stream<String?> userIdChanges() async* {
    // Emit the restored session first so we never depend on replay behavior.
    yield _client.auth.currentSession?.user.id;
    yield* _client.auth.onAuthStateChange.map(
      (state) => state.session?.user.id,
    );
  }

  @override
  Future<ProfileModel> fetchProfile(String userId) => supabaseGuard(() async {
    final json = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return ProfileModel.fromJson(json);
  });

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) => supabaseGuard(
    () => _client.auth.signInWithPassword(email: email, password: password),
    customMapper: _mapAuthError,
  );

  @override
  Future<bool> signUp({
    required String email,
    required String password,
    String? fullName,
  }) => supabaseGuard(() async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: fullName == null ? null : {'full_name': fullName},
    );
    return response.session != null;
  }, customMapper: _mapAuthError);

  @override
  Future<void> signOut() => supabaseGuard(_client.auth.signOut);
}

Failure? _mapAuthError(Object error, StackTrace stackTrace) {
  if (error is! AuthException) return null;
  return switch (error.code) {
    'user_already_exists' || 'email_exists' => ValidationFailure(
      {'email': FieldError.emailTaken.name},
      cause: error,
      stackTrace: stackTrace,
    ),
    'weak_password' => ValidationFailure(
      {'password': FieldError.weakPassword.name},
      cause: error,
      stackTrace: stackTrace,
    ),
    _ => null,
  };
}
