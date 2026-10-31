import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:property_manager/app/router/routes.dart';
import 'package:property_manager/app/theme/design_tokens.dart';
import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/features/auth/domain/validators/auth_validators.dart';
import 'package:property_manager/features/auth/presentation/extensions/auth_messages.dart';
import 'package:property_manager/features/auth/presentation/providers/auth_controllers.dart';
import 'package:property_manager/features/auth/presentation/widgets/auth_layout.dart';
import 'package:property_manager/l10n/l10n.dart';

class LoginPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref
        .read(signInControllerProvider.notifier)
        .submit(email: _email.text, password: _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(signInControllerProvider);
    final error = state.error;

    return AuthLayout(
      title: l10n.loginTitle,
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: l10n.fieldEmail),
                validator: (v) => AuthValidators.email(v)?.localized(l10n),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _password,
                obscureText: true,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => unawaited(_submit()),
                decoration: InputDecoration(labelText: l10n.fieldPassword),
                validator: (v) =>
                    AuthValidators.signInPassword(v)?.localized(l10n),
              ),
            ],
          ),
        ),
        if (error != null)
          AuthErrorText(authFailureMessage(toFailure(error), l10n)),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: state.isLoading ? null : () => unawaited(_submit()),
          child: state.isLoading
              ? const ButtonProgress()
              : Text(l10n.actionSignIn),
        ),
        TextButton(
          onPressed: () => context.go(AppRoutes.register),
          child: Text(l10n.linkNoAccount),
        ),
      ],
    );
  }
}
