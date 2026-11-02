import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:property_manager/app/theme/design_tokens.dart';
import 'package:property_manager/features/properties/domain/entities/photo_upload.dart';
import 'package:property_manager/features/properties/domain/entities/property_photo.dart';
import 'package:property_manager/features/properties/domain/rules/photo_rules.dart';
import 'package:property_manager/features/properties/presentation/extensions/photo_messages.dart';
import 'package:property_manager/features/properties/presentation/providers/properties_providers.dart';
import 'package:property_manager/features/properties/presentation/providers/property_list_providers.dart';
import 'package:property_manager/features/properties/presentation/widgets/property_image.dart';
import 'package:property_manager/l10n/l10n.dart';

enum _PhotoAction { cover, remove }

/// Photo section of the edit screen. Reads the listing's photos from
/// [propertyDetailProvider] itself, so it always shows the latest list even
/// while the form's own state stays untouched.
class PropertyPhotoManager extends ConsumerStatefulWidget {
  const new({required this.propertyId, super.key});

  final String propertyId;

  @override
  ConsumerState<PropertyPhotoManager> createState() =>
      _PropertyPhotoManagerState();
}

class _PropertyPhotoManagerState extends ConsumerState<PropertyPhotoManager> {
  final _picker = ImagePicker();
  bool _busy = false;

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _chooseSource() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(context.l10n.photosFromCamera),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(context.l10n.photosFromGallery),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    await _add(source);
  }

  Future<void> _add(ImageSource source) async {
    final l10n = context.l10n;
    setState(() => _busy = true);
    try {
      // Shrinks while picking, so a full-size photo never sits in memory.
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 80,
      );
      if (picked == null) return; // cancelled
      final bytes = await picked.readAsBytes();
      final upload = PhotoUpload(
        bytes: bytes,
        extension: PhotoRules.detectExtension(bytes) ?? '',
      );
      final failure = await ref
          .read(propertyActionsProvider.notifier)
          .addPhoto(widget.propertyId, upload);
      _toast(
        failure == null ? l10n.photoAdded : photoFailureMessage(failure, l10n),
      );
    } on Object catch (_) {
      _toast(l10n.errorUnknown);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onAction(PropertyPhoto photo, _PhotoAction action) async {
    final l10n = context.l10n;
    setState(() => _busy = true);
    final actions = ref.read(propertyActionsProvider.notifier);
    final failure = switch (action) {
      _PhotoAction.cover => await actions.setCover(widget.propertyId, photo.id),
      _PhotoAction.remove => await actions.removePhoto(
        widget.propertyId,
        photo.id,
      ),
    };
    if (!mounted) return;
    setState(() => _busy = false);
    _toast(
      failure != null
          ? photoFailureMessage(failure, l10n)
          : (action == _PhotoAction.cover
                ? l10n.photoCoverSet
                : l10n.photoRemoved),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    if (!ref.watch(photosSupportedProvider)) {
      return Text(
        l10n.photosUnavailable,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    final photos =
        ref.watch(propertyDetailProvider(widget.propertyId)).value?.photos ??
        const <PropertyPhoto>[];
    final isFull = photos.length >= PhotoRules.maxPerProperty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(l10n.photosTitle, style: theme.textTheme.titleMedium),
            ),
            Text(l10n.photosCount(photos.length, PhotoRules.maxPerProperty)),
          ],
        ),
        if (_busy)
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.sm),
            child: LinearProgressIndicator(),
          ),
        const SizedBox(height: AppSpacing.sm),
        if (photos.isEmpty)
          Text(l10n.photosEmpty)
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 140,
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
            ),
            itemCount: photos.length,
            itemBuilder: (context, index) => _PhotoTile(
              photo: photos[index],
              isCover: index == 0,
              enabled: !_busy,
              onAction: (action) => unawaited(_onAction(photos[index], action)),
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: (_busy || isFull)
              ? null
              : () => unawaited(_chooseSource()),
          icon: const Icon(Icons.add_a_photo_outlined),
          label: Text(l10n.photosAdd),
        ),
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const new({
    required this.photo,
    required this.isCover,
    required this.enabled,
    required this.onAction,
  });

  final PropertyPhoto photo;
  final bool isCover;
  final bool enabled;
  final ValueChanged<_PhotoAction> onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Stack(
        fit: StackFit.expand,
        children: [
          PropertyImage(photo: photo, memCacheWidth: 400),
          if (isCover)
            PositionedDirectional(
              start: AppSpacing.xs,
              bottom: AppSpacing.xs,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  child: Text(
                    l10n.photoCover,
                    style: TextStyle(color: scheme.onPrimary, fontSize: 12),
                  ),
                ),
              ),
            ),
          PositionedDirectional(
            top: AppSpacing.xs,
            end: AppSpacing.xs,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: PopupMenuButton<_PhotoAction>(
                enabled: enabled,
                iconColor: Colors.white,
                iconSize: 20,
                padding: EdgeInsets.zero,
                tooltip: l10n.actionMore,
                onSelected: onAction,
                itemBuilder: (_) => [
                  if (!isCover)
                    PopupMenuItem(
                      value: _PhotoAction.cover,
                      child: Text(l10n.photoSetCover),
                    ),
                  PopupMenuItem(
                    value: _PhotoAction.remove,
                    child: Text(l10n.photoRemove),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
