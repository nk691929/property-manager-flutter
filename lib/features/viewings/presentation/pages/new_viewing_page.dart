import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:property_manager/app/router/routes.dart';
import 'package:property_manager/app/theme/design_tokens.dart';
import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/features/auth/presentation/widgets/auth_layout.dart';
import 'package:property_manager/features/properties/presentation/providers/property_list_providers.dart';
import 'package:property_manager/features/viewings/domain/rules/viewing_rules.dart';
import 'package:property_manager/features/viewings/presentation/extensions/viewing_format.dart';
import 'package:property_manager/features/viewings/presentation/extensions/viewing_texts.dart';
import 'package:property_manager/features/viewings/presentation/providers/viewings_providers.dart';
import 'package:property_manager/l10n/l10n.dart';

class NewViewingPage extends ConsumerStatefulWidget {
  const new({required this.propertyId, super.key});

  final String propertyId;

  @override
  ConsumerState<NewViewingPage> createState() => _NewViewingPageState();
}

class _NewViewingPageState extends ConsumerState<NewViewingPage> {
  DateTime? _date;
  TimeOfDay? _time;
  bool _sending = false;
  Failure? _error;

  /// Date and time are picked separately, in local time.
  DateTime? get _scheduled {
    final date = _date;
    final time = _time;
    if (date == null || time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? today.add(const Duration(days: 1)),
      firstDate: today,
      lastDate: today.add(ViewingRules.maxAhead),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _date = picked;
      _error = null;
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 10, minute: 0),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _time = picked;
      _error = null;
    });
  }

  Future<void> _submit() async {
    final scheduled = _scheduled;
    if (scheduled == null) {
      setState(
        () => _error = ValidationFailure({
          'time': ViewingFieldError.missingTime.name,
        }),
      );
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    final result = await ref
        .read(viewingActionsProvider.notifier)
        .request(widget.propertyId, scheduled);
    if (!mounted) return;

    if (result.isOk) {
      final messenger = ScaffoldMessenger.of(context);
      final message = context.l10n.viewingRequested;
      // Replace this screen with the list that now contains the request.
      context.pushReplacement(AppRoutes.clientViewings);
      messenger.showSnackBar(SnackBar(content: Text(message)));
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
    final scheduled = _scheduled;
    final error = _error;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.viewingNewTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          if (property.value case final value?) ...[
            Text(
              l10n.viewingForProperty(value.title),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          Text(l10n.viewingRequestHint),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => unawaited(_pickDate()),
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(l10n.viewingPickDate),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => unawaited(_pickTime()),
                  icon: const Icon(Icons.schedule),
                  label: Text(l10n.viewingPickTime),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            scheduled == null
                ? l10n.viewingNoTimeYet
                : formatViewingTime(context, scheduled),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (error != null)
            AuthErrorText(
              viewingFailureMessage(error, l10n, duplicateIsConflict: true),
            ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: _sending ? null : () => unawaited(_submit()),
            child: _sending ? const ButtonProgress() : Text(l10n.viewingSubmit),
          ),
        ],
      ),
    );
  }
}
