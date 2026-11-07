import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/core/result/run_catching.dart';
import 'package:property_manager/features/leases/data/datasources/leases_data_source.dart';
import 'package:property_manager/features/leases/domain/entities/leasable_property.dart';
import 'package:property_manager/features/leases/domain/entities/lease.dart';
import 'package:property_manager/features/leases/domain/entities/new_lease.dart';
import 'package:property_manager/features/leases/domain/repositories/leases_repository.dart';

final class LeasesRepositoryImpl implements LeasesRepository {
  const new(this._dataSource);

  final LeasesDataSource _dataSource;

  @override
  Future<Result<List<Lease>>> listForTenant(
    String tenantId, {
    required int limit,
  }) => runCatching(() => _dataSource.listForTenant(tenantId, limit: limit));

  @override
  Future<Result<List<Lease>>> listForAgent(
    String agentId, {
    required int limit,
  }) => runCatching(() => _dataSource.listForAgent(agentId, limit: limit));

  @override
  Future<Result<Lease>> getById(String id) =>
      runCatching(() => _dataSource.getById(id));

  @override
  Future<Result<List<String>>> tenantCandidateIds(String propertyId) =>
      runCatching(() => _dataSource.tenantCandidateIds(propertyId));

  @override
  Future<Result<List<LeasableProperty>>> leasableProperties(String agentId) =>
      runCatching(() => _dataSource.leasableProperties(agentId));

  @override
  Future<Result<Lease>> create(NewLease draft) =>
      runCatching(() => _dataSource.create(draft));
}
