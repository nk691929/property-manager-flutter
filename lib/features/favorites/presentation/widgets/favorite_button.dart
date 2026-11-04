import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:property_manager/core/presentation/failure_message.dart';
import 'package:property_manager/features/auth/domain/entities/permission.dart';
import 'package:property_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:property_manager/features/favorites/presentation/providers/favorites_providers.dart';
import 'package:property_manager/l10n/l10n.dart';

/// Renders nothing for users who can't save properties (agents, admins).
/// That is UX only; `AddFavorite` and the database policies enforce it.
class FavoriteButton extends ConsumerWidget {
  const new({required this.propertyId, super.key});

  final String propertyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canFavorite = ref.watch(
      currentUserProvider.select(
        (user) => user?.can(Permission.favoriteProperties) ?? false,
      ),
    );
    if (!canFavorite) return const SizedBox.shrink();

    final l10n = context.l10n;
    final (isFavorite, isLoaded) = ref.watch(
      favoriteIdsProvider.select(
        (ids) => (ids.value?.contains(propertyId) ?? false, ids.hasValue),
      ),
    );

    return IconButton(
      tooltip: isFavorite ? l10n.favoriteRemove : l10n.favoriteAdd,
      isSelected: isFavorite,
      icon: const Icon(Icons.favorite_border),
      selectedIcon: Icon(
        Icons.favorite,
        color: Theme.of(context).colorScheme.primary,
      ),
      onPressed: isLoaded
          ? () async {
              final failure = await ref
                  .read(favoriteIdsProvider.notifier)
                  .toggle(propertyId);
              if (failure == null || !context.mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(failure.localized(l10n))));
            }
          : null,
    );
  }
}
