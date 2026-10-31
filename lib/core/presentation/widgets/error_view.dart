import 'package:flutter/material.dart';
import 'package:property_manager/app/theme/design_tokens.dart';
import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/presentation/failure_message.dart';
import 'package:property_manager/l10n/l10n.dart';

class ErrorView extends StatelessWidget {
  const new({required this.failure, required this.onRetry, super.key});

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
