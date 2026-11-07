import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:property_manager/app/router/routes.dart';
import 'package:property_manager/app/theme/design_tokens.dart';
import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/money/money.dart';
import 'package:property_manager/core/presentation/failure_message.dart';
import 'package:property_manager/core/presentation/formatters.dart';
import 'package:property_manager/core/providers/core_providers.dart';
import 'package:property_manager/core/time/calendar.dart';
import 'package:property_manager/features/auth/presentation/widgets/auth_layout.dart';
import 'package:property_manager/features/leases/domain/entities/leasable_property.dart';
import 'package:property_manager/features/leases/domain/entities/new_lease.dart';
import 'package:property_manager/features/leases/domain/rules/lease_rules.dart';
import 'package:property_manager/features/leases/domain/rules/lease_schedule.dart';
import 'package:property_manager/features/leases/presentation/extensions/lease_texts.dart';
import 'package:property_manager/features/leases/presentation/providers/leases_providers.dart';
import 'package:property_manager/features/user_directory/presentation/providers/user_directory_providers.dart';
import 'package:property_manager/l10n/l10n.dart';

class NewLeasePage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<NewLeasePage> createState() => _NewLeasePageState();
}

class _NewLeasePageState extends ConsumerState<NewLeasePage> {
  final _formKey = GlobalKey<FormState>();
  final _rent = TextEditingController();
  final _deposit = TextEditingController(text: '0');
  LeasableProperty? _property;
  String? _tenantId;
  DateTime? _start;
  DateTime? _end;
  int _dueDay = 1;
  bool _saving = false;
  Failure? _error;

  String get _currency => _property?.monthlyRent.currency ?? 'PKR';

  @override
  void dispose() {
    _rent.dispose();
    _deposit.dispose();
    super.dispose();
  }

  static String _plain(Money money) => money.minorUnits % 100 == 0
      ? '${money.minorUnits ~/ 100}'
      : money.toDecimalString();

  void _onPropertyChanged(LeasableProperty? value) {
    setState(() {
      _property = value;
      _tenantId = null;
      _error = null;
      if (value != null) _rent.text = _plain(value.monthlyRent);
    });
  }

  Future<void> _pickStart() async {
    final today = Calendar.dateOnly(ref.read(clockProvider)());
    final picked = await showDatePicker(
      context: context,
      initialDate: _start ?? today,
      firstDate: Calendar.addDays(today, -365),
      lastDate: Calendar.addMonths(today, 24),
    );
    if (picked == null || !mounted) return;
    final start = Calendar.dateOnly(picked);
    final end = _end;
    setState(() {
      _start = start;
      // An end date that is no longer after the start must be chosen again.
      if (end != null && !end.isAfter(start)) _end = null;
      _error = null;
    });
  }

