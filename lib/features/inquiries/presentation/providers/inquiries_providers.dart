import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/core/providers/core_providers.dart';
import 'package:property_manager/core/providers/supabase_provider.dart';
import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/features/auth/presentation/providers/auth_providers.dart';
import 'package:property_manager/features/inquiries/data/datasources/fake_inquiries_data_source.dart';
import 'package:property_manager/features/inquiries/data/datasources/inquiries_data_source.dart';
import 'package:property_manager/features/inquiries/data/datasources/supabase_inquiries_data_source.dart';
import 'package:property_manager/features/inquiries/data/repositories/inquiries_repository_impl.dart';
import 'package:property_manager/features/inquiries/domain/entities/inquiry.dart';
import 'package:property_manager/features/inquiries/domain/entities/inquiry_message.dart';
import 'package:property_manager/features/inquiries/domain/repositories/inquiries_repository.dart';
import 'package:property_manager/features/inquiries/domain/usecases/close_inquiry.dart';
import 'package:property_manager/features/inquiries/domain/usecases/find_open_inquiry.dart';
import 'package:property_manager/features/inquiries/domain/usecases/get_inquiry.dart';
import 'package:property_manager/features/inquiries/domain/usecases/list_inquiry_messages.dart';
import 'package:property_manager/features/inquiries/domain/usecases/list_my_inquiries.dart';
import 'package:property_manager/features/inquiries/domain/usecases/send_inquiry_message.dart';
import 'package:property_manager/features/inquiries/domain/usecases/start_inquiry.dart';
import 'package:property_manager/features/properties/presentation/providers/properties_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'inquiries_providers.g.dart';

// Composition root for inquiries (allowed to see data/).

@Riverpod(keepAlive: true)
InquiriesDataSource inquiriesDataSource(Ref ref) {
  final config = ref.watch(appConfigProvider);
  return config.hasBackendConfig
      ? SupabaseInquiriesDataSource(ref.watch(supabaseClientProvider))
      : FakeInquiriesDataSource(
          properties: ref.watch(propertiesDataSourceProvider),
        );
}

@Riverpod(keepAlive: true)
InquiriesRepository inquiriesRepository(Ref ref) =>
    InquiriesRepositoryImpl(ref.watch(inquiriesDataSourceProvider));

@riverpod
StartInquiry startInquiry(Ref ref) => StartInquiry(
  ref.watch(inquiriesRepositoryProvider),
  () => ref.read(currentUserProvider),
);

@riverpod
SendInquiryMessage sendInquiryMessage(Ref ref) => SendInquiryMessage(
  ref.watch(inquiriesRepositoryProvider),
  () => ref.read(currentUserProvider),
);

@riverpod
CloseInquiry closeInquiry(Ref ref) => CloseInquiry(
  ref.watch(inquiriesRepositoryProvider),
  () => ref.read(currentUserProvider),
);

@riverpod
GetInquiry getInquiry(Ref ref) => GetInquiry(
  ref.watch(inquiriesRepositoryProvider),
  () => ref.read(currentUserProvider),
);

@riverpod
ListInquiryMessages listInquiryMessages(Ref ref) => ListInquiryMessages(
  ref.watch(inquiriesRepositoryProvider),
  () => ref.read(currentUserProvider),
);

@riverpod
ListMyInquiries listMyInquiries(Ref ref) => ListMyInquiries(
  ref.watch(inquiriesRepositoryProvider),
  () => ref.read(currentUserProvider),
);

@riverpod
FindOpenInquiry findOpenInquiry(Ref ref) => FindOpenInquiry(
  ref.watch(inquiriesRepositoryProvider),
  () => ref.read(currentUserProvider),
);

@riverpod
Future<List<Inquiry>> inquiryInbox(Ref ref) async {
  final result = await ref.watch(listMyInquiriesProvider)(offset: 0);
  return result.fold<List<Inquiry>>(
    onOk: (items) => items,
    onErr: (failure) => throw failure,
  );
}

@riverpod
Future<Inquiry> inquiryDetail(Ref ref, String id) async {
  final result = await ref.watch(getInquiryProvider)(id);
  return result.fold<Inquiry>(
    onOk: (inquiry) => inquiry,
    onErr: (failure) => throw failure,
  );
}

@riverpod
Future<List<InquiryMessage>> inquiryMessages(Ref ref, String inquiryId) async {
  final result = await ref.watch(listInquiryMessagesProvider)(inquiryId);
  return result.fold<List<InquiryMessage>>(
    onOk: (items) => items,
    onErr: (failure) => throw failure,
  );
}

/// The client's open conversation about a listing, or null.
@riverpod
Future<Inquiry?> openInquiryFor(Ref ref, String propertyId) async {
  final result = await ref.watch(findOpenInquiryProvider)(propertyId);
  return result.fold<Inquiry?>(
    onOk: (inquiry) => inquiry,
    onErr: (failure) => throw failure,
  );
}

/// Mutations. keepAlive so the notifier outlives the page that called it
/// (a successful start replaces its own page).
@Riverpod(keepAlive: true)
class InquiryActions extends _$InquiryActions {
  @override
  void build() {}

  Future<Result<Inquiry>> start(String propertyId, String body) async {
    final result = await ref.read(startInquiryProvider)(
      propertyId: propertyId,
      body: body,
    );
    if (ref.mounted && result.isOk) _refreshData();
    return result;
  }

  Future<Failure?> send(String inquiryId, String body) => _run(
    () =>
        ref.read(sendInquiryMessageProvider)(inquiryId: inquiryId, body: body),
  );

  Future<Failure?> close(String inquiryId) =>
      _run(() => ref.read(closeInquiryProvider)(inquiryId));

  void _refreshData() {
    ref
      ..invalidate(inquiryInboxProvider)
      ..invalidate(inquiryDetailProvider)
      ..invalidate(inquiryMessagesProvider)
      ..invalidate(openInquiryForProvider);
  }

  /// Returns null on success, or the failure to show.
  Future<Failure?> _run<T>(Future<Result<T>> Function() action) async {
    final result = await action();
    if (!ref.mounted) return null;
    return result.fold<Failure?>(
      onOk: (_) {
        _refreshData();
        return null;
      },
      onErr: (failure) => failure,
    );
  }
}
