import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:property_manager/app/theme/design_tokens.dart';
import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/presentation/failure_message.dart';
import 'package:property_manager/core/presentation/widgets/error_view.dart';
import 'package:property_manager/features/properties/domain/entities/property.dart';
import 'package:property_manager/features/properties/presentation/providers/property_list_providers.dart';
import 'package:property_manager/features/properties/presentation/providers/property_list_query.dart';
import 'package:property_manager/l10n/l10n.dart';

/// Shared by browse, "my listings" and the admin screens.
class PagedPropertyList extends ConsumerWidget {
  const new({
    required this.query,
    required this.itemBuilder,
    required this.emptyMessage,
    super.key,
  });

  final PropertyListQuery query;
  final Widget Function(BuildContext context, Property property) itemBuilder;
  final String emptyMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final provider = propertyListProvider(query);
    final paged = ref.watch(provider);

    return paged.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorView(
        failure: toFailure(error),
        onRetry: () => ref.invalidate(provider),
      ),
      data: (data) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(provider);
          await ref.read(provider.future);
        },
        child: data.items.isEmpty
            ? ListView(
                children: [
                  const SizedBox(height: 120),
                  Center(child: Text(emptyMessage)),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.only(bottom: 96),
                itemCount: data.items.length + 1,
                itemBuilder: (context, index) {
                  if (index < data.items.length) {
                    return itemBuilder(context, data.items[index]);
                  }
                  return _Footer(
                    paged: data,
                    onLoadMore: () => ref.read(provider.notifier).loadMore(),
                    l10n: l10n,
                  );
                },
              ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const new({
    required this.paged,
    required this.onLoadMore,
    required this.l10n,
  });

  final PagedProperties paged;
  final Future<void> Function() onLoadMore;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    if (paged.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (!paged.hasMore) return const SizedBox(height: AppSpacing.md);

    final failure = paged.loadMoreFailure;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          if (failure != null)
            Text(
              failure.localized(l10n),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          TextButton(onPressed: onLoadMore, child: Text(l10n.actionLoadMore)),
        ],
      ),
    );
  }
}
