import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/core/result/run_catching.dart';
import 'package:property_manager/features/properties/data/datasources/properties_data_source.dart';
import 'package:property_manager/features/properties/domain/entities/property.dart';
import 'package:property_manager/features/properties/domain/entities/property_draft.dart';
import 'package:property_manager/features/properties/domain/entities/property_enums.dart';
import 'package:property_manager/features/properties/domain/entities/property_filter.dart';
import 'package:property_manager/features/properties/domain/repositories/properties_repository.dart';

final class PropertiesRepositoryImpl implements PropertiesRepository {
  const new(this._dataSource);

  final PropertiesDataSource _dataSource;

  @override
  Future<Result<List<Property>>> searchPublished(
    PropertyFilter filter, {
    required int offset,
    required int limit,
  }) => runCatching(
    () => _dataSource.search(filter, offset: offset, limit: limit),
  );

  @override
  Future<Result<List<Property>>> listByAgent(
    String agentId, {
    required int offset,
    required int limit,
    PropertyStatus? status,
  }) => runCatching(
    () => _dataSource.listByAgent(
      agentId,
      offset: offset,
      limit: limit,
      status: status,
    ),
  );

  @override
  Future<Result<List<Property>>> listAll({
    required int offset,
    required int limit,
    PropertyStatus? status,
  }) => runCatching(
    () => _dataSource.listAll(offset: offset, limit: limit, status: status),
  );

  @override
  Future<Result<Property>> getById(String id) =>
      runCatching(() => _dataSource.getById(id));

  @override
  Future<Result<Property>> create(
    PropertyDraft draft, {
    required String agentId,
  }) => runCatching(() => _dataSource.create(draft, agentId));

  @override
  Future<Result<Property>> update(String id, PropertyDraft draft) =>
      runCatching(() => _dataSource.update(id, draft));

  @override
  Future<Result<Property>> setStatus(
    String id,
    PropertyStatus status, {
    String? rejectionReason,
  }) => runCatching(
    () => _dataSource.setStatus(id, status, rejectionReason: rejectionReason),
  );

  @override
  Future<Result<Property>> reassign(String id, String agentId) =>
      runCatching(() => _dataSource.reassign(id, agentId));

  @override
  Future<Result<void>> delete(String id) =>
      runCatching(() => _dataSource.delete(id));
}
