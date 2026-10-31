import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/presentation/failure_message.dart';
import 'package:property_manager/core/presentation/widgets/error_view.dart';
import 'package:property_manager/features/admin_users/presentation/providers/admin_users_providers.dart';
import 'package:property_manager/features/auth/domain/entities/app_user.dart';
import 'package:property_manager/features/auth/domain/entities/role.dart';
import 'package:property_manager/features/auth/presentation/extensions/auth_messages.dart';
import 'package:property_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:property_manager/l10n/l10n.dart';

class AdminUsersPage extends ConsumerWidget {
  const new({super.key});

  Future<void> _onRoleSelected(
    BuildContext context,
    WidgetRef ref,
    AppUser user,
    Role role,
  ) async {
    if (role == user.role) return;
    final failure = await ref
        .read(adminUsersProvider.notifier)
        .changeRole(user, role);
    if (!context.mounted) return;
    final l10n = context.l10n;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          failure == null
              ? l10n.adminUsersRoleUpdated
              : failure.localized(l10n),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final users = ref.watch(adminUsersProvider);
    final me = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminUsersTitle)),
      body: users.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          failure: toFailure(error),
          onRetry: () => ref.invalidate(adminUsersProvider),
        ),
        data: (list) => list.isEmpty
            ? Center(child: Text(l10n.adminUsersEmpty))
            : RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(adminUsersProvider);
                  await ref.read(adminUsersProvider.future);
                },
                child: ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final user = list[index];
                    final isSelf = user.id == me?.id;
                    return ListTile(
                      title: Text(
                        isSelf
                            ? l10n.adminUsersSelf(user.displayName)
                            : user.displayName,
                      ),
                      subtitle: Text(user.email),
                      trailing: PopupMenuButton<Role>(
                        enabled: !isSelf,
                        tooltip: l10n.adminUsersChangeRole,
                        onSelected: (role) => unawaited(
                          _onRoleSelected(context, ref, user, role),
                        ),
                        itemBuilder: (_) => [
                          for (final role in Role.values)
                            PopupMenuItem(
                              value: role,
                              child: Text(role.label(l10n)),
                            ),
                        ],
                        child: Chip(label: Text(user.role.label(l10n))),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
