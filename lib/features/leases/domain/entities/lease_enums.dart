enum LeaseStatus {
  active,
  ended;

  String get wireName => name;

  /// Unknown values degrade to ended (nothing can be done to them).
  static LeaseStatus fromWire(String raw) =>
      LeaseStatus.values.asNameMap()[raw] ?? LeaseStatus.ended;
}

enum PaymentMethod {
  cash('cash'),
  bankTransfer('bank_transfer'),
  cheque('cheque'),
  other('other');

  new(this.wireName);

  /// Matches the database enum `payment_method`.
  final String wireName;

  static PaymentMethod fromWire(String raw) =>
      PaymentMethod.values.where((m) => m.wireName == raw).firstOrNull ??
      PaymentMethod.other;
}

/// Derived from the charge, its payments and today's date. Never stored.
enum ChargeStatus { due, partlyPaid, paid, overdue, cancelled }
