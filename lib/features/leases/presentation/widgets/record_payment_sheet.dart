import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:property_manager/app/theme/design_tokens.dart';
import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/money/money.dart';
import 'package:property_manager/core/presentation/formatters.dart';
import 'package:property_manager/core/providers/core_providers.dart';
import 'package:property_manager/core/time/calendar.dart';
import 'package:property_manager/features/auth/presentation/widgets/auth_layout.dart';
import 'package:property_manager/features/leases/domain/entities/lease_enums.dart';
import 'package:property_manager/features/leases/domain/entities/new_payment.dart';
import 'package:property_manager/features/leases/domain/entities/rent_charge.dart';
import 'package:property_manager/features/leases/domain/rules/payment_rules.dart';
import 'package:property_manager/features/leases/presentation/extensions/lease_texts.dart';
import 'package:property_manager/features/leases/presentation/providers/leases_providers.dart';
import 'package:property_manager/l10n/l10n.dart';

Future<bool?> showRecordPaymentSheet(
  BuildContext context, {
  required String leaseId,
  required RentCharge charge,
}) => showModalBottomSheet<bool>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _RecordPaymentSheet(leaseId: leaseId, charge: charge),
);

class _RecordPaymentSheet extends ConsumerStatefulWidget {
  const new({required this.leaseId, required this.charge});

  final String leaseId;
  final RentCharge charge;

  @override
  ConsumerState<_RecordPaymentSheet> createState() =>
      _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends ConsumerState<_RecordPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;
  final _reference = TextEditingController();
  late DateTime _paidOn;
  PaymentMethod _method = PaymentMethod.cash;
  bool _saving = false;
  Failure? _error;

  Money get _balance => widget.charge.balance;

  @override
  void initState() {
    super.initState();
    _paidOn = Calendar.dateOnly(ref.read(clockProvider)());
    // Default to the full balance: the common case is paying it all.
    _amount = TextEditingController(
      text: _balance.minorUnits % 100 == 0
          ? '${_balance.minorUnits ~/ 100}'
          : _balance.toDecimalString(),
    );
  }

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    super.dispose();
  }

  Money? get _parsed =>
      Money.tryParse(_amount.text, currency: _balance.currency);

  Future<void> _pickDate() async {
    final today = Calendar.dateOnly(ref.read(clockProvider)());
    final picked = await showDatePicker(
      context: context,
      initialDate: _paidOn,
      firstDate: Calendar.addDays(today, -365),
      lastDate: today,
    );
    if (picked == null || !mounted) return;
    setState(() => _paidOn = Calendar.dateOnly(picked));
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final failure = await ref
        .read(leaseActionsProvider.notifier)
        .recordPayment(
          NewPayment(
            leaseId: widget.leaseId,
            chargeId: widget.charge.id,
            amount: _parsed ?? Money.zero(_balance.currency),
            paidOn: _paidOn,
            method: _method,
            reference: _reference.text.trim(),
          ),
        );
    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _saving = false;
      _error = failure;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final error = _error;
    const gap = SizedBox(height: AppSpacing.md);

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.paymentRecordTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.paymentBalanceDue(
                  formatMoney(context, _balance),
                  formatDate(context, widget.charge.dueDate),
                ),
              ),
              gap,
              TextFormField(
                controller: _amount,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText:
                      '${l10n.paymentFieldAmount} (${_balance.currency})',
                ),
                validator: (value) {
                  final amount = Money.tryParse(
                    value,
                    currency: _balance.currency,
                  );
                  if (amount == null) return l10n.paymentErrorAmount;
                  return PaymentRules.amount(
                    amount,
                    balance: _balance,
                  )?.localized(l10n);
                },
              ),
              gap,
              DropdownButtonFormField<PaymentMethod>(
                initialValue: _method,
                decoration: InputDecoration(labelText: l10n.paymentFieldMethod),
                items: [
                  for (final method in PaymentMethod.values)
                    DropdownMenuItem(
                      value: method,
                      child: Text(method.label(l10n)),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _method = value);
                },
              ),
              gap,
              OutlinedButton.icon(
                onPressed: () => unawaited(_pickDate()),
                icon: const Icon(Icons.event_outlined),
                label: Text(
                  l10n.paymentFieldDate(formatDate(context, _paidOn)),
                ),
              ),
              gap,
              TextFormField(
                controller: _reference,
                maxLength: PaymentRules.maxReferenceLength,
                decoration: InputDecoration(
                  labelText: l10n.paymentFieldReference,
                ),
              ),
              if (error != null)
                AuthErrorText(paymentFailureMessage(error, l10n)),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: _saving ? null : () => unawaited(_submit()),
                child: _saving
                    ? const ButtonProgress()
                    : Text(l10n.paymentRecordAction),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
