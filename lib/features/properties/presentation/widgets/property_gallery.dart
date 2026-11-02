import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:property_manager/app/theme/design_tokens.dart';
import 'package:property_manager/features/properties/domain/entities/property_photo.dart';
import 'package:property_manager/features/properties/presentation/widgets/property_image.dart';
import 'package:property_manager/l10n/l10n.dart';

class PropertyGallery extends StatefulWidget {
  const new({required this.photos, this.semanticLabel, super.key});

  final List<PropertyPhoto> photos;
  final String? semanticLabel;

  @override
  State<PropertyGallery> createState() => _PropertyGalleryState();
}

class _PropertyGalleryState extends State<PropertyGallery> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.photos;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: photos.isEmpty
            ? const PropertyImage(photo: null)
            : Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    controller: _controller,
                    itemCount: photos.length,
                    onPageChanged: (index) => setState(() => _index = index),
                    itemBuilder: (_, index) => PropertyImage(
                      photo: photos[index],
                      memCacheWidth: 1200,
                      semanticLabel: widget.semanticLabel,
                    ),
                  ),
                  if (photos.length > 1)
                    PositionedDirectional(
                      bottom: AppSpacing.sm,
                      end: AppSpacing.sm,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          child: Text(
                            context.l10n.galleryCounter(
                              math.min(_index, photos.length - 1) + 1,
                              photos.length,
                            ),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
