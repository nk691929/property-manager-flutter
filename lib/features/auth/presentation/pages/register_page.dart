import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:property_manager/app/router/routes.dart';
import 'package:property_manager/app/theme/design_tokens.dart';
import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/features/auth/domain/entities/sign_up_outcome.dart';
import 'package:property_manager/features/auth/domain/validators/auth_validators.dart';
import 'package:property_manager/features/auth/presentation/extensions/auth_messages.dart';
import 'package:property_manager/features/auth/presentation/providers/auth_controllers.dart';
import 'package:property_manager/features/auth/presentation/widgets/auth_layout.dart';
import 'package:property_manager/l10n/l10n.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref
        .read(signUpControllerProvider.notifier)
        .submit(
          email: _email.text,
          password: _password.text,
          fullName: _name.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(signUpControllerProvider);
    final error = state.error;
    final needsConfirmation = state.value == SignUpOutcome.confirmationRequired;

    return AuthLayout(
      title: l10n.registerTitle,
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _name,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: l10n.fieldFullName),
              ),
              const SizedBox(height: AppSpacing.md),
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
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: l10n.fieldPassword),
                validator: (v) => AuthValidators.password(v)?.localized(l10n),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _confirm,
                obscureText: true,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => unawaited(_submit()),
                decoration: InputDecoration(
                  labelText: l10n.fieldConfirmPassword,
                ),
                validator: (v) => AuthValidators.confirmPassword(
                  _password.text,
                  v,
                )?.localized(l10n),
              ),
            ],
          ),
        ),
        if (error != null)
          AuthErrorText(authFailureMessage(toFailure(error), l10n)),
        if (needsConfirmation) AuthErrorText(l10n.registerConfirmEmail),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: state.isLoading ? null : () => unawaited(_submit()),
          child: state.isLoading
              ? const ButtonProgress()
              : Text(l10n.actionSignUp),
        ),
        TextButton(
          onPressed: () => context.go(AppRoutes.login),
          child: Text(l10n.linkHaveAccount),
        ),
      ],
    );
  }
}
