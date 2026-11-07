import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:property_manager/app/router/routes.dart';
import 'package:property_manager/app/theme/design_tokens.dart';
import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/presentation/widgets/error_view.dart';
import 'package:property_manager/features/auth/domain/entities/permission.dart';
import 'package:property_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:property_manager/features/leases/domain/entities/lease.dart';
import 'package:property_manager/features/leases/presentation/providers/leases_providers.dart';
import 'package:property_manager/features/leases/presentation/widgets/lease_card.dart';
import 'package:property_manager/l10n/l10n.dart';

/// Shared by agents ("leases of my listings") and tenants ("my tenancy").
class LeasesPage extends ConsumerWidget {
  const new({required this.leasePath, super.key});

  /// Where one lease lives for this role (supplied by the router).
  final String Function(String leaseId) leasePath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final leases = ref.watch(leaseListProvider);
    final isAgent =
        ref.watch(currentUserProvider)?.can(Permission.manageLeases) ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(isAgent ? l10n.leasesTitle : l10n.leasesMineTitle),
      ),
      floatingActionButton: isAgent
          ? FloatingActionButton.extended(
              onPressed: () => unawaited(context.push(AppRoutes.agentLeaseNew)),
              icon: const Icon(Icons.add),
              label: Text(l10n.leaseNew),
            )
          : null,
      body: leases.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          failure: toFailure(error),
          onRetry: () => ref.invalidate(leaseListProvider),
        ),
        data: (items) {
          final active = [
            for (final lease in items)
              if (lease.isActive) lease,
          ];
          final ended = [
            for (final lease in items)
              if (!lease.isActive) lease,
          ];

          Widget card(Lease lease) => LeaseCard(
            lease: lease,
            isAgentView: isAgent,
            onTap: () => unawaited(context.push(leasePath(lease.id))),
          );

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(leaseListProvider);
              await ref.read(leaseListProvider.future);
            },
            child: items.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 120),
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Center(
                          child: Text(
                            isAgent ? l10n.leasesEmpty : l10n.leasesEmptyTenant,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.only(bottom: 96),
                    children: [
                      if (active.isNotEmpty) ...[
                        _Header(l10n.leaseStatusActive),
                        for (final lease in active) card(lease),
                      ],
                      if (ended.isNotEmpty) ...[
                        _Header(l10n.leaseStatusEnded),
                        for (final lease in ended) card(lease),
                      ],
                    ],
                  ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
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
