import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:property_manager/app/theme/design_tokens.dart';
import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/presentation/formatters.dart';
import 'package:property_manager/core/presentation/widgets/error_view.dart';
import 'package:property_manager/core/providers/core_providers.dart';
import 'package:property_manager/features/auth/domain/entities/permission.dart';
import 'package:property_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:property_manager/features/leases/domain/entities/lease.dart';
import 'package:property_manager/features/leases/domain/entities/lease_enums.dart';
import 'package:property_manager/features/leases/domain/entities/rent_charge.dart';
import 'package:property_manager/features/leases/domain/entities/rent_payment.dart';
import 'package:property_manager/features/leases/presentation/extensions/lease_texts.dart';
import 'package:property_manager/features/leases/presentation/providers/leases_providers.dart';
import 'package:property_manager/features/leases/presentation/widgets/lease_chips.dart';
import 'package:property_manager/features/user_directory/presentation/providers/user_directory_providers.dart';
import 'package:property_manager/l10n/l10n.dart';

/// One lease with its rent schedule. Read-only in this slice.
class LeaseDetailPage extends ConsumerWidget {
  const new({required this.leaseId, super.key});

  final String leaseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final detail = ref.watch(leaseDetailProvider(leaseId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.leaseDetailTitle)),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          failure: toFailure(error),
          onRetry: () => ref.invalidate(leaseDetailProvider(leaseId)),
        ),
        data: (lease) => RefreshIndicator(
          onRefresh: () async {
            ref
              ..invalidate(leaseDetailProvider(leaseId))
              ..invalidate(leaseListProvider);
            await ref.read(leaseDetailProvider(leaseId).future);
          },
          child: _LeaseBody(lease: lease),
        ),
      ),
    );
  }
}

class _LeaseBody extends ConsumerWidget {
  const new({required this.lease});

  final Lease lease;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final today = ref.watch(clockProvider)();
    final isAgent =
        ref.watch(currentUserProvider)?.can(Permission.manageLeases) ?? false;
    final counterpartId = isAgent ? lease.tenantId : lease.agentId;
    final name = counterpartId == null
        ? null
        : ref.watch(userNameProvider(counterpartId)).value;
    final counterpart = isAgent
        ? l10n.leaseWithTenant(name ?? l10n.inquiryOtherClient)
        : l10n.leaseWithAgent(name ?? l10n.inquiryOtherAgent);
    final overdue = lease.overdueAmount(today);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                lease.propertyTitle,
                style: theme.textTheme.titleLarge,
              ),
            ),
            LeaseStatusChip(status: lease.status),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(counterpart),
        Text(
          l10n.leasePeriod(
            formatDate(context, lease.startDate),
            formatDate(context, lease.endDate),
          ),
        ),
        Text(l10n.pricePerMonth(formatMoney(context, lease.monthlyRent))),
        Text(l10n.leaseDueDay(lease.dueDay)),
        Text(l10n.leaseDeposit(formatMoney(context, lease.securityDeposit))),
        if (!lease.isActive)
          Text(
            l10n.leaseEndedOn(
              formatDate(context, lease.endedOn ?? lease.endDate),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            _Figure(
              label: l10n.leaseSummaryPaid,
              value: formatMoney(context, lease.totalPaid),
            ),
            _Figure(
              label: l10n.leaseSummaryOutstanding,
              value: formatMoney(context, lease.outstanding),
            ),
            _Figure(
              label: l10n.leaseSummaryOverdue,
              value: formatMoney(context, overdue),
              emphasize: overdue.isPositive,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(l10n.leaseScheduleTitle, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        if (lease.charges.isEmpty)
          Text(l10n.leaseNoCharges)
        else
          for (final charge in lease.charges)
            _ChargeTile(charge: charge, today: today),
      ],
    );
  }
}

class _Figure extends StatelessWidget {
  const new({required this.label, required this.value, this.emphasize = false});

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelSmall),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              color: emphasize ? theme.colorScheme.error : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChargeTile extends StatelessWidget {
  const new({required this.charge, required this.today});

  final RentCharge charge;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final status = charge.statusOn(today);
    final showProgress = charge.paid.isPositive && status != ChargeStatus.paid;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    formatDate(context, charge.dueDate),
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                ChargeStatusChip(status: status),
              ],
            ),
            Text(formatMoney(context, charge.amount)),
            if (showProgress)
              Text(
                l10n.chargePaidOf(
                  formatMoney(context, charge.paid),
                  formatMoney(context, charge.amount),
                ),
              ),
            for (final payment in charge.payments)
              _PaymentLine(payment: payment),
          ],
        ),
      ),
    );
  }
}

class _PaymentLine extends StatelessWidget {
  const new({required this.payment});

  final RentPayment payment;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final reference = payment.reference;
    final style = payment.isVoid
        ? TextStyle(color: muted, decoration: TextDecoration.lineThrough)
        : TextStyle(color: muted);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.paymentLine(
              formatMoney(context, payment.amount),
              formatDate(context, payment.paidOn),
              payment.method.label(l10n),
            ),
            style: style,
          ),
          if (reference != null && reference.isNotEmpty)
            Text(l10n.paymentReference(reference), style: style),
          if (payment.isVoid)
            Text(
              l10n.paymentVoided(payment.voidReason ?? ''),
              style: TextStyle(color: theme.colorScheme.error),
            ),
        ],
      ),
    );
  }
}
