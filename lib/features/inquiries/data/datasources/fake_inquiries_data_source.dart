import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/features/inquiries/data/datasources/inquiries_data_source.dart';
import 'package:property_manager/features/inquiries/domain/entities/inquiry.dart';
import 'package:property_manager/features/inquiries/domain/entities/inquiry_enums.dart';
import 'package:property_manager/features/inquiries/domain/entities/inquiry_message.dart';
import 'package:property_manager/features/properties/data/datasources/properties_data_source.dart';
import 'package:property_manager/features/properties/domain/entities/property_enums.dart';

/// In-memory backend for dev (no config) and tests. Like the other fakes it
/// does NOT emulate RLS; the database rules are verified against Supabase.
final class FakeInquiriesDataSource implements InquiriesDataSource {
  new({required this._properties});

  final PropertiesDataSource _properties;
  final Map<String, Inquiry> _inquiries = {};
  final Map<String, List<InquiryMessage>> _messages = {};
  int _nextId = 1;

  Inquiry _require(String id) =>
      _inquiries[id] ?? (throw const NotFoundFailure());

  static List<Inquiry> _page(
    Iterable<Inquiry> source, {
    required int offset,
    required int limit,
  }) {
    final sorted = source.toList()
      ..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
    return sorted.skip(offset).take(limit).toList();
  }

  @override
  Future<List<Inquiry>> listForClient(
    String clientId, {
    required int offset,
    required int limit,
  }) async => _page(
    _inquiries.values.where((i) => i.clientId == clientId),
    offset: offset,
    limit: limit,
  );

  @override
  Future<List<Inquiry>> listForAgent(
    String agentId, {
    required int offset,
    required int limit,
  }) async => _page(
    _inquiries.values.where((i) => i.agentId == agentId),
    offset: offset,
    limit: limit,
  );

  @override
  Future<Inquiry> getById(String id) async => _require(id);

  @override
  Future<Inquiry?> findOpen(String clientId, String propertyId) async =>
      _inquiries.values
          .where(
            (i) =>
                i.clientId == clientId &&
                i.propertyId == propertyId &&
                i.isOpen,
          )
          .firstOrNull;

  @override
  Future<List<InquiryMessage>> messages(String inquiryId) async {
    _require(inquiryId);
    return List.of(_messages[inquiryId] ?? const <InquiryMessage>[]);
  }

  @override
  Future<Inquiry> start({
    required String propertyId,
    required String clientId,
    required String body,
  }) async {
    final property = await _properties.getById(propertyId);
    if (property.status != PropertyStatus.published) {
      throw const NotFoundFailure();
    }
    final hasOpen = _inquiries.values.any(
      (i) => i.clientId == clientId && i.propertyId == propertyId && i.isOpen,
    );
    if (hasOpen) throw const ConflictFailure();

    final now = DateTime.now();
    final inquiry = Inquiry(
      id: 'i-${_nextId++}',
      propertyId: propertyId,
      propertyTitle: property.title,
      clientId: clientId,
      status: InquiryStatus.open,
      lastMessageAt: now,
      lastMessagePreview: _preview(body),
      lastSenderId: clientId,
      createdAt: now,
      agentId: property.agentId,
    );
    _inquiries[inquiry.id] = inquiry;
    _messages[inquiry.id] = [_message(inquiry.id, clientId, body, now)];
    return inquiry;
  }

  @override
  Future<InquiryMessage> send(
    String inquiryId, {
    required String senderId,
    required String body,
  }) async {
    final inquiry = _require(inquiryId);
    if (!inquiry.isOpen) throw const ForbiddenFailure();

    final now = DateTime.now();
    final message = _message(inquiryId, senderId, body, now);
    _messages.putIfAbsent(inquiryId, () => []).add(message);
    _inquiries[inquiryId] = inquiry.copyWith(
      lastMessageAt: now,
      lastMessagePreview: _preview(body),
      lastSenderId: senderId,
    );
    return message;
  }

  @override
  Future<Inquiry> close(String inquiryId) async {
    final inquiry = _require(inquiryId);
    return _inquiries[inquiryId] = inquiry.copyWith(
      status: InquiryStatus.closed,
    );
  }

  InquiryMessage _message(
    String inquiryId,
    String senderId,
    String body,
    DateTime at,
  ) => InquiryMessage(
    id: 'm-${_nextId++}',
    inquiryId: inquiryId,
    senderId: senderId,
    body: body.trim(),
    createdAt: at,
  );

  static String _preview(String body) {
    final text = body.trim();
    return text.length <= 120 ? text : text.substring(0, 120);
  }
}
