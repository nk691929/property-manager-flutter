import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:property_manager/app/router/routes.dart';
import 'package:property_manager/app/theme/design_tokens.dart';
import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/presentation/failure_message.dart';
import 'package:property_manager/features/admin_users/presentation/providers/admin_users_providers.dart';
import 'package:property_manager/features/auth/domain/entities/role.dart';
import 'package:property_manager/features/platform_settings/presentation/providers/platform_settings_providers.dart';
import 'package:property_manager/features/properties/domain/entities/property.dart';
import 'package:property_manager/features/properties/domain/entities/property_enums.dart';
import 'package:property_manager/features/properties/domain/rules/property_workflow.dart';
import 'package:property_manager/features/properties/presentation/extensions/property_labels.dart';
import 'package:property_manager/features/properties/presentation/providers/property_list_providers.dart';
import 'package:property_manager/features/properties/presentation/providers/property_list_query.dart';
import 'package:property_manager/features/properties/presentation/widgets/paged_property_list.dart';
import 'package:property_manager/features/properties/presentation/widgets/property_card.dart';
import 'package:property_manager/l10n/l10n.dart';

enum _MenuAction { edit, delete, reassign }

class ManagedListingsPage extends ConsumerStatefulWidget {
  const new({required this.scope, this.initialStatus, super.key});

  /// `mine` for agents, `all` for admins.
  final PropertyScope scope;
  final PropertyStatus? initialStatus;

  @override
  ConsumerState<ManagedListingsPage> createState() =>
      _ManagedListingsPageState();
}

class _ManagedListingsPageState extends ConsumerState<ManagedListingsPage> {
  PropertyStatus? _status;

  bool get _asAdmin => widget.scope == PropertyScope.all;

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
  }

  void _toast(Failure? failure, String Function(AppLocalizations) success) {
    if (!mounted) return;
    final l10n = context.l10n;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          failure == null ? success(l10n) : failure.localized(l10n),
        ),
      ),
    );
  }

  Future<void> _onSelected(Property property, Object value) async {
    switch (value) {
      case _MenuAction.edit:
        await context.push(AppRoutes.agentListingEdit(property.id));
      case _MenuAction.delete:
        await _delete(property);
      case _MenuAction.reassign:
        await _reassign(property);
      case final PropertyStatus to:
        await _changeStatus(property, to);
    }
  }

  Future<void> _changeStatus(Property property, PropertyStatus to) async {
    String? reason;
    if (to == PropertyStatus.rejected) {
      reason = await showDialog<String>(
        context: context,
        builder: (_) => const _ReasonDialog(),
      );
      if (reason == null) return;
    }
    final failure = await ref
        .read(propertyActionsProvider.notifier)
        .changeStatus(property.id, to, rejectionReason: reason);
    _toast(failure, (l10n) => l10n.listingStatusUpdated);
  }

  Future<void> _delete(Property property) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deleteDialogTitle),
        content: Text(context.l10n.deleteDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final failure = await ref
        .read(propertyActionsProvider.notifier)
        .delete(property.id);
    _toast(failure, (l10n) => l10n.listingDeleted);
  }

  Future<void> _reassign(Property property) async {
    final agentId = await showDialog<String>(
      context: context,
      builder: (_) => const _AgentPickerDialog(),
    );
    if (agentId == null) return;
    final failure = await ref
        .read(propertyActionsProvider.notifier)
        .reassign(property.id, agentId);
    _toast(failure, (l10n) => l10n.listingReassigned);
  }

  Widget _menu(Property property, {required bool approvalRequired}) {
    final l10n = context.l10n;
    final targets = PropertyWorkflow.nextStatuses(
      from: property.status,
      asAdmin: _asAdmin,
      approvalRequired: approvalRequired,
    );
    final canEdit =
        !_asAdmin && PropertyWorkflow.isEditableByOwner(property.status);
    final canDelete = property.status == PropertyStatus.draft;

    return PopupMenuButton<Object>(
      tooltip: l10n.actionMore,
      onSelected: (value) => unawaited(_onSelected(property, value)),
      itemBuilder: (_) => [
        if (canEdit)
          PopupMenuItem<Object>(
            value: _MenuAction.edit,
            child: Text(l10n.actionEdit),
          ),
        for (final to in targets)
          PopupMenuItem<Object>(
            value: to,
            child: Text(
              statusActionLabel(from: property.status, to: to, l10n: l10n),
            ),
          ),
        if (_asAdmin)
          PopupMenuItem<Object>(
            value: _MenuAction.reassign,
            child: Text(l10n.actionReassign),
          ),
        if (canDelete)
          PopupMenuItem<Object>(
            value: _MenuAction.delete,
            child: Text(l10n.actionDelete),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final approvalRequired =
        ref
            .watch(platformSettingsControllerProvider)
            .value
            ?.requireListingApproval ??
        true;
    final query = PropertyListQuery(scope: widget.scope, status: _status);
    final title = !_asAdmin
        ? l10n.listingsMineTitle
        : (widget.initialStatus == PropertyStatus.pendingReview
              ? l10n.listingsReviewTitle
              : l10n.listingsAllTitle);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      floatingActionButton: _asAdmin
          ? null
          : FloatingActionButton.extended(
              onPressed: () =>
                  unawaited(context.push(AppRoutes.agentListingNew)),
              icon: const Icon(Icons.add),
              label: Text(l10n.listingNew),
            ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                ChoiceChip(
                  label: Text(l10n.statusAll),
                  selected: _status == null,
                  onSelected: (_) => setState(() => _status = null),
                ),
                for (final status in PropertyStatus.values) ...[
                  const SizedBox(width: AppSpacing.sm),
                  ChoiceChip(
                    label: Text(status.label(l10n)),
                    selected: _status == status,
                    onSelected: (_) => setState(() => _status = status),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: PagedPropertyList(
              query: query,
              emptyMessage: l10n.listingsEmpty,
              itemBuilder: (context, property) => PropertyCard(
                property: property,
                showStatus: true,
                trailing: _menu(property, approvalRequired: approvalRequired),
                onTap: () => unawaited(
                  context.push(AppRoutes.propertyDetail(property.id)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReasonDialog extends StatefulWidget {
  const new();

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _controller = TextEditingController();
  bool _showError = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.rejectDialogTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 3,
        decoration: InputDecoration(
          labelText: l10n.rejectReasonLabel,
          errorText: _showError ? l10n.fieldEmpty : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () {
            final text = _controller.text.trim();
            if (text.isEmpty) {
              setState(() => _showError = true);
              return;
            }
            Navigator.of(context).pop(text);
          },
          child: Text(l10n.actionReject),
        ),
      ],
    );
  }
}

class _AgentPickerDialog extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final users = ref.watch(adminUsersProvider);

    return SimpleDialog(
      title: Text(l10n.reassignDialogTitle),
      children: users.when(
        loading: () => const [
          Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
        error: (error, _) => [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(toFailure(error).localized(l10n)),
          ),
        ],
        data: (list) {
          final agents = list.where((u) => u.role == Role.agent).toList();
          if (agents.isEmpty) {
            return [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(l10n.reassignNoAgents),
              ),
            ];
          }
          return [
            for (final agent in agents)
              SimpleDialogOption(
                onPressed: () => Navigator.of(context).pop(agent.id),
                child: Text('${agent.displayName} (${agent.email})'),
              ),
          ];
        },
      ),
    );
  }
}
