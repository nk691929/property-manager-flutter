import 'package:property_manager/features/auth/data/models/profile_model.dart';

/// Backend seam. Implementations throw typed `Failure`s, never SDK exceptions.
abstract interface class AuthRemoteDataSource {
  /// Current user id (or null) immediately, then on every auth change.
  Stream<String?> userIdChanges();

  Future<ProfileModel> fetchProfile(String userId);

  Future<void> signInWithPassword({
    required String email,
    required String password,
  });

  /// Returns true when a session was created (no email confirmation needed).
  Future<bool> signUp({
    required String email,
    required String password,
    String? fullName,
  });

  Future<void> signOut();
}
