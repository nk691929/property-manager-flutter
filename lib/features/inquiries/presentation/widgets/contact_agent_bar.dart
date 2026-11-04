import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:property_manager/app/router/routes.dart';
import 'package:property_manager/app/theme/design_tokens.dart';
import 'package:property_manager/features/auth/domain/entities/permission.dart';
import 'package:property_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:property_manager/features/inquiries/presentation/providers/inquiries_providers.dart';
import 'package:property_manager/l10n/l10n.dart';

/// Bottom bar of the property detail screen. Renders nothing for users who
/// can't send inquiries (agents, admins). UX only: `StartInquiry` and the
/// database enforce it.
class ContactAgentBar extends ConsumerWidget {
  const new({required this.propertyId, super.key});

  final String propertyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canSend = ref.watch(
      currentUserProvider.select(
        (user) => user?.can(Permission.sendInquiries) ?? false,
      ),
    );
    if (!canSend) return const SizedBox.shrink();

    final l10n = context.l10n;
    final open = ref.watch(openInquiryForProvider(propertyId));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: open.when(
          loading: () => FilledButton.icon(
            onPressed: null,
            icon: const Icon(Icons.chat_bubble_outline),
            label: Text(l10n.inquiryContactAgent),
          ),
          // If the lookup fails we still let them write; the database rejects
          // a true duplicate with a clear message.
          error: (_, _) => FilledButton.icon(
            onPressed: () =>
                unawaited(context.push(AppRoutes.newInquiry(propertyId))),
            icon: const Icon(Icons.chat_bubble_outline),
            label: Text(l10n.inquiryContactAgent),
          ),
          data: (inquiry) => FilledButton.icon(
            onPressed: () => unawaited(
              context.push(
                inquiry == null
                    ? AppRoutes.newInquiry(propertyId)
                    : AppRoutes.clientInquiry(inquiry.id),
              ),
            ),
            icon: const Icon(Icons.chat_bubble_outline),
            label: Text(
              inquiry == null
                  ? l10n.inquiryContactAgent
                  : l10n.inquiryViewConversation,
            ),
          ),
        ),
      ),
    );
  }
}
