import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:property_manager/app/theme/design_tokens.dart';
import 'package:property_manager/core/presentation/formatters.dart';
import 'package:property_manager/core/providers/core_providers.dart';
import 'package:property_manager/features/leases/domain/entities/lease.dart';
import 'package:property_manager/features/leases/presentation/widgets/lease_chips.dart';
import 'package:property_manager/features/user_directory/presentation/providers/user_directory_providers.dart';
import 'package:property_manager/l10n/l10n.dart';

class LeaseCard extends ConsumerWidget {
  const new({
    required this.lease,
    required this.isAgentView,
    required this.onTap,
    super.key,
  });

  final Lease lease;

  /// Agents see the tenant; tenants see the agent.
  final bool isAgentView;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final today = ref.watch(clockProvider)();
    final counterpartId = isAgentView ? lease.tenantId : lease.agentId;
    final name = counterpartId == null
        ? null
        : ref.watch(userNameProvider(counterpartId)).value;
    final counterpart = isAgentView
        ? l10n.leaseWithTenant(name ?? l10n.inquiryOtherClient)
        : l10n.leaseWithAgent(name ?? l10n.inquiryOtherAgent);

    final overdueCount = lease.overdueCharges(today).length;
    final next = lease.nextCharge(today);

    Widget? statusLine;
    if (!lease.isActive) {
      statusLine = Text(
        l10n.leaseEndedOn(formatDate(context, lease.endedOn ?? lease.endDate)),
      );
    } else if (overdueCount > 0) {
      statusLine = Text(
        l10n.leaseOverdueLine(
          overdueCount,
          formatMoney(context, lease.overdueAmount(today)),
        ),
        style: TextStyle(color: theme.colorScheme.error),
      );
    } else if (next != null) {
      statusLine = Text(
        l10n.leaseNextPayment(
          formatMoney(context, next.balance),
          formatDate(context, next.dueDate),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      lease.propertyTitle,
                      style: theme.textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  LeaseStatusChip(status: lease.status),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(counterpart),
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.pricePerMonth(formatMoney(context, lease.monthlyRent))),
              if (statusLine != null) ...[
                const SizedBox(height: AppSpacing.sm),
                statusLine,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
