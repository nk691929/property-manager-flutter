import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:property_manager/app/router/routes.dart';
import 'package:property_manager/features/viewings/presentation/providers/viewings_providers.dart';
import 'package:property_manager/l10n/l10n.dart';

/// "Request viewing", or "Your viewing" when one is already active.
class ViewingButton extends ConsumerWidget {
  const new({required this.propertyId, super.key});

  final String propertyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final active = ref.watch(activeViewingForProvider(propertyId));
    final viewing = active.value;
    final isLoading = active.isLoading && !active.hasValue;

    return FilledButton.tonalIcon(
      // If the lookup fails we still let them ask; the database rejects a
      // true duplicate with a clear message.
      onPressed: isLoading
          ? null
          : () => unawaited(
              context.push(
                viewing == null
                    ? AppRoutes.newViewing(propertyId)
                    : AppRoutes.clientViewings,
              ),
            ),
      icon: const Icon(Icons.event_available_outlined),
      label: Text(
        viewing == null ? l10n.viewingRequest : l10n.viewingYours,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
