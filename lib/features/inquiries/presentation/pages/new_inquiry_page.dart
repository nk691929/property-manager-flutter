import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:property_manager/app/router/routes.dart';
import 'package:property_manager/app/theme/design_tokens.dart';
import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/features/auth/presentation/widgets/auth_layout.dart';
import 'package:property_manager/features/inquiries/domain/rules/inquiry_rules.dart';
import 'package:property_manager/features/inquiries/presentation/extensions/inquiry_texts.dart';
import 'package:property_manager/features/inquiries/presentation/providers/inquiries_providers.dart';
import 'package:property_manager/features/properties/presentation/providers/property_list_providers.dart';
import 'package:property_manager/l10n/l10n.dart';

class NewInquiryPage extends ConsumerStatefulWidget {
  const new({required this.propertyId, super.key});

  final String propertyId;

  @override
  ConsumerState<NewInquiryPage> createState() => _NewInquiryPageState();
}

class _NewInquiryPageState extends ConsumerState<NewInquiryPage> {
  final _controller = TextEditingController();
  bool _sending = false;
  Failure? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _sending = true;
      _error = null;
    });
    final result = await ref
        .read(inquiryActionsProvider.notifier)
        .start(widget.propertyId, _controller.text);
    if (!mounted) return;

    final inquiry = result.valueOrNull;
    if (inquiry != null) {
      // Replace this screen with the conversation it just created.
      context.pushReplacement(AppRoutes.clientInquiry(inquiry.id));
      return;
    }
    setState(() {
      _sending = false;
      _error = result.failureOrNull;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final property = ref.watch(propertyDetailProvider(widget.propertyId));
    final error = _error;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.inquiryNewTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          if (property.value case final value?) ...[
            Text(
              l10n.inquiryAbout(value.title),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          TextField(
            controller: _controller,
            autofocus: true,
            minLines: 4,
            maxLines: 8,
            maxLength: InquiryRules.maxLength,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(hintText: l10n.inquiryMessageHint),
          ),
          if (error != null) AuthErrorText(inquiryFailureMessage(error, l10n)),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: _sending ? null : () => unawaited(_send()),
            child: _sending ? const ButtonProgress() : Text(l10n.inquirySend),
          ),
        ],
      ),
    );
  }
}
