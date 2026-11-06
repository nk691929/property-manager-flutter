enum InquiryStatus {
  open,
  closed;

  String get wireName => name;

  /// Unknown values degrade to closed (nothing can be sent into them).
  static InquiryStatus fromWire(String raw) =>
      InquiryStatus.values.asNameMap()[raw] ?? InquiryStatus.closed;
}
