import 'package:property_manager/core/backend/supabase_failure_mapper.dart';
import 'package:property_manager/features/inquiries/data/datasources/inquiries_data_source.dart';
import 'package:property_manager/features/inquiries/data/inquiry_json.dart';
import 'package:property_manager/features/inquiries/domain/entities/inquiry.dart';
import 'package:property_manager/features/inquiries/domain/entities/inquiry_enums.dart';
import 'package:property_manager/features/inquiries/domain/entities/inquiry_message.dart';
import 'package:property_manager/features/inquiries/domain/paging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final class SupabaseInquiriesDataSource implements InquiriesDataSource {
  const new(this._client);

  final SupabaseClient _client;

  static const _inquiries = 'inquiries';
  static const _messages = 'inquiry_messages';

  @override
  Future<List<Inquiry>> listForClient(
    String clientId, {
    required int offset,
    required int limit,
  }) => supabaseGuard(() async {
    final rows = await _client
        .from(_inquiries)
        .select(inquirySelect)
        .eq('client_id', clientId)
        .order('last_message_at', ascending: false)
        .order('id', ascending: true)
        .range(offset, offset + limit - 1);
    return rows.map(inquiryFromJson).toList();
  });

  @override
  Future<List<Inquiry>> listForAgent(
    String agentId, {
    required int offset,
    required int limit,
  }) => supabaseGuard(() async {
    // Inner join + filter on the embedded column = "listings I own now".
    final rows = await _client
        .from(_inquiries)
        .select(inquirySelectInner)
        .eq('properties.agent_id', agentId)
        .order('last_message_at', ascending: false)
        .order('id', ascending: true)
        .range(offset, offset + limit - 1);
    return rows.map(inquiryFromJson).toList();
  });

  @override
  Future<Inquiry> getById(String id) => supabaseGuard(() async {
    final row = await _client
        .from(_inquiries)
        .select(inquirySelect)
        .eq('id', id)
        .single();
    return inquiryFromJson(row);
  });

  @override
  Future<Inquiry?> findOpen(String clientId, String propertyId) =>
      supabaseGuard(() async {
        final row = await _client
            .from(_inquiries)
            .select(inquirySelect)
            .eq('client_id', clientId)
            .eq('property_id', propertyId)
            .eq('status', InquiryStatus.open.wireName)
            .maybeSingle();
        return row == null ? null : inquiryFromJson(row);
      });

  @override
  Future<List<InquiryMessage>> messages(String inquiryId) =>
      supabaseGuard(() async {
        final rows = await _client
            .from(_messages)
            .select()
            .eq('inquiry_id', inquiryId)
            .order('created_at', ascending: true)
            .order('id', ascending: true)
            .limit(inquiryMessageLimit);
        return rows.map(messageFromJson).toList();
      });

  @override
  Future<Inquiry> start({
    required String propertyId,
    required String clientId,
    required String body,
  }) => supabaseGuard(() async {
    // One transaction creates the inquiry and its first message. The
    // database takes the client from the session; [clientId] is ignored.
    final dynamic id = await _client.rpc<dynamic>(
      'create_inquiry',
      params: {'p_property_id': propertyId, 'p_body': body},
    );
    return await getById(id as String);
  });

  @override
  Future<InquiryMessage> send(
    String inquiryId, {
    required String senderId,
    required String body,
  }) => supabaseGuard(() async {
    final row = await _client
        .from(_messages)
        .insert({'inquiry_id': inquiryId, 'sender_id': senderId, 'body': body})
        .select()
        .single();
    return messageFromJson(row);
  });

  @override
  Future<Inquiry> close(String inquiryId) => supabaseGuard(() async {
    final row = await _client
        .from(_inquiries)
        .update({'status': InquiryStatus.closed.wireName})
        .eq('id', inquiryId)
        .select(inquirySelect)
        .single();
    return inquiryFromJson(row);
  });
}
