import 'package:flutter/material.dart';
import 'package:property_manager/app/router/routes.dart';
import 'package:property_manager/features/home/presentation/widgets/home_action_button.dart';
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
        HomeActionButton(
          icon: Icons.group_outlined,
          label: l10n.homeManageUsers,
          route: AppRoutes.adminUsers,
        ),
        HomeActionButton(
          icon: Icons.rate_review_outlined,
          label: l10n.homeReviewQueue,
          route: AppRoutes.adminReview,
        ),
        HomeActionButton(
          icon: Icons.apartment_outlined,
          label: l10n.homeAllListings,
          route: AppRoutes.adminListings,
        ),
        HomeActionButton(
          icon: Icons.search,
          label: l10n.homeBrowse,
          route: AppRoutes.properties,
        ),
        HomeActionButton(
          icon: Icons.settings_outlined,
          label: l10n.homeSettings,
          route: AppRoutes.adminSettings,
        ),
      ],
    );
  }
}
