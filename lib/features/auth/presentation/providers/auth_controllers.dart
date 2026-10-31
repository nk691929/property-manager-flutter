import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/features/auth/domain/entities/sign_up_outcome.dart';
import 'package:property_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_controllers.g.dart';

@riverpod
class SignInController extends _$SignInController {
  @override
  FutureOr<void> build() {}

  Future<void> submit({required String email, required String password}) async {
    state = const AsyncLoading();
    final result = await ref.read(signInWithEmailProvider)(
      email: email,
      password: password,
    );
    // The page (and this autoDispose controller) may already be gone:
    // a successful sign-in redirects away before we get here.
    if (!ref.mounted) return;
    state = switch (result) {
      Ok() => const AsyncData(null),
      Err(:final failure) => AsyncError(failure, StackTrace.current),
    };
  }
}

@riverpod
class SignUpController extends _$SignUpController {
  @override
  FutureOr<SignUpOutcome?> build() => null;

  Future<void> submit({
    required String email,
    required String password,
    String? fullName,
  }) async {
    state = const AsyncLoading();
    final result = await ref.read(signUpWithEmailProvider)(
      email: email,
      password: password,
      fullName: fullName,
    );
    if (!ref.mounted) return;
    state = switch (result) {
      Ok(:final value) => AsyncData(value),
      Err(:final failure) => AsyncError(failure, StackTrace.current),
    };
  }
}
