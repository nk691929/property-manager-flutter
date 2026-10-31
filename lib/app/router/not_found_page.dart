import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:property_manager/app/router/routes.dart';
import 'package:property_manager/app/theme/design_tokens.dart';
import 'package:property_manager/l10n/l10n.dart';

class NotFoundPage extends StatelessWidget {
  const new({required this.location, super.key});

  final String location;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.routeNotFoundTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.routeNotFoundBody(location),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () => context.go(AppRoutes.home),
                child: Text(l10n.appInfoTitle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
