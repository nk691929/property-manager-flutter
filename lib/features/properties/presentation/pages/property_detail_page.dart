import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:property_manager/app/theme/design_tokens.dart';
import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/presentation/widgets/error_view.dart';
import 'package:property_manager/features/properties/domain/entities/property.dart';
import 'package:property_manager/features/properties/domain/entities/property_enums.dart';
import 'package:property_manager/features/properties/presentation/extensions/property_format.dart';
import 'package:property_manager/features/properties/presentation/extensions/property_labels.dart';
import 'package:property_manager/features/properties/presentation/providers/property_list_providers.dart';
import 'package:property_manager/features/properties/presentation/widgets/property_status_chip.dart';
import 'package:property_manager/l10n/l10n.dart';

class PropertyDetailPage extends ConsumerWidget {
  const new({required this.propertyId, super.key});

  final String propertyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final detail = ref.watch(propertyDetailProvider(propertyId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.detailTitle)),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          failure: toFailure(error),
          onRetry: () => ref.invalidate(propertyDetailProvider(propertyId)),
        ),
        data: (property) => _Detail(property: property),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const new({required this.property});

  final Property property;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final area = formatArea(context, property);
    final reason = property.rejectionReason;
    final bedrooms = property.bedrooms;
    final bathrooms = property.bathrooms;
    final location = [
      property.address,
      property.city,
    ].where((part) => part.trim().isNotEmpty).join(', ');

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(
          formatPrice(context, property),
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(property.title, style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            if (property.status != PropertyStatus.published)
              PropertyStatusChip(status: property.status),
            Chip(label: Text(property.listingType.label(l10n))),
            Chip(label: Text(property.propertyType.label(l10n))),
          ],
        ),
        if (reason != null && reason.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Text(
              l10n.rejectionReasonLabel(reason),
              style: TextStyle(color: theme.colorScheme.onErrorContainer),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          children: [
            if (bedrooms != null) Text(l10n.bedroomsLabel(bedrooms)),
            if (bathrooms != null) Text(l10n.bathroomsLabel(bathrooms)),
            if (area != null) Text(area),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(l10n.detailLocation, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(location),
        if (property.description.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.detailDescription, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(property.description),
        ],
      ],
    );
  }
}
