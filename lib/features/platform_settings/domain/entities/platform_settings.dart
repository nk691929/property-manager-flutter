import 'package:freezed_annotation/freezed_annotation.dart';

part 'platform_settings.freezed.dart';

@freezed
abstract class PlatformSettings with _$PlatformSettings {
  const factory({required bool requireListingApproval}) = _PlatformSettings;
}
