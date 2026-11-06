import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:property_manager/app/theme/design_tokens.dart';
import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/presentation/widgets/error_view.dart';
import 'package:property_manager/features/auth/domain/entities/permission.dart';
import 'package:property_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:property_manager/features/inquiries/domain/entities/inquiry.dart';
import 'package:property_manager/features/inquiries/domain/entities/inquiry_message.dart';
import 'package:property_manager/features/inquiries/domain/rules/inquiry_rules.dart';
import 'package:property_manager/features/inquiries/presentation/extensions/inquiry_texts.dart';
import 'package:property_manager/features/inquiries/presentation/providers/inquiries_providers.dart';
import 'package:property_manager/features/user_directory/presentation/providers/user_directory_providers.dart';
import 'package:property_manager/l10n/l10n.dart';

class InquiryThreadPage extends ConsumerStatefulWidget {
  const new({required this.inquiryId, super.key});

  final String inquiryId;

  @override
  ConsumerState<InquiryThreadPage> createState() => _InquiryThreadPageState();
}

class _InquiryThreadPageState extends ConsumerState<InquiryThreadPage> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _send() async {
    final l10n = context.l10n;
    setState(() => _sending = true);
    final failure = await ref
        .read(inquiryActionsProvider.notifier)
        .send(widget.inquiryId, _controller.text);
    if (!mounted) return;
    setState(() => _sending = false);
    if (failure == null) {
      _controller.clear(); // keep the text if sending failed
    } else {
      _toast(inquiryFailureMessage(failure, l10n));
    }
  }

  Future<void> _close() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.inquiryCloseTitle),
        content: Text(l10n.inquiryCloseBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.inquiryClose),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final failure = await ref
        .read(inquiryActionsProvider.notifier)
        .close(widget.inquiryId);
    if (failure != null) _toast(inquiryFailureMessage(failure, l10n));
  }

  void _refresh() {
    ref
      ..invalidate(inquiryDetailProvider(widget.inquiryId))
      ..invalidate(inquiryMessagesProvider(widget.inquiryId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final id = widget.inquiryId;
    final inquiry = ref.watch(inquiryDetailProvider(id));
    final current = inquiry.value;

    return Scaffold(
      appBar: AppBar(
        title: Text(current?.propertyTitle ?? l10n.inquiriesTitle),
        actions: [
          IconButton(
            tooltip: l10n.actionRefresh,
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
          if (current != null && current.isOpen)
            IconButton(
              tooltip: l10n.inquiryClose,
              icon: const Icon(Icons.lock_outline),
              onPressed: () => unawaited(_close()),
            ),
        ],
      ),
      body: inquiry.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            ErrorView(failure: toFailure(error), onRetry: _refresh),
        data: _conversation,
      ),
    );
  }

  Widget _conversation(Inquiry inquiry) {
    final l10n = context.l10n;
    final me = ref.watch(currentUserProvider);
    final amClient = me?.can(Permission.sendInquiries) ?? false;
    final otherId = amClient ? inquiry.agentId : inquiry.clientId;
    final otherName = otherId == null
        ? null
        : ref.watch(userNameProvider(otherId)).value;
    final otherLabel =
        otherName ??
        (amClient ? l10n.inquiryOtherAgent : l10n.inquiryOtherClient);
    final messages = ref.watch(inquiryMessagesProvider(inquiry.id));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              l10n.inquiryWith(otherLabel),
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        ),
        Expanded(
          child: messages.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) =>
                ErrorView(failure: toFailure(error), onRetry: _refresh),
            data: (items) =>
                _messageList(items, myId: me?.id, otherLabel: otherLabel),
          ),
        ),
        if (inquiry.isOpen) _composer(l10n) else _closedNotice(l10n),
      ],
    );
  }

  Widget _messageList(
    List<InquiryMessage> items, {
    required String? myId,
    required String otherLabel,
  }) {
    final l10n = context.l10n;
    if (items.isEmpty) return Center(child: Text(l10n.inquiriesEmpty));

    // Newest at the bottom: a reversed list starts anchored there.
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final message = items[items.length - 1 - index];
        final isMine = message.senderId == myId;
        return _Bubble(
          message: message,
          isMine: isMine,
          label: isMine ? l10n.inquiryYou : otherLabel,
        );
      },
    );
  }

  Widget _composer(AppLocalizations l10n) {
    final canSend = !_sending && _controller.text.trim().isNotEmpty;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 5,
                maxLength: InquiryRules.maxLength,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: l10n.inquiryMessageHint,
                  counterText: '',
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton.filled(
              tooltip: l10n.inquirySend,
              onPressed: canSend ? () => unawaited(_send()) : null,
              icon: _sending
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }

  Widget _closedNotice(AppLocalizations l10n) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Text(
        l10n.inquiryClosed,
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    ),
  );
}

class _Bubble extends StatelessWidget {
  const new({required this.message, required this.isMine, required this.label});

  final InquiryMessage message;
  final bool isMine;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final time = DateFormat.MMMd(locale)
        .add_jm()
        .format(message.createdAt.toLocal());

    return Align(
      alignment: isMine
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.8,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isMine
                ? scheme.primaryContainer
                : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.labelSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(message.body),
              const SizedBox(height: AppSpacing.xs),
              Text(time, style: theme.textTheme.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}
