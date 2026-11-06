import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/core/result/run_catching.dart';
import 'package:property_manager/features/favorites/data/datasources/favorites_data_source.dart';
import 'package:property_manager/features/favorites/domain/repositories/favorites_repository.dart';

final class FavoritesRepositoryImpl implements FavoritesRepository {
  const new(this._dataSource);

  final FavoritesDataSource _dataSource;

  @override
  Future<Result<List<String>>> listIds(String userId) =>
      runCatching(() => _dataSource.listIds(userId));

  @override
  Future<Result<void>> add(String userId, String propertyId) =>
      runCatching(() => _dataSource.add(userId, propertyId));

  @override
  Future<Result<void>> remove(String userId, String propertyId) =>
      runCatching(() => _dataSource.remove(userId, propertyId));
}
