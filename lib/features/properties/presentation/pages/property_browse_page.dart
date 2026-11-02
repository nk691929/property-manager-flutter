import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:property_manager/app/router/routes.dart';
import 'package:property_manager/app/theme/design_tokens.dart';
import 'package:property_manager/features/properties/presentation/providers/property_list_providers.dart';
import 'package:property_manager/features/properties/presentation/providers/property_list_query.dart';
import 'package:property_manager/features/properties/presentation/widgets/paged_property_list.dart';
import 'package:property_manager/features/properties/presentation/widgets/property_card.dart';
import 'package:property_manager/features/properties/presentation/widgets/property_filter_sheet.dart';
import 'package:property_manager/l10n/l10n.dart';

class PropertyBrowsePage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<PropertyBrowsePage> createState() => _PropertyBrowsePageState();
}

class _PropertyBrowsePageState extends ConsumerState<PropertyBrowsePage> {
  final _search = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _search.text = ref.read(browseFilterProvider).query;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  /// Debounced: one request after typing pauses, not one per keystroke.
  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      ref.read(browseFilterProvider.notifier).setQuery(text.trim());
    });
  }

  Future<void> _openFilters() async {
    final current = ref.read(browseFilterProvider);
    final result = await showPropertyFilterSheet(context, current);
    if (result != null) ref.read(browseFilterProvider.notifier).filter = result;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final filter = ref.watch(browseFilterProvider);
    final query = PropertyListQuery(
      scope: PropertyScope.browse,
      filter: filter,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.browseTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    onChanged: _onChanged,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: l10n.browseSearchHint,
                      prefixIcon: const Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Badge(
                  isLabelVisible: filter.activeCount > 0,
                  label: Text('${filter.activeCount}'),
                  child: IconButton.filledTonal(
                    tooltip: l10n.actionFilters,
                    icon: const Icon(Icons.tune),
                    onPressed: () => unawaited(_openFilters()),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: PagedPropertyList(
              query: query,
              emptyMessage: l10n.browseEmpty,
              itemBuilder: (context, property) => PropertyCard(
                property: property,
                onTap: () => unawaited(
                  context.push(AppRoutes.propertyDetail(property.id)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
