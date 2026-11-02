enum ListingType {
  rent,
  sale;

  String get wireName => name;

  static ListingType fromWire(String raw) =>
      ListingType.values.asNameMap()[raw] ?? ListingType.rent;
}

enum PropertyType {
  house,
  apartment,
  room,
  commercial,
  plot;

  String get wireName => name;

  static PropertyType fromWire(String raw) =>
      PropertyType.values.asNameMap()[raw] ?? PropertyType.house;
}

enum AreaUnit {
  sqft,
  sqm,
  marla,
  kanal;

  String get wireName => name;

  static AreaUnit fromWire(String raw) =>
      AreaUnit.values.asNameMap()[raw] ?? AreaUnit.sqft;
}

enum PropertyStatus {
  draft('draft'),
  pendingReview('pending_review'),
  published('published'),
  rejected('rejected'),
  archived('archived');

  new(this.wireName);

  /// Matches the database enum `property_status`.
  final String wireName;

  /// Unknown values degrade to the least actionable status.
  static PropertyStatus fromWire(String raw) =>
      PropertyStatus.values.where((s) => s.wireName == raw).firstOrNull ??
      PropertyStatus.archived;
}

enum PropertySort { newest, priceAsc, priceDesc }
