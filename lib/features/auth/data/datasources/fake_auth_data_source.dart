import 'dart:async';

import 'package:property_manager/core/error/failure.dart';
import 'package:property_manager/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:property_manager/features/auth/data/models/profile_model.dart';
import 'package:property_manager/features/auth/domain/entities/role.dart';
import 'package:property_manager/features/auth/domain/validators/auth_validators.dart';

final class FakeAccount {
  const new({
    required this.id,
    required this.email,
    required this.password,
    required this.role,
    this.fullName,
  });

  final String id;
  final String email;
  final String password;
  final Role role;
  final String? fullName;
}

/// Seed data for the in-memory backend. Dev and tests only; prod refuses to
/// start without real backend config (see backend_initializer.dart).
const fakeAccounts = [
  FakeAccount(
    id: 'u-admin',
    email: 'admin@example.com',
    password: 'Password1',
    role: Role.admin,
    fullName: 'Ada Admin',
  ),
  FakeAccount(
    id: 'u-agent',
    email: 'agent@example.com',
    password: 'Password1',
    role: Role.agent,
    fullName: 'Alex Agent',
  ),
  FakeAccount(
    id: 'u-client',
    email: 'client@example.com',
    password: 'Password1',
    role: Role.client,
    fullName: 'Casey Client',
  ),
];

final class FakeAuthDataSource implements AuthRemoteDataSource {
  new({Iterable<FakeAccount> accounts = const []}) {
    for (final account in accounts) {
      _accounts[account.email] = account;
    }
  }

  factory seeded() => FakeAuthDataSource(accounts: fakeAccounts);

  final Map<String, FakeAccount> _accounts = {};
  final StreamController<String?> _changes =
      StreamController<String?>.broadcast();
  String? _currentUserId;

  @override
  Stream<String?> userIdChanges() => Stream.multi((controller) {
    // Replay and subscribe atomically: no gap where an event can be lost.
    controller.add(_currentUserId);
    final subscription = _changes.stream.listen(controller.add);
    controller.onCancel = subscription.cancel;
  });

  @override
  Future<ProfileModel> fetchProfile(String userId) async {
    final account = _accounts.values.where((a) => a.id == userId).firstOrNull;
    if (account == null) throw const NotFoundFailure();
    return ProfileModel(
      id: account.id,
      email: account.email,
      role: account.role,
      fullName: account.fullName,
    );
  }

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final account = _accounts[email.trim().toLowerCase()];
    if (account == null || account.password != password) {
      throw const InvalidCredentialsFailure();
    }
    _setCurrent(account.id);
  }

  @override
  Future<bool> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final key = email.trim().toLowerCase();
    if (_accounts.containsKey(key)) {
      throw ValidationFailure({'email': FieldError.emailTaken.name});
    }
    final account = FakeAccount(
      id: 'u-${_accounts.length + 1}',
      email: key,
      password: password,
      role: Role.client, // same rule as the database trigger
      fullName: fullName,
    );
    _accounts[key] = account;
    _setCurrent(account.id);
    return true;
  }

  @override
  Future<void> signOut() async => _setCurrent(null);

  void _setCurrent(String? id) {
    _currentUserId = id;
    _changes.add(id);
  }

  Future<void> dispose() => _changes.close();
}
