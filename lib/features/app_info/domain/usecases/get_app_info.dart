import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/features/app_info/domain/entities/app_info.dart';
import 'package:property_manager/features/app_info/domain/repositories/app_info_repository.dart';

/// A pass-through today. It's here to establish the pattern: from MVP 1 on,
/// use cases are where permission checks and business rules live.
final class GetAppInfo {
  const new(this._repository);

  final AppInfoRepository _repository;

  Future<Result<AppInfo>> call() => _repository.getAppInfo();
}
