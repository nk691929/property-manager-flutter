import 'package:flutter_test/flutter_test.dart';
import 'package:property_manager/features/viewings/domain/entities/viewing_enums.dart';
import 'package:property_manager/features/viewings/domain/rules/viewing_workflow.dart';

void main() {
  final now = DateTime.utc(2026, 11, 3, 9);
  final future = now.add(const Duration(days: 1));
  final past = now.subtract(const Duration(hours: 1));

  bool can(
    ViewingStatus from,
    ViewingStatus to, {
    bool client = false,
    bool agent = false,
    DateTime? at,
  }) => ViewingWorkflow.canTransition(
    from: from,
    to: to,
    isClient: client,
    isAgent: agent,
    scheduledAt: at ?? future,
    now: now,
  );

  test('only the agent confirms or declines, and only a pending request', () {
    expect(
      can(ViewingStatus.requested, ViewingStatus.confirmed, agent: true),
      isTrue,
    );
    expect(
      can(ViewingStatus.requested, ViewingStatus.declined, agent: true),
      isTrue,
    );
    expect(
      can(ViewingStatus.requested, ViewingStatus.confirmed, client: true),
      isFalse,
    );
    expect(
      can(ViewingStatus.requested, ViewingStatus.declined, client: true),
      isFalse,
    );
    expect(
      can(ViewingStatus.confirmed, ViewingStatus.declined, agent: true),
      isFalse,
    );
  });

  test('confirming needs the time to still be ahead', () {
    expect(
      can(
        ViewingStatus.requested,
        ViewingStatus.confirmed,
        agent: true,
        at: past,
      ),
      isFalse,
    );
  });

  test('a pending request can be cancelled by the client, not the agent', () {
    expect(
      can(ViewingStatus.requested, ViewingStatus.cancelled, client: true),
      isTrue,
    );
    expect(
      can(ViewingStatus.requested, ViewingStatus.cancelled, agent: true),
      isFalse,
    );
  });

  test('a confirmed viewing can be cancelled by either side', () {
    expect(
      can(ViewingStatus.confirmed, ViewingStatus.cancelled, client: true),
      isTrue,
    );
    expect(
      can(ViewingStatus.confirmed, ViewingStatus.cancelled, agent: true),
      isTrue,
    );
    expect(can(ViewingStatus.confirmed, ViewingStatus.cancelled), isFalse);
  });

  test('only the agent completes, and only after the time has passed', () {
    expect(
      can(
        ViewingStatus.confirmed,
        ViewingStatus.completed,
        agent: true,
        at: past,
      ),
      isTrue,
    );
    expect(
      can(ViewingStatus.confirmed, ViewingStatus.completed, agent: true),
      isFalse,
    );
    expect(
      can(
        ViewingStatus.confirmed,
        ViewingStatus.completed,
        client: true,
        at: past,
      ),
      isFalse,
    );
  });

  test('finished viewings have no moves', () {
    for (final from in [
      ViewingStatus.declined,
      ViewingStatus.cancelled,
      ViewingStatus.completed,
    ]) {
      for (final to in ViewingStatus.values) {
        expect(
          can(from, to, client: true, agent: true, at: past),
          isFalse,
          reason: '${from.name} -> ${to.name}',
        );
      }
    }
  });

  test('nextStatuses lists the buttons in a stable order', () {
    List<ViewingStatus> next(
      ViewingStatus from, {
      bool client = false,
      bool agent = false,
      DateTime? at,
    }) => ViewingWorkflow.nextStatuses(
      from: from,
      isClient: client,
      isAgent: agent,
      scheduledAt: at ?? future,
      now: now,
    );

    expect(next(ViewingStatus.requested, agent: true), [
      ViewingStatus.confirmed,
      ViewingStatus.declined,
    ]);
    expect(next(ViewingStatus.requested, client: true), [
      ViewingStatus.cancelled,
    ]);
    expect(next(ViewingStatus.confirmed, agent: true, at: past), [
      ViewingStatus.cancelled,
      ViewingStatus.completed,
    ]);
  });
}
