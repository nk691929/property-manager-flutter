import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:property_manager/app/theme/design_tokens.dart';
import 'package:property_manager/core/presentation/formatters.dart';
import 'package:property_manager/core/providers/core_providers.dart';
import 'package:property_manager/core/time/calendar.dart';
import 'package:property_manager/features/leases/domain/entities/lease.dart';
import 'package:property_manager/features/leases/domain/rules/lease_ending.dart';
import 'package:property_manager/l10n/l10n.dart';

/// Picks the end date and shows what will be cancelled. Returns the date, or
/// null if cancelled.
Future<DateTime?> showEndLeaseDialog(BuildContext context, Lease lease) =>
    showDialog<DateTime>(
      context: context,
      builder: (_) => _EndLeaseDialog(lease: lease),
    );

class _EndLeaseDialog extends ConsumerStatefulWidget {
  const new({required this.lease});

  final Lease lease;

  @override
  ConsumerState<_EndLeaseDialog> createState() => _EndLeaseDialogState();
}

class _EndLeaseDialogState extends ConsumerState<_EndLeaseDialog> {
  late DateTime _endOn;

  @override
  void initState() {
    super.initState();
    final today = Calendar.dateOnly(ref.read(clockProvider)());
    // Never before the lease started, never after it was due to finish.
    final start = widget.lease.startDate;
    final end = widget.lease.endDate;
    _endOn = today.isBefore(start) ? start : (today.isAfter(end) ? end : today);
  }

  Future<void> _pick() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endOn,
      firstDate: widget.lease.startDate,
      lastDate: widget.lease.endDate,
    );
    if (picked == null || !mounted) return;
    setState(() => _endOn = Calendar.dateOnly(picked));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cancelled = LeaseEnding.chargesToCancel(
      widget.lease,
      _endOn,
    ).toList();

    return AlertDialog(
      title: Text(l10n.leaseEndTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.leaseEndBody),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: _pick,
            icon: const Icon(Icons.event_outlined),
            label: Text(l10n.leaseEndDate(formatDate(context, _endOn))),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            cancelled.isEmpty
                ? l10n.leaseEndNothingCancelled
                : l10n.leaseEndCancels(cancelled.length),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_endOn),
          child: Text(l10n.leaseEndAction),
        ),
      ],
    );
  }
}
