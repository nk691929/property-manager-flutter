import 'package:flutter/material.dart';
import 'package:property_manager/features/leases/domain/rules/payment_rules.dart';
import 'package:property_manager/features/leases/presentation/extensions/lease_texts.dart';
import 'package:property_manager/l10n/l10n.dart';

/// Asks for a reason and returns it, or null if cancelled.
Future<String?> showVoidPaymentDialog(BuildContext context) =>
    showDialog<String>(context: context, builder: (_) => const _VoidDialog());

class _VoidDialog extends StatefulWidget {
  const new();

  @override
  State<_VoidDialog> createState() => _VoidDialogState();
}

class _VoidDialogState extends State<_VoidDialog> {
  final _controller = TextEditingController();
  PaymentFieldError? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.paymentVoidTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.paymentVoidBody),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLines: 2,
            maxLength: PaymentRules.maxReasonLength,
            decoration: InputDecoration(
              labelText: l10n.paymentVoidReasonLabel,
              errorText: _error?.localized(l10n),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () {
            final error = PaymentRules.voidReason(_controller.text);
            if (error != null) {
              setState(() => _error = error);
              return;
            }
            Navigator.of(context).pop(_controller.text.trim());
          },
          child: Text(l10n.paymentVoidAction),
        ),
      ],
    );
  }
}
