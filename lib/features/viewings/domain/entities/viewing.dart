import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:property_manager/features/viewings/domain/entities/viewing_enums.dart';

part 'viewing.freezed.dart';

@freezed
abstract class Viewing with _$Viewing {
  const factory({
    required String id,
    required String propertyId,
    required String propertyTitle,
    required String clientId,
    required DateTime scheduledAt,
    required ViewingStatus status,
    required DateTime createdAt,
    required DateTime updatedAt,

    /// The listing's CURRENT agent, read from the property when the viewing is
    /// loaded (not stored on the viewing). Null if the property is hidden.
    String? agentId,
    String? declineReason,
  }) = _Viewing;
  const new _();

  /// Requested or confirmed: still something to act on.
  bool get isActive =>
      status == ViewingStatus.requested || status == ViewingStatus.confirmed;
}
