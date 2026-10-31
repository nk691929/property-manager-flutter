import 'package:flutter/material.dart';
import 'package:property_manager/features/home/presentation/widgets/home_scaffold.dart';
import 'package:property_manager/l10n/l10n.dart';

class AgentHomePage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) =>
      HomeScaffold(title: context.l10n.roleAgent);
}
