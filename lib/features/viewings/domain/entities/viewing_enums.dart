enum ViewingStatus {
  requested,
  confirmed,
  declined,
  cancelled,
  completed;

  String get wireName => name;

  /// Unknown values degrade to cancelled: inactive, with no actions offered.
  static ViewingStatus fromWire(String raw) =>
      ViewingStatus.values.asNameMap()[raw] ?? ViewingStatus.cancelled;
}
