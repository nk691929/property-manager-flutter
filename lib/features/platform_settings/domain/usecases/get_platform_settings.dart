import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/features/auth/domain/current_user_reader.dart';
import 'package:property_manager/features/platform_settings/domain/entities/platform_settings.dart';
import 'package:property_manager/features/platform_settings/domain/repositories/platform_settings_repository.dart';

/// Any signed-in user may read the rules (agents need them to label buttons).
final class GetPlatformSettings {
  const new(this._repository, this._currentUser);

  final PlatformSettingsRepository _repository;
  final CurrentUserReader _currentUser;

  Future<Result<PlatformSettings>> call() async {
    if (_currentUser() == null) return const Err(UnauthorizedFailure());
    return await _repository.get();
  }
}
