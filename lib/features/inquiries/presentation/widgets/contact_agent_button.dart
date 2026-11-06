import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:property_manager/app/router/routes.dart';
import 'package:property_manager/features/inquiries/presentation/providers/inquiries_providers.dart';
import 'package:property_manager/l10n/l10n.dart';

/// "Contact agent", or "View conversation" when one is already open. Who may
/// see it is decided by the app layer (see `PropertyEngagementBar`).
class ContactAgentButton extends ConsumerWidget {
  const new({required this.propertyId, super.key});

  final String propertyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final open = ref.watch(openInquiryForProvider(propertyId));
    final inquiry = open.value;
    final isLoading = open.isLoading && !open.hasValue;

    return FilledButton.icon(
      // If the lookup fails we still let them write; the database rejects a
      // true duplicate with a clear message.
      onPressed: isLoading
          ? null
          : () => unawaited(
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
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
