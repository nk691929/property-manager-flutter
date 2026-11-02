import 'package:flutter/material.dart';
import 'package:property_manager/app/theme/design_tokens.dart';
import 'package:property_manager/features/properties/domain/entities/property.dart';
import 'package:property_manager/features/properties/presentation/extensions/property_format.dart';
import 'package:property_manager/features/properties/presentation/extensions/property_labels.dart';
import 'package:property_manager/features/properties/presentation/widgets/property_status_chip.dart';
import 'package:property_manager/l10n/l10n.dart';

class PropertyCard extends StatelessWidget {
  const new({
    required this.property,
    required this.onTap,
    this.showStatus = false,
    this.trailing,
    super.key,
  });

  final Property property;
  final VoidCallback onTap;
  final bool showStatus;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final area = formatArea(context, property);
    final bedrooms = property.bedrooms;
    final bathrooms = property.bathrooms;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      formatPrice(context, property),
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  if (showStatus) PropertyStatusChip(status: property.status),
                  ?trailing,
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                property.title,
                style: theme.textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                property.city,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.xs,
                children: [
                  _Fact(
                    icon: Icons.home_work_outlined,
                    text: property.propertyType.label(l10n),
                  ),
                  if (bedrooms != null)
                    _Fact(
                      icon: Icons.bed_outlined,
                      text: l10n.bedroomsLabel(bedrooms),
                    ),
                  if (bathrooms != null)
                    _Fact(
                      icon: Icons.bathtub_outlined,
                      text: l10n.bathroomsLabel(bathrooms),
                    ),
                  if (area != null) _Fact(icon: Icons.square_foot, text: area),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const new({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: AppSpacing.xs),
        Text(text, style: TextStyle(color: color)),
      ],
    );
  }
}
