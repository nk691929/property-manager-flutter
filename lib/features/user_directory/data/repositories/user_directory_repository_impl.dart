import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/core/result/run_catching.dart';
import 'package:property_manager/features/user_directory/data/datasources/user_directory_data_source.dart';
import 'package:property_manager/features/user_directory/domain/repositories/user_directory_repository.dart';

final class UserDirectoryRepositoryImpl implements UserDirectoryRepository {
  const new(this._dataSource);

  final UserDirectoryDataSource _dataSource;

  @override
  Future<Result<Map<String, String>>> namesFor(Set<String> userIds) =>
      runCatching(() => _dataSource.fetchNames(userIds));
}
