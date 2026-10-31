import 'package:property_manager/core/logging/app_logger.dart';
import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/core/result/run_catching.dart';
import 'package:property_manager/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:property_manager/features/auth/domain/entities/app_user.dart';
import 'package:property_manager/features/auth/domain/entities/sign_up_outcome.dart';
import 'package:property_manager/features/auth/domain/repositories/auth_repository.dart';

final class AuthRepositoryImpl implements AuthRepository {
  const new({required this._dataSource, required this._logger});

  final AuthRemoteDataSource _dataSource;
  final AppLogger _logger;

  @override
  Stream<AppUser?> authStateChanges() =>
      _dataSource.userIdChanges().distinct().asyncMap(_loadUser);

  Future<AppUser?> _loadUser(String? userId) async {
    if (userId == null) return null;
    try {
      return (await _dataSource.fetchProfile(userId)).toEntity();
    } on Object catch (error, stackTrace) {
      // Known limitation (MVP 1): a failed profile load looks signed-out.
      _logger.warning(
        'Could not load profile for $userId',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  @override
  Future<Result<void>> signIn({
    required String email,
    required String password,
  }) => runCatching(
    () => _dataSource.signInWithPassword(email: email, password: password),
  );

  @override
  Future<Result<SignUpOutcome>> signUp({
    required String email,
    required String password,
    String? fullName,
  }) => runCatching(() async {
    final signedIn = await _dataSource.signUp(
      email: email,
      password: password,
      fullName: fullName,
    );
    return signedIn
        ? SignUpOutcome.signedIn
        : SignUpOutcome.confirmationRequired;
  });

  @override
  Future<Result<void>> signOut() => runCatching(_dataSource.signOut);
}
