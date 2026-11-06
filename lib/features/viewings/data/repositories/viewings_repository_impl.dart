import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/core/result/run_catching.dart';
import 'package:property_manager/features/viewings/data/datasources/viewings_data_source.dart';
import 'package:property_manager/features/viewings/domain/entities/viewing.dart';
import 'package:property_manager/features/viewings/domain/entities/viewing_enums.dart';
import 'package:property_manager/features/viewings/domain/repositories/viewings_repository.dart';

final class ViewingsRepositoryImpl implements ViewingsRepository {
  const new(this._dataSource);

  final ViewingsDataSource _dataSource;

  @override
  Future<Result<List<Viewing>>> listForClient(
    String clientId, {
    required int limit,
  }) => runCatching(() => _dataSource.listForClient(clientId, limit: limit));

  @override
  Future<Result<List<Viewing>>> listForAgent(
    String agentId, {
    required int limit,
  }) => runCatching(() => _dataSource.listForAgent(agentId, limit: limit));

  @override
  Future<Result<Viewing>> getById(String id) =>
      runCatching(() => _dataSource.getById(id));

  @override
  Future<Result<Viewing?>> findActive(String clientId, String propertyId) =>
      runCatching(() => _dataSource.findActive(clientId, propertyId));

  @override
  Future<Result<Viewing>> request({
    required String propertyId,
    required String clientId,
    required DateTime scheduledAt,
  }) => runCatching(
    () => _dataSource.request(
      propertyId: propertyId,
      clientId: clientId,
      scheduledAt: scheduledAt,
    ),
  );

  @override
  Future<Result<Viewing>> setStatus(
    String id,
    ViewingStatus status, {
    String? declineReason,
  }) => runCatching(
    () => _dataSource.setStatus(id, status, declineReason: declineReason),
  );
}
