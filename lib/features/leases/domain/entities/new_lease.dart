import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:property_manager/core/money/money.dart';

part 'new_lease.freezed.dart';

/// What an agent fills in to create a lease.
@freezed
abstract class NewLease with _$NewLease {
  const factory({
    required String propertyId,
    required String tenantId,
    required DateTime startDate,
    required DateTime endDate,
    required Money monthlyRent,
    required Money securityDeposit,
    required int dueDay,
  }) = _NewLease;
}
