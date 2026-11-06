import 'package:property_manager/features/viewings/domain/entities/viewing.dart';

/// Viewings split into what still needs attention and what is finished.
final class ViewingBoard {
  const new({required this.upcoming, required this.history});

  factory from(Iterable<Viewing> viewings) {
    final upcoming = viewings.where((v) => v.isActive).toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    final history = viewings.where((v) => !v.isActive).toList()
      ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
    return ViewingBoard(upcoming: upcoming, history: history);
  }

  /// Soonest first.
  final List<Viewing> upcoming;

  /// Most recent first.
  final List<Viewing> history;

  bool get isEmpty => upcoming.isEmpty && history.isEmpty;
}
