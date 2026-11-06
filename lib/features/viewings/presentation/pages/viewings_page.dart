import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:property_manager/app/theme/design_tokens.dart';
import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/presentation/widgets/error_view.dart';
import 'package:property_manager/features/auth/domain/entities/permission.dart';
import 'package:property_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:property_manager/features/viewings/domain/entities/viewing.dart';
import 'package:property_manager/features/viewings/domain/entities/viewing_enums.dart';
import 'package:property_manager/features/viewings/domain/rules/viewing_rules.dart';
import 'package:property_manager/features/viewings/domain/rules/viewing_workflow.dart';
import 'package:property_manager/features/viewings/presentation/extensions/viewing_texts.dart';
import 'package:property_manager/features/viewings/presentation/providers/viewings_providers.dart';
import 'package:property_manager/features/viewings/presentation/widgets/viewing_card.dart';
import 'package:property_manager/l10n/l10n.dart';

/// Shared by clients ("my viewings") and agents (the requests queue).
class ViewingsPage extends ConsumerWidget {
  const new({super.key});

  Future<void> _onAction(
    BuildContext context,
    WidgetRef ref,
    Viewing viewing,
    ViewingStatus to,
  ) async {
    final l10n = context.l10n;
    String? reason;

    if (to == ViewingStatus.declined) {
      reason = await showDialog<String>(
        context: context,
        builder: (_) => const _DeclineDialog(),
      );
      if (reason == null) return;
    } else if (to == ViewingStatus.cancelled) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.viewingCancelTitle),
          content: Text(l10n.viewingCancelBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.viewingKeep),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.viewingActionCancel),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    final failure = await ref
        .read(viewingActionsProvider.notifier)
        .changeStatus(viewing.id, to, declineReason: reason);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          failure == null
              ? l10n.viewingUpdated
              : viewingFailureMessage(failure, l10n),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final board = ref.watch(viewingBoardProvider);
    final me = ref.watch(currentUserProvider);
    final asClient = me?.can(Permission.requestViewings) ?? false;
    final now = DateTime.now();

    Widget card(Viewing v) {
      final isClient = me != null && v.clientId == me.id;
      final isAgent = me != null && v.agentId == me.id;
      return ViewingCard(
        viewing: v,
        counterpartId: asClient ? v.agentId : v.clientId,
        counterpartFallback: asClient
            ? l10n.inquiryOtherAgent
            : l10n.inquiryOtherClient,
        actions: ViewingWorkflow.nextStatuses(
          from: v.status,
          isClient: isClient,
          isAgent: isAgent,
          scheduledAt: v.scheduledAt,
          now: now,
        ),
        onAction: (to) => unawaited(_onAction(context, ref, v, to)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.viewingsTitle)),
      body: board.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          failure: toFailure(error),
          onRetry: () => ref.invalidate(viewingBoardProvider),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(viewingBoardProvider);
            await ref.read(viewingBoardProvider.future);
          },
          child: data.isEmpty
              ? ListView(
                  children: [
                    const SizedBox(height: 120),
                    Center(child: Text(l10n.viewingsEmpty)),
                  ],
                )
              : ListView(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                  children: [
                    if (data.upcoming.isNotEmpty) ...[
                      _SectionHeader(l10n.viewingsUpcoming),
                      for (final v in data.upcoming) card(v),
                    ],
                    if (data.history.isNotEmpty) ...[
                      _SectionHeader(l10n.viewingsHistory),
                      for (final v in data.history) card(v),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.md,
      AppSpacing.md,
      AppSpacing.md,
      AppSpacing.xs,
    ),
    child: Text(text, style: Theme.of(context).textTheme.titleSmall),
  );
}

class _DeclineDialog extends StatefulWidget {
  const new();

  @override
  State<_DeclineDialog> createState() => _DeclineDialogState();
}

class _DeclineDialogState extends State<_DeclineDialog> {
  final _controller = TextEditingController();
  ViewingFieldError? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.viewingDeclineTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 3,
        maxLength: ViewingRules.maxReasonLength,
        decoration: InputDecoration(
          labelText: l10n.viewingDeclineReasonLabel,
          errorText: _error?.localized(l10n),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () {
            final error = ViewingRules.validateReason(_controller.text);
            if (error != null) {
              setState(() => _error = error);
              return;
            }
            Navigator.of(context).pop(_controller.text.trim());
          },
          child: Text(l10n.viewingActionDecline),
        ),
      ],
    );
  }
}
