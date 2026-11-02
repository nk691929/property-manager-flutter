import 'package:flutter/material.dart';
import 'package:property_manager/features/properties/domain/entities/property_enums.dart';
import 'package:property_manager/features/properties/presentation/extensions/property_labels.dart';
import 'package:property_manager/l10n/l10n.dart';

class PropertyStatusChip extends StatelessWidget {
  const new({required this.status, super.key});

  final PropertyStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (status) {
      PropertyStatus.published => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      PropertyStatus.pendingReview => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      PropertyStatus.rejected => (
        scheme.errorContainer,
        scheme.onErrorContainer,
      ),
      PropertyStatus.draft || PropertyStatus.archived => (
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
