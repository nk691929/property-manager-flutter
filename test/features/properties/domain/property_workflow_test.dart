import 'package:flutter_test/flutter_test.dart';
import 'package:property_manager/features/properties/domain/entities/property_enums.dart';
import 'package:property_manager/features/properties/domain/rules/property_workflow.dart';

void main() {
  bool can(
    PropertyStatus from,
    PropertyStatus to, {
    bool admin = false,
    bool approval = true,
  }) => PropertyWorkflow.canTransition(
    from: from,
    to: to,
    asAdmin: admin,
    approvalRequired: approval,
  );

  group('agent', () {
    test('must go through review while approval is required', () {
      expect(can(PropertyStatus.draft, PropertyStatus.pendingReview), isTrue);
      expect(can(PropertyStatus.draft, PropertyStatus.published), isFalse);
    });

    test('can publish directly when approval is off', () {
      expect(
        can(PropertyStatus.draft, PropertyStatus.published, approval: false),
        isTrue,
      );
      expect(
        can(
          PropertyStatus.draft,
          PropertyStatus.pendingReview,
          approval: false,
        ),
        isFalse,
      );
    });

    test('cannot approve, reject or self-reject', () {
      expect(
        can(PropertyStatus.pendingReview, PropertyStatus.published),
        isFalse,
      );
      expect(
        can(PropertyStatus.pendingReview, PropertyStatus.rejected),
        isFalse,
      );
    });

    test('can withdraw, unpublish, archive and restore', () {
      expect(can(PropertyStatus.pendingReview, PropertyStatus.draft), isTrue);
      expect(can(PropertyStatus.published, PropertyStatus.draft), isTrue);
      expect(can(PropertyStatus.published, PropertyStatus.archived), isTrue);
      expect(can(PropertyStatus.archived, PropertyStatus.draft), isTrue);
    });

    test('same status is not a transition', () {
      expect(can(PropertyStatus.draft, PropertyStatus.draft), isFalse);
    });
  });

  group('admin', () {
    test('can approve and reject pending listings', () {
      expect(
        can(
          PropertyStatus.pendingReview,
          PropertyStatus.published,
          admin: true,
        ),
        isTrue,
      );
      expect(
        can(PropertyStatus.pendingReview, PropertyStatus.rejected, admin: true),
        isTrue,
      );
    });

    test('is offered sensible moves only', () {
      expect(
        PropertyWorkflow.nextStatuses(
          from: PropertyStatus.pendingReview,
          asAdmin: true,
          approvalRequired: true,
        ),
        [PropertyStatus.published, PropertyStatus.rejected],
      );
    });
  });

  test('agent gets only legal moves as buttons', () {
    expect(
      PropertyWorkflow.nextStatuses(
        from: PropertyStatus.draft,
        asAdmin: false,
        approvalRequired: true,
      ),
      [PropertyStatus.pendingReview, PropertyStatus.archived],
    );
  });

  test('only drafts and rejected listings are editable by owners', () {
    for (final status in PropertyStatus.values) {
      expect(
        PropertyWorkflow.isEditableByOwner(status),
        status == PropertyStatus.draft || status == PropertyStatus.rejected,
        reason: status.name,
      );
    }
  });
}
