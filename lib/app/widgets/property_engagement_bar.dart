import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:property_manager/app/theme/design_tokens.dart';
import 'package:property_manager/features/auth/domain/entities/permission.dart';
import 'package:property_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:property_manager/features/inquiries/presentation/widgets/contact_agent_button.dart';
import 'package:property_manager/features/viewings/presentation/widgets/viewing_button.dart';

/// Bottom bar of the property detail screen: contact the agent, or ask for a
/// viewing. Lives in the app layer so `inquiries` and `viewings` never import
/// each other. Renders nothing for agents and admins (UX only: the use cases
/// and database enforce who may do either).
class PropertyEngagementBar extends ConsumerWidget {
  const new({required this.propertyId, super.key});

  final String propertyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canEngage = ref.watch(
      currentUserProvider.select(
        (user) =>
            (user?.can(Permission.sendInquiries) ?? false) ||
            (user?.can(Permission.requestViewings) ?? false),
      ),
    );
    if (!canEngage) return const SizedBox.shrink();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(child: ContactAgentButton(propertyId: propertyId)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: ViewingButton(propertyId: propertyId)),
          ],
        ),
      ),
    );
  }
}
