import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:property_manager/core/config/flavor.dart';

part 'app_info.freezed.dart';

@freezed
abstract class AppInfo with _$AppInfo {
  const factory({
    required String appName,
    required String version,
    required String buildNumber,
    required Flavor flavor,
  }) = _AppInfo;
}
