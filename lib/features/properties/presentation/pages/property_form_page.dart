import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:property_manager/app/theme/design_tokens.dart';
import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/presentation/failure_message.dart';
import 'package:property_manager/core/presentation/widgets/error_view.dart';
import 'package:property_manager/features/auth/presentation/widgets/auth_layout.dart';
import 'package:property_manager/features/properties/domain/entities/property.dart';
import 'package:property_manager/features/properties/domain/entities/property_draft.dart';
import 'package:property_manager/features/properties/domain/entities/property_enums.dart';
import 'package:property_manager/features/properties/domain/rules/property_validators.dart';
import 'package:property_manager/features/properties/presentation/extensions/property_labels.dart';
import 'package:property_manager/features/properties/presentation/providers/property_list_providers.dart';
import 'package:property_manager/l10n/l10n.dart';

/// Create when [propertyId] is null, edit otherwise.
class PropertyFormPage extends ConsumerWidget {
  const new({this.propertyId, super.key});

  final String? propertyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final id = propertyId;
    final title = id == null ? l10n.formCreateTitle : l10n.formEditTitle;

    if (id == null) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const _PropertyForm(),
      );
    }
    final detail = ref.watch(propertyDetailProvider(id));
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          failure: toFailure(error),
          onRetry: () => ref.invalidate(propertyDetailProvider(id)),
        ),
        data: (property) => _PropertyForm(initial: property),
      ),
    );
  }
}

class _PropertyForm extends ConsumerStatefulWidget {
  const new({this.initial});

  final Property? initial;

  @override
  ConsumerState<_PropertyForm> createState() => _PropertyFormState();
}

class _PropertyFormState extends ConsumerState<_PropertyForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _bedrooms;
  late final TextEditingController _bathrooms;
  late final TextEditingController _area;
  late final TextEditingController _city;
  late final TextEditingController _address;
  late ListingType _listingType;
  late PropertyType _propertyType;
  AreaUnit? _areaUnit;
  bool _saving = false;
  Failure? _error;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _title = TextEditingController(text: p?.title);
    _description = TextEditingController(text: p?.description);
    _price = TextEditingController(text: _plain(p?.price));
    _bedrooms = TextEditingController(text: p?.bedrooms?.toString());
    _bathrooms = TextEditingController(text: p?.bathrooms?.toString());
    _area = TextEditingController(text: _plain(p?.areaValue));
    _city = TextEditingController(text: p?.city);
    _address = TextEditingController(text: p?.address);
    _listingType = p?.listingType ?? ListingType.rent;
    _propertyType = p?.propertyType ?? PropertyType.house;
    _areaUnit = p?.areaUnit;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    _bedrooms.dispose();
    _bathrooms.dispose();
    _area.dispose();
    _city.dispose();
    _address.dispose();
    super.dispose();
  }

  static String _plain(double? v) =>
      v == null ? '' : (v == v.roundToDouble() ? v.round().toString() : '$v');

  static double? _parse(String text) =>
      double.tryParse(text.trim().replaceAll(',', ''));

  String? _validateCount(String? text) {
    final value = text?.trim() ?? '';
    if (value.isEmpty) return null; // optional
    return PropertyValidators.count(int.tryParse(value))
        ?.localized(context.l10n);
  }

  String? _validateArea(String? text) {
    final l10n = context.l10n;
    final value = text?.trim() ?? '';
    final parsed = value.isEmpty ? null : _parse(value);
    if (value.isNotEmpty && parsed == null) {
      return PropertyFieldError.areaInvalid.localized(l10n);
    }
    return PropertyValidators.area(parsed, _areaUnit)?.localized(l10n);
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });

    final draft = PropertyDraft(
      title: _title.text.trim(),
      description: _description.text.trim(),
      listingType: _listingType,
      propertyType: _propertyType,
      price: _parse(_price.text) ?? 0,
      bedrooms: int.tryParse(_bedrooms.text.trim()),
      bathrooms: int.tryParse(_bathrooms.text.trim()),
      areaValue: _parse(_area.text),
      areaUnit: _areaUnit,
      city: _city.text.trim(),
      address: _address.text.trim(),
    );

    final actions = ref.read(propertyActionsProvider.notifier);
    final id = widget.initial?.id;
    final failure = id == null
        ? await actions.create(draft)
        : await actions.update(id, draft);
    if (!mounted) return;
    if (failure != null) {
      setState(() {
        _saving = false;
        _error = failure;
      });
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final message = context.l10n.listingSaved;
    context.pop();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const gap = SizedBox(height: AppSpacing.md);

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          TextFormField(
            controller: _title,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: l10n.fieldTitle),
            validator: (v) => PropertyValidators.title(v)?.localized(l10n),
          ),
          gap,
          TextFormField(
            controller: _description,
            maxLines: 5,
            decoration: InputDecoration(labelText: l10n.fieldDescription),
            validator: (v) =>
                PropertyValidators.description(v)?.localized(l10n),
          ),
          gap,
          SegmentedButton<ListingType>(
            segments: [
              for (final type in ListingType.values)
                ButtonSegment(value: type, label: Text(type.label(l10n))),
            ],
            selected: {_listingType},
            onSelectionChanged: (s) => setState(() => _listingType = s.first),
          ),
          gap,
          DropdownButtonFormField<PropertyType>(
            initialValue: _propertyType,
            decoration: InputDecoration(labelText: l10n.filterPropertyType),
            items: [
              for (final type in PropertyType.values)
                DropdownMenuItem(value: type, child: Text(type.label(l10n))),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _propertyType = v);
            },
          ),
          gap,
          TextFormField(
            controller: _price,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.fieldPrice,
              helperText: l10n.fieldPriceHelper,
            ),
            validator: (v) =>
                PropertyValidators.price(_parse(v ?? ''))?.localized(l10n),
          ),
          gap,
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _bedrooms,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l10n.fieldBedrooms),
                  validator: _validateCount,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: TextFormField(
                  controller: _bathrooms,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l10n.fieldBathrooms),
                  validator: _validateCount,
                ),
              ),
            ],
          ),
          gap,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _area,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l10n.fieldArea),
                  validator: _validateArea,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: DropdownButtonFormField<AreaUnit?>(
                  initialValue: _areaUnit,
                  decoration: InputDecoration(labelText: l10n.fieldAreaUnit),
                  items: [
                    DropdownMenuItem(child: Text(l10n.unitNone)),
                    for (final unit in AreaUnit.values)
                      DropdownMenuItem(
                        value: unit,
                        child: Text(unit.label(l10n)),
                      ),
                  ],
                  onChanged: (v) => setState(() => _areaUnit = v),
                ),
              ),
            ],
          ),
          gap,
          TextFormField(
            controller: _city,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: l10n.fieldCity),
            validator: (v) => PropertyValidators.city(v)?.localized(l10n),
          ),
          gap,
          TextFormField(
            controller: _address,
            decoration: InputDecoration(labelText: l10n.fieldAddress),
            validator: (v) => PropertyValidators.address(v)?.localized(l10n),
          ),
          if (_error case final failure?)
            AuthErrorText(failure.localized(l10n)),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: _saving ? null : () => unawaited(_submit()),
            child: _saving ? const ButtonProgress() : Text(l10n.actionSave),
          ),
        ],
      ),
    );
  }
}
