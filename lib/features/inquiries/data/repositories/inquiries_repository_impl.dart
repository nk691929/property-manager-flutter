import 'package:property_manager/core/result/result.dart';
import 'package:property_manager/core/result/run_catching.dart';
import 'package:property_manager/features/inquiries/data/datasources/inquiries_data_source.dart';
import 'package:property_manager/features/inquiries/domain/entities/inquiry.dart';
import 'package:property_manager/features/inquiries/domain/entities/inquiry_message.dart';
import 'package:property_manager/features/inquiries/domain/repositories/inquiries_repository.dart';

final class InquiriesRepositoryImpl implements InquiriesRepository {
  const new(this._dataSource);

  final InquiriesDataSource _dataSource;

  @override
  Future<Result<List<Inquiry>>> listForClient(
    String clientId, {
    required int offset,
    required int limit,
  }) => runCatching(
    () => _dataSource.listForClient(clientId, offset: offset, limit: limit),
  );

  @override
  Future<Result<List<Inquiry>>> listForAgent(
    String agentId, {
    required int offset,
    required int limit,
  }) => runCatching(
    () => _dataSource.listForAgent(agentId, offset: offset, limit: limit),
  );

  @override
  Future<Result<Inquiry>> getById(String id) =>
      runCatching(() => _dataSource.getById(id));

  @override
  Future<Result<Inquiry?>> findOpen(String clientId, String propertyId) =>
      runCatching(() => _dataSource.findOpen(clientId, propertyId));

  @override
  Future<Result<List<InquiryMessage>>> messages(String inquiryId) =>
      runCatching(() => _dataSource.messages(inquiryId));

  @override
  Future<Result<Inquiry>> start({
    required String propertyId,
    required String clientId,
    required String body,
  }) => runCatching(
    () => _dataSource.start(
      propertyId: propertyId,
      clientId: clientId,
      body: body,
    ),
  );

  @override
  Future<Result<InquiryMessage>> send(
    String inquiryId, {
    required String senderId,
    required String body,
  }) => runCatching(
    () => _dataSource.send(inquiryId, senderId: senderId, body: body),
  );

  @override
  Future<Result<Inquiry>> close(String inquiryId) =>
      runCatching(() => _dataSource.close(inquiryId));
}
