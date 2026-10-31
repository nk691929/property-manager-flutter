import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/features/auth/domain/entities/app_user.dart';
import 'package:property_manager/features/auth/domain/entities/sign_up_outcome.dart';

abstract interface class AuthRepository {
  /// Emits the signed-in user (with role), or null when signed out.
  Stream<AppUser?> authStateChanges();

  Future<Result<void>> signIn({
    required String email,
    required String password,
  });

  Future<Result<SignUpOutcome>> signUp({
    required String email,
    required String password,
    String? fullName,
  });

  Future<Result<void>> signOut();
}
