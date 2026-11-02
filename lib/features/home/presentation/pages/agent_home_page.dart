import 'package:flutter/material.dart';
import 'package:property_manager/app/router/routes.dart';
import 'package:property_manager/features/home/presentation/widgets/home_action_button.dart';
import 'package:property_manager/features/home/presentation/widgets/home_scaffold.dart';
import 'package:property_manager/l10n/l10n.dart';

class AgentHomePage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return HomeScaffold(
      title: l10n.roleAgent,
      children: [
        HomeActionButton(
          icon: Icons.apartment_outlined,
          label: l10n.homeMyListings,
          route: AppRoutes.agentListings,
        ),
        HomeActionButton(
          icon: Icons.search,
          label: l10n.homeBrowse,
          route: AppRoutes.properties,
        ),
      ],
    );
  }
}
