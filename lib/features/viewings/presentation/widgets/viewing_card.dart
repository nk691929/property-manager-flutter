import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:property_manager/app/theme/design_tokens.dart';
import 'package:property_manager/features/user_directory/presentation/providers/user_directory_providers.dart';
import 'package:property_manager/features/viewings/domain/entities/viewing.dart';
import 'package:property_manager/features/viewings/domain/entities/viewing_enums.dart';
import 'package:property_manager/features/viewings/presentation/extensions/viewing_format.dart';
import 'package:property_manager/features/viewings/presentation/extensions/viewing_texts.dart';
import 'package:property_manager/features/viewings/presentation/widgets/viewing_status_chip.dart';
import 'package:property_manager/l10n/l10n.dart';

class ViewingCard extends ConsumerWidget {
  const new({
    required this.viewing,
    required this.counterpartId,
    required this.counterpartFallback,
    required this.actions,
    required this.onAction,
    super.key,
  });

  final Viewing viewing;

  /// The other person: the agent for a client, the client for an agent.
  final String? counterpartId;
  final String counterpartFallback;

  /// Moves the rules allow right now (chosen by `ViewingWorkflow`).
  final List<ViewingStatus> actions;
  final ValueChanged<ViewingStatus> onAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final id = counterpartId;
    final name = id == null ? null : ref.watch(userNameProvider(id)).value;
    final reason = viewing.declineReason;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    viewing.propertyTitle,
                    style: theme.textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ViewingStatusChip(status: viewing.status),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(Icons.event_outlined, size: 18),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(formatViewingTime(context, viewing.scheduledAt)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 18),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(l10n.viewingWith(name ?? counterpartFallback)),
                ),
              ],
            ),
            if (reason != null && reason.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.viewingDeclineReasonShown(reason),
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
            if (actions.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final to in actions)
                    TextButton(
                      onPressed: () => onAction(to),
                      child: Text(viewingActionLabel(to, l10n)),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
