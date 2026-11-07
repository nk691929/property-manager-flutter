import 'package:property_manager/core/money/money.dart';
import 'package:property_manager/features/leases/domain/entities/lease.dart';
import 'package:property_manager/features/leases/domain/entities/lease_enums.dart';
import 'package:property_manager/features/leases/domain/entities/new_lease.dart';
import 'package:property_manager/features/leases/domain/entities/rent_charge.dart';
import 'package:property_manager/features/leases/domain/entities/rent_payment.dart';

Money pkr(int whole) => Money(whole * 100);

RentPayment samplePayment({
  required String id,
  required String chargeId,
  required int amount,
  bool voided = false,
}) => RentPayment(
  id: id,
  chargeId: chargeId,
  amount: pkr(amount),
  paidOn: DateTime(2027, 1, 2),
  method: PaymentMethod.cash,
  recordedBy: 'u-agent',
  createdAt: DateTime.utc(2027, 1, 2),
  voidedAt: voided ? DateTime.utc(2027, 1, 3) : null,
  voidReason: voided ? 'Entered twice' : null,
);

RentCharge sampleCharge({
  required String id,
  required DateTime dueDate,
  int amount = 50000,
  List<RentPayment> payments = const [],
  bool cancelled = false,
}) => RentCharge(
  id: id,
  leaseId: 'l-1',
  dueDate: dueDate,
  amount: pkr(amount),
  payments: payments,
  cancelledAt: cancelled ? DateTime.utc(2027, 2) : null,
);

Lease sampleLease({
  String id = 'l-1',
  String propertyId = 'p-2',
  String tenantId = 'u-client',
  String? agentId = 'u-agent',
  LeaseStatus status = LeaseStatus.active,
  List<RentCharge> charges = const [],
}) => Lease(
  id: id,
  propertyId: propertyId,
  propertyTitle: 'Two-Bedroom Apartment in Gulberg',
  tenantId: tenantId,
  startDate: DateTime(2027),
  endDate: DateTime(2027, 4, 30),
  monthlyRent: pkr(50000),
  securityDeposit: pkr(100000),
  dueDay: 1,
  status: status,
  createdAt: DateTime.utc(2026, 11, 6),
  agentId: agentId,
  charges: charges,
);

NewLease sampleNewLease({
  String propertyId = 'p-2',
  String tenantId = 'u-client',
  DateTime? start,
  DateTime? end,
  Money? rent,
  Money? deposit,
  int dueDay = 1,
}) => NewLease(
  propertyId: propertyId,
  tenantId: tenantId,
  startDate: start ?? DateTime(2027),
  endDate: end ?? DateTime(2027, 11, 30),
  monthlyRent: rent ?? pkr(50000),
  securityDeposit: deposit ?? pkr(100000),
  dueDay: dueDay,
);
