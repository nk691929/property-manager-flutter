import 'package:property_manager/features/platform_settings/domain/entities/platform_settings.dart';

abstract interface class PlatformSettingsDataSource {
  Future<PlatformSettings> fetch();

  Future<PlatformSettings> setRequireListingApproval({required bool value});
}
