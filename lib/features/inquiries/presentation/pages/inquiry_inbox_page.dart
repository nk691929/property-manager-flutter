import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/presentation/widgets/error_view.dart';
import 'package:property_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:property_manager/features/inquiries/presentation/providers/inquiries_providers.dart';
import 'package:property_manager/l10n/l10n.dart';

class InquiryInboxPage extends ConsumerWidget {
  const new({required this.threadPath, super.key});

  /// Where a conversation lives for this role (supplied by the router).
  final String Function(String inquiryId) threadPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final inbox = ref.watch(inquiryInboxProvider);
    final myId = ref.watch(currentUserProvider)?.id;
    final locale = Localizations.localeOf(context).toString();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.inquiriesTitle)),
      body: inbox.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          failure: toFailure(error),
          onRetry: () => ref.invalidate(inquiryInboxProvider),
        ),
        data: (items) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(inquiryInboxProvider);
            await ref.read(inquiryInboxProvider.future);
          },
          child: items.isEmpty
              ? ListView(
                  children: [
                    const SizedBox(height: 120),
                    Center(child: Text(l10n.inquiriesEmpty)),
                  ],
                )
              : ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final inquiry = items[index];
                    final preview = inquiry.lastSenderId == myId
                        ? l10n.inquiryPreviewYou(inquiry.lastMessagePreview)
                        : inquiry.lastMessagePreview;
                    return ListTile(
                      title: Text(
                        inquiry.propertyTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        preview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            DateFormat.MMMd(locale)
                                .format(inquiry.lastMessageAt.toLocal()),
                          ),
                          if (!inquiry.isOpen)
                            Text(
                              l10n.inquiryStatusClosed,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                        ],
                      ),
                      onTap: () =>
                          unawaited(context.push(threadPath(inquiry.id))),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
