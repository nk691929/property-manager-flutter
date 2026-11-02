import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/features/platform_settings/domain/entities/platform_settings.dart';

abstract interface class PlatformSettingsRepository {
  Future<Result<PlatformSettings>> get();

  Future<Result<PlatformSettings>> setRequireListingApproval({
    required bool value,
  });
}
