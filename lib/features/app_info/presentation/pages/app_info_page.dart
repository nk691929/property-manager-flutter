import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:property_manager/app/theme/design_tokens.dart';
import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/presentation/failure_message.dart';
import 'package:property_manager/core/providers/core_providers.dart';
import 'package:property_manager/features/app_info/domain/entities/app_info.dart';
import 'package:property_manager/features/app_info/presentation/providers/app_info_providers.dart';
import 'package:property_manager/l10n/l10n.dart';

class AppInfoPage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(appInfoProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.appInfoTitle)),
      body: SafeArea(
        child: info.when(
          data: (data) => _InfoList(info: data),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorView(
            failure: error is Failure ? error : UnknownFailure(cause: error),
            onRetry: () => ref.invalidate(appInfoProvider),
          ),
        ),
      ),
    );
  }
}

class _InfoList extends ConsumerWidget {
  const new({required this.info});

  final AppInfo info;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final hasBackend = ref.watch(appConfigProvider).hasBackendConfig;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Card(
          child: Column(
            children: [
              _InfoTile(label: l10n.labelApp, value: info.appName),
              _InfoTile(
                label: l10n.labelVersion,
                value: l10n.versionValue(info.version, info.buildNumber),
              ),
              // Flavor name is a technical label, intentionally not localized.
              _InfoTile(
                label: l10n.labelEnvironment,
                value: info.flavor.name.toUpperCase(),
              ),
              _InfoTile(
                label: l10n.labelBackend,
                value: hasBackend
                    ? l10n.backendConfigured
                    : l10n.backendNotConfigured,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const new({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(title: Text(label), trailing: Text(value));
  }
}

class _ErrorView extends StatelessWidget {
  const new({required this.failure, required this.onRetry});

  final Failure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(failure.localized(l10n), textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            FilledButton(onPressed: onRetry, child: Text(l10n.actionRetry)),
          ],
        ),
      ),
    );
  }
}
