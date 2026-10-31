import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:property_manager/app/router/routes.dart';
import 'package:property_manager/features/home/presentation/widgets/home_scaffold.dart';
import 'package:property_manager/l10n/l10n.dart';

class AdminHomePage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return HomeScaffold(
      title: l10n.roleAdmin,
      children: [
        FilledButton.tonalIcon(
          onPressed: () => unawaited(context.push(AppRoutes.adminUsers)),
          icon: const Icon(Icons.group_outlined),
          label: Text(l10n.homeManageUsers),
        ),
      ],
    );
  }
}