  Future<void> _pickEnd() async {
    final start = _start;
    if (start == null) return;
    final firstDate = Calendar.addDays(start, 1);
    final lastDate = Calendar.addMonths(start, LeaseRules.maxMonths);
    final suggested = Calendar.addDays(Calendar.addMonths(start, 12), -1);
    final picked = await showDatePicker(
      context: context,
      initialDate: _end ?? suggested,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _end = Calendar.dateOnly(picked);
      _error = null;
    });
  }

  String? _validateMoney(String? text, {required bool isRent}) {
    final l10n = context.l10n;
    final money = Money.tryParse(text, currency: _currency);
    if (money == null) {
      return isRent ? l10n.leaseErrorRent : l10n.leaseErrorDeposit;
    }
    if (isRent && !money.isPositive) return l10n.leaseErrorRent;
    return null;
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final start = _start;
    final end = _end;
    if (start == null || end == null) {
      setState(
        () => _error = ValidationFailure({
          'dates': LeaseFieldError.datesMissing.name,
        }),
      );
      return;
    }

    final draft = NewLease(
      propertyId: _property?.id ?? '',
      tenantId: _tenantId ?? '',
      startDate: start,
      endDate: end,
      monthlyRent:
          Money.tryParse(_rent.text, currency: _currency) ??
          Money.zero(_currency),
      securityDeposit:
          Money.tryParse(_deposit.text, currency: _currency) ??
          Money.zero(_currency),
      dueDay: _dueDay,
    );

    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await ref.read(leaseActionsProvider.notifier).create(draft);
    if (!mounted) return;

    final lease = result.valueOrNull;
    if (lease != null) {
      final messenger = ScaffoldMessenger.of(context);
      // Replace this form with the lease it just created.
      context.pushReplacement(AppRoutes.agentLease(lease.id));
      messenger.showSnackBar(SnackBar(content: Text(l10n.leaseCreated)));
      return;
    }
    setState(() {
      _saving = false;
      _error = result.failureOrNull;
    });
  }

  Widget _propertyField(AsyncValue<List<LeasableProperty>> properties) {
    final l10n = context.l10n;
    return properties.when(
      loading: () => const LinearProgressIndicator(),
      error: (error, _) => Text(toFailure(error).localized(l10n)),
      data: (items) {
        if (items.isEmpty) return Text(l10n.leaseNoProperties);
        return DropdownButtonFormField<LeasableProperty>(
          initialValue: _property,
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.leaseFieldProperty),
          items: [
            for (final item in items)
              DropdownMenuItem(
                value: item,
                child: Text(
                  '${item.title} (${item.city})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: _onPropertyChanged,
          validator: (value) => value == null ? l10n.leaseErrorMissing : null,
        );
      },
    );
  }

  Widget _tenantField(LeasableProperty property) {
    final l10n = context.l10n;
    final candidates = ref.watch(tenantCandidatesProvider(property.id));
    return candidates.when(
      loading: () => const LinearProgressIndicator(),
      error: (error, _) => Text(toFailure(error).localized(l10n)),
      data: (ids) {
        if (ids.isEmpty) return Text(l10n.leaseNoCandidates);
        return DropdownButtonFormField<String>(
          // A new listing means a new list: rebuild so the old choice resets.
          key: ValueKey(property.id),
          initialValue: _tenantId,
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.leaseFieldTenant),
          items: [
            for (final id in ids)
              DropdownMenuItem(
                value: id,
                child: _ClientName(clientId: id),
              ),
          ],
          onChanged: (value) => setState(() => _tenantId = value),
          validator: (value) => value == null ? l10n.leaseErrorMissing : null,
        );
      },
    );
  }

  Widget? _preview() {
    final start = _start;
    final end = _end;
    final rent = Money.tryParse(_rent.text, currency: _currency);
    if (start == null || end == null || rent == null || !rent.isPositive) {
      return null;
    }
    if (LeaseRules.dates(start, end) != null) return null;
    final dates = LeaseSchedule.dueDates(
      start: start,
      end: end,
      dueDay: _dueDay,
    );
    if (dates.isEmpty) return null;
    return Text(
      context.l10n.leasePreview(
        dates.length,
        formatDate(context, dates.first),
        formatMoney(context, rent * dates.length),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final properties = ref.watch(leasablePropertiesProvider);
    final property = _property;
    final error = _error;
    final start = _start;
    final end = _end;
    final preview = _preview();
    const gap = SizedBox(height: AppSpacing.md);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.leaseNewTitle)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _propertyField(properties),
            if (property != null) ...[
              gap,
              _tenantField(property),
              gap,
              TextFormField(
                controller: _rent,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: '${l10n.leaseFieldRent} ($_currency)',
                ),
                onChanged: (_) => setState(() {}),
                validator: (value) => _validateMoney(value, isRent: true),
              ),
              gap,
              TextFormField(
                controller: _deposit,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: '${l10n.leaseFieldDeposit} ($_currency)',
                ),
                validator: (value) => _validateMoney(value, isRent: false),
              ),
              gap,
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => unawaited(_pickStart()),
                      icon: const Icon(Icons.event_outlined),
                      label: Text(
                        start == null
                            ? l10n.leaseFieldStart
                            : formatDate(context, start),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: start == null
                          ? null
                          : () => unawaited(_pickEnd()),
                      icon: const Icon(Icons.event_available_outlined),
                      label: Text(
                        end == null
                            ? l10n.leaseFieldEnd
                            : formatDate(context, end),
                      ),
                    ),
                  ),
                ],
              ),
              gap,
              DropdownButtonFormField<int>(
                initialValue: _dueDay,
                decoration: InputDecoration(labelText: l10n.leaseFieldDueDay),
                items: [
                  for (var day = 1; day <= 28; day++)
                    DropdownMenuItem(value: day, child: Text('$day')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _dueDay = value);
                },
              ),
              if (preview != null) ...[gap, preview],
            ],
            if (error != null)
              AuthErrorText(leaseFailureMessage(error, l10n, forCreate: true)),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: (_saving || property == null)
                  ? null
                  : () => unawaited(_submit()),
              child: _saving ? const ButtonProgress() : Text(l10n.leaseSubmit),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientName extends ConsumerWidget {
  const new({required this.clientId});

  final String clientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(userNameProvider(clientId)).value;
    return Text(
      name ?? context.l10n.inquiryOtherClient,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
