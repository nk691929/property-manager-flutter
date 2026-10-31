/// Wire contract: [name] is stored in the database enum `user_role`.
/// Renaming a value is a breaking change (a test pins this).
enum Role {
  admin,
  agent,
  client;

  String get wireName => name;

  /// Unknown values degrade to the least-privileged role.
  static Role fromWire(String raw) =>
      Role.values.asNameMap()[raw] ?? Role.client;
}
