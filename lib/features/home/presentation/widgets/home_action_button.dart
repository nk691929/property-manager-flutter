import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:property_manager/app/theme/design_tokens.dart';

class HomeActionButton extends StatelessWidget {
  const new({
    required this.icon,
    required this.label,
    required this.route,
    super.key,
  });

  final IconData icon;
  final String label;
  final String route;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: FilledButton.tonalIcon(
      onPressed: () => unawaited(context.push(route)),
      icon: Icon(icon),
      label: Text(label),
    ),
  );
}
