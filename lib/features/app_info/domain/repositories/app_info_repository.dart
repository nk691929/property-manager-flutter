import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/features/app_info/domain/entities/app_info.dart';

abstract interface class AppInfoRepository {
  Future<Result<AppInfo>> getAppInfo();
}
