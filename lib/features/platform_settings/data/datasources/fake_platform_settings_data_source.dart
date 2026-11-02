import 'package:property_manager/features/platform_settings/data/datasources/platform_settings_data_source.dart';
import 'package:property_manager/features/platform_settings/domain/entities/platform_settings.dart';

final class FakePlatformSettingsDataSource
    implements PlatformSettingsDataSource {
  new({bool requireListingApproval = true})
    : _approval = requireListingApproval;

  bool _approval;

  @override
  Future<PlatformSettings> fetch() async =>
      PlatformSettings(requireListingApproval: _approval);

  @override
  Future<PlatformSettings> setRequireListingApproval({
    required bool value,
  }) async {
    _approval = value;
    return PlatformSettings(requireListingApproval: _approval);
  }
}
