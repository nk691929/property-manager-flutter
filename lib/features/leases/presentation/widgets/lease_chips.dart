import 'package:flutter/material.dart';
import 'package:property_manager/features/leases/domain/entities/lease_enums.dart';
import 'package:property_manager/features/leases/presentation/extensions/lease_texts.dart';
import 'package:property_manager/l10n/l10n.dart';

class LeaseStatusChip extends StatelessWidget {
  const new({required this.status, super.key});

  final LeaseStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (status) {
      LeaseStatus.active => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      LeaseStatus.ended => (
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
      ),
    };
    return Chip(
      label: Text(
        status.label(context.l10n),
        style: TextStyle(color: foreground),
      ),
      backgroundColor: background,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}

class ChargeStatusChip extends StatelessWidget {
  const new({required this.status, super.key});

  final ChargeStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (status) {
      ChargeStatus.paid => (scheme.primaryContainer, scheme.onPrimaryContainer),
      ChargeStatus.partlyPaid => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      ChargeStatus.overdue => (scheme.errorContainer, scheme.onErrorContainer),
      ChargeStatus.due || ChargeStatus.cancelled => (
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
      ),
    };
    // The text label carries the meaning; colour is only reinforcement.
    return Chip(
      label: Text(
        status.label(context.l10n),
        style: TextStyle(color: foreground),
      ),
      backgroundColor: background,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}
