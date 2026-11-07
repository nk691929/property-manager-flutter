import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/features/leases/domain/entities/leasable_property.dart';
import 'package:property_manager/features/leases/domain/entities/lease.dart';
import 'package:property_manager/features/leases/domain/entities/new_lease.dart';
import 'package:property_manager/features/leases/domain/entities/new_payment.dart';
import 'package:property_manager/features/leases/domain/entities/rent_payment.dart';

abstract interface class LeasesRepository {
  Future<Result<List<Lease>>> listForTenant(
    String tenantId, {
    required int limit,
  });

  /// Leases of listings this agent currently owns.
  Future<Result<List<Lease>>> listForAgent(
    String agentId, {
    required int limit,
  });

  Future<Result<Lease>> getById(String id);

  /// Clients who contacted the agent about this listing (an inquiry or a
  /// completed viewing): the only people a lease can be created for.
  Future<Result<List<String>>> tenantCandidateIds(String propertyId);

  /// The agent's rental listings that can take a new lease (published or
  /// archived, with no active lease yet).
  Future<Result<List<LeasableProperty>>> leasableProperties(String agentId);

  Future<Result<Lease>> create(NewLease draft);

  Future<Result<RentPayment>> recordPayment(NewPayment payment);

  Future<Result<RentPayment>> voidPayment(String paymentId, String reason);

  Future<Result<Lease>> endLease(String leaseId, DateTime endOn);
}
