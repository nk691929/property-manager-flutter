import 'package:flutter/material.dart';
import 'package:property_manager/app/theme/design_tokens.dart';
import 'package:property_manager/features/properties/domain/entities/property_enums.dart';
import 'package:property_manager/features/properties/domain/entities/property_filter.dart';
import 'package:property_manager/features/properties/presentation/extensions/property_labels.dart';
import 'package:property_manager/l10n/l10n.dart';

Future<PropertyFilter?> showPropertyFilterSheet(
  BuildContext context,
  PropertyFilter current,
) => showModalBottomSheet<PropertyFilter>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _FilterSheet(initial: current),
);

class _FilterSheet extends StatefulWidget {
  const new({required this.initial});

  final PropertyFilter initial;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late final TextEditingController _city;
  late final TextEditingController _minPrice;
  late final TextEditingController _maxPrice;
  late ListingType? _listingType;
  late PropertyType? _propertyType;
  late int? _minBedrooms;
  late PropertySort _sort;

  @override
  void initState() {
    super.initState();
    final f = widget.initial;
    _city = TextEditingController(text: f.city);
    _minPrice = TextEditingController(text: _plain(f.minPrice));
    _maxPrice = TextEditingController(text: _plain(f.maxPrice));
    _listingType = f.listingType;
    _propertyType = f.propertyType;
    _minBedrooms = f.minBedrooms;
    _sort = f.sort;
  }

  @override
  void dispose() {
    _city.dispose();
    _minPrice.dispose();
    _maxPrice.dispose();
    super.dispose();
  }

  static String _plain(double? v) =>
      v == null ? '' : (v == v.roundToDouble() ? v.round().toString() : '$v');

  static double? _parse(String text) =>
      double.tryParse(text.trim().replaceAll(',', ''));

  PropertyFilter _build() => PropertyFilter(
    query: widget.initial.query,
    city: _city.text.trim(),
    sort: _sort,
    listingType: _listingType,
    propertyType: _propertyType,
    minPrice: _parse(_minPrice.text),
    maxPrice: _parse(_maxPrice.text),
    minBedrooms: _minBedrooms,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.filterListingType),
            const SizedBox(height: AppSpacing.sm),
            SegmentedButton<ListingType?>(
              segments: [
                ButtonSegment(value: null, label: Text(l10n.filterAny)),
                for (final type in ListingType.values)
                  ButtonSegment(value: type, label: Text(type.label(l10n))),
              ],
              selected: {_listingType},
              onSelectionChanged: (s) => setState(() => _listingType = s.first),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<PropertyType?>(
              initialValue: _propertyType,
              decoration: InputDecoration(labelText: l10n.filterPropertyType),
              items: [
                DropdownMenuItem(child: Text(l10n.filterAny)),
                for (final type in PropertyType.values)
                  DropdownMenuItem(value: type, child: Text(type.label(l10n))),
              ],
              onChanged: (v) => setState(() => _propertyType = v),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _city,
              decoration: InputDecoration(labelText: l10n.filterCity),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minPrice,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: l10n.filterMinPrice),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: TextField(
                    controller: _maxPrice,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: l10n.filterMaxPrice),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<int?>(
              initialValue: _minBedrooms,
              decoration: InputDecoration(labelText: l10n.filterMinBedrooms),
              items: [
                DropdownMenuItem(child: Text(l10n.filterAny)),
                for (final n in const [1, 2, 3, 4, 5])
                  DropdownMenuItem(value: n, child: Text('$n+')),
              ],
              onChanged: (v) => setState(() => _minBedrooms = v),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<PropertySort>(
              initialValue: _sort,
              decoration: InputDecoration(labelText: l10n.filterSort),
              items: [
                for (final sort in PropertySort.values)
                  DropdownMenuItem(value: sort, child: Text(sort.label(l10n))),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _sort = v);
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        Navigator.of(context)
                            .pop(PropertyFilter(query: widget.initial.query)),
                    child: Text(l10n.actionClearFilters),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(_build()),
                    child: Text(l10n.actionApply),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
