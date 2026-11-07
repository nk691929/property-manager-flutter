import 'package:property_manager/features/leases/domain/entities/leasable_property.dart';
import 'package:property_manager/features/leases/domain/entities/lease.dart';
import 'package:property_manager/features/leases/domain/entities/new_lease.dart';

/// Backend seam. Implementations throw typed `Failure`s, never SDK exceptions.
abstract interface class LeasesDataSource {
  Future<List<Lease>> listForTenant(String tenantId, {required int limit});

  Future<List<Lease>> listForAgent(String agentId, {required int limit});

  Future<Lease> getById(String id);

  Future<List<String>> tenantCandidateIds(String propertyId);

  Future<List<LeasableProperty>> leasableProperties(String agentId);

  Future<Lease> create(NewLease draft);
}
