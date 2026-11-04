import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:property_manager/app/router/routes.dart';
import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/presentation/widgets/error_view.dart';
import 'package:property_manager/features/favorites/presentation/providers/favorites_providers.dart';
import 'package:property_manager/features/favorites/presentation/widgets/favorite_button.dart';
import 'package:property_manager/features/properties/presentation/widgets/property_card.dart';
import 'package:property_manager/l10n/l10n.dart';

class SavedPropertiesPage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final saved = ref.watch(savedPropertiesProvider);
    final favoriteIds = ref.watch(favoriteIdsProvider).value;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.savedTitle)),
      body: saved.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          failure: toFailure(error),
          onRetry: () => ref
            ..invalidate(savedPropertiesProvider)
            ..invalidate(favoriteIdsProvider),
        ),
        data: (items) {
          if (favoriteIds == null) {
            return const Center(child: CircularProgressIndicator());
          }
          // Hide what the user un-hearted since the list loaded.
          final visible = [
            for (final property in items)
              if (favoriteIds.contains(property.id)) property,
          ];
          if (visible.isEmpty) {
            return Center(child: Text(l10n.savedEmpty));
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref
                ..invalidate(favoriteIdsProvider)
                ..invalidate(savedPropertiesProvider);
              await ref.read(savedPropertiesProvider.future);
            },
            child: ListView.builder(
              itemCount: visible.length,
              itemBuilder: (context, index) {
                final property = visible[index];
                return PropertyCard(
                  property: property,
                  trailing: FavoriteButton(propertyId: property.id),
                  onTap: () => unawaited(
                    context.push(AppRoutes.propertyDetail(property.id)),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
