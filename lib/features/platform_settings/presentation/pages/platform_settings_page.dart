import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/presentation/failure_message.dart';
import 'package:property_manager/core/presentation/widgets/error_view.dart';
import 'package:property_manager/features/platform_settings/presentation/providers/platform_settings_providers.dart';
import 'package:property_manager/l10n/l10n.dart';

class PlatformSettingsPage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(platformSettingsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: settings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          failure: toFailure(error),
          onRetry: () => ref.invalidate(platformSettingsControllerProvider),
        ),
        data: (data) => ListView(
          children: [
            SwitchListTile(
              title: Text(l10n.settingsApprovalTitle),
              subtitle: Text(l10n.settingsApprovalBody),
              value: data.requireListingApproval,
              onChanged: (value) async {
                final failure = await ref
                    .read(platformSettingsControllerProvider.notifier)
                    .setApprovalRequired(value: value);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      failure == null
                          ? l10n.settingsSaved
                          : failure.localized(l10n),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
