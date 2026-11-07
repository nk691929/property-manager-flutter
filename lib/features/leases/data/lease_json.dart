import 'package:property_manager/core/money/money.dart';
import 'package:property_manager/core/time/calendar.dart';
import 'package:property_manager/features/leases/domain/entities/lease.dart';
import 'package:property_manager/features/leases/domain/entities/lease_enums.dart';
import 'package:property_manager/features/leases/domain/entities/rent_charge.dart';
import 'package:property_manager/features/leases/domain/entities/rent_payment.dart';

/// Lease, the listing's current agent, and the whole schedule with payments,
/// in one request (resource embedding).
const leaseSelect =
    '*, properties(agent_id), rent_charges(*, rent_payments(*))';

/// Same, as an inner join so filters on the embedded property drop rows.
const leaseSelectInner =
    '*, properties!inner(agent_id), rent_charges(*, rent_payments(*))';

RentPayment paymentFromJson(Map<String, dynamic> json, String currency) =>
    RentPayment(
      id: json['id'] as String,
      chargeId: json['charge_id'] as String,
      amount: Money.parse(json['amount'], currency: currency),
      paidOn: Calendar.parse(json['paid_on'] as String),
      method: PaymentMethod.fromWire(json['method'] as String),
      reference: json['reference'] as String?,
      recordedBy: json['recorded_by'] as String,
      voidedAt: json['voided_at'] == null
          ? null
          : DateTime.parse(json['voided_at'] as String),
      voidReason: json['void_reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

RentCharge chargeFromJson(Map<String, dynamic> json, String currency) {
  final rawPayments = json['rent_payments'] as List<dynamic>? ?? const [];
  final payments =
      [
        for (final raw in rawPayments)
          paymentFromJson(raw as Map<String, dynamic>, currency),
      ]..sort((a, b) {
        final byTime = a.createdAt.compareTo(b.createdAt);
        return byTime != 0 ? byTime : a.id.compareTo(b.id);
      });

  return RentCharge(
    id: json['id'] as String,
    leaseId: json['lease_id'] as String,
    dueDate: Calendar.parse(json['due_date'] as String),
    amount: Money.parse(json['amount'], currency: currency),
    cancelledAt: json['cancelled_at'] == null
        ? null
        : DateTime.parse(json['cancelled_at'] as String),
    payments: payments,
  );
}

Lease leaseFromJson(Map<String, dynamic> json) {
  final currency = json['currency'] as String? ?? 'PKR';
  final property = json['properties'];
  final rawCharges = json['rent_charges'] as List<dynamic>? ?? const [];
  final charges = [
    for (final raw in rawCharges)
      chargeFromJson(raw as Map<String, dynamic>, currency),
  ]..sort((a, b) => a.dueDate.compareTo(b.dueDate));

  return Lease(
    id: json['id'] as String,
    propertyId: json['property_id'] as String,
    propertyTitle: json['property_title'] as String,
    tenantId: json['tenant_id'] as String,
    startDate: Calendar.parse(json['start_date'] as String),
    endDate: Calendar.parse(json['end_date'] as String),
    monthlyRent: Money.parse(json['monthly_rent'], currency: currency),
    securityDeposit: Money.parse(json['security_deposit'], currency: currency),
    dueDay: json['due_day'] as int,
    status: LeaseStatus.fromWire(json['status'] as String),
    endedOn: json['ended_on'] == null
        ? null
        : Calendar.parse(json['ended_on'] as String),
    createdAt: DateTime.parse(json['created_at'] as String),
    agentId: property is Map<String, dynamic>
        ? property['agent_id'] as String?
        : null,
    charges: charges,
  );
}
