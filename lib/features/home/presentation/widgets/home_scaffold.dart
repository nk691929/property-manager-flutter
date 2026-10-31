import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:property_manager/app/router/routes.dart';
import 'package:property_manager/app/theme/design_tokens.dart';
import 'package:property_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:property_manager/l10n/l10n.dart';

class HomeScaffold extends ConsumerWidget {
  const new({required this.title, this.children = const [], super.key});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: l10n.appInfoTitle,
            icon: const Icon(Icons.info_outline),
            onPressed: () => unawaited(context.push(AppRoutes.about)),
          ),
          IconButton(
            tooltip: l10n.actionSignOut,
            icon: const Icon(Icons.logout),
            onPressed: () => unawaited(ref.read(signOutProvider)()),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            l10n.homeWelcome(user?.displayName ?? ''),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          ...children,
        ],
      ),
    );
  }
}
