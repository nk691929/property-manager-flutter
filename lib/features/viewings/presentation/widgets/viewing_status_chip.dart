import 'package:flutter/material.dart';
import 'package:property_manager/features/viewings/domain/entities/viewing_enums.dart';
import 'package:property_manager/features/viewings/presentation/extensions/viewing_texts.dart';
import 'package:property_manager/l10n/l10n.dart';

class ViewingStatusChip extends StatelessWidget {
  const new({required this.status, super.key});

  final ViewingStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (status) {
      ViewingStatus.confirmed => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      ViewingStatus.requested => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      ViewingStatus.declined => (
        scheme.errorContainer,
        scheme.onErrorContainer,
      ),
      ViewingStatus.cancelled || ViewingStatus.completed => (
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
