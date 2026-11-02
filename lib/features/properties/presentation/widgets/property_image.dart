import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:property_manager/features/properties/domain/entities/property_photo.dart';

/// One photo, or a neutral placeholder when there isn't one.
class PropertyImage extends StatelessWidget {
  const new({
    required this.photo,
    this.memCacheWidth,
    this.semanticLabel,
    super.key,
  });

  final PropertyPhoto? photo;

  /// Decode at this width instead of full size (saves memory in lists).
  final int? memCacheWidth;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget placeholder(IconData icon) => ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(child: Icon(icon, color: scheme.onSurfaceVariant)),
    );

    final current = photo;
    if (current == null) return placeholder(Icons.home_work_outlined);

    return Semantics(
      image: true,
      label: semanticLabel,
      child: CachedNetworkImage(
        imageUrl: current.url,
        // The path never changes for a given file, so it is a stable key.
        cacheKey: current.path,
        fit: BoxFit.cover,
        memCacheWidth: memCacheWidth,
        placeholder: (_, _) => placeholder(Icons.image_outlined),
        errorWidget: (_, _, _) => placeholder(Icons.broken_image_outlined),
      ),
    );
  }
}
