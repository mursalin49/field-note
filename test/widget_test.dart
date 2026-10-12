import 'dart:async';

import 'package:field_notes/domain/entities.dart';
import 'package:field_notes/domain/repositories.dart';
import 'package:field_notes/presentation/blocs/auth_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _AuthRepository implements AuthRepository {
  _AuthRepository({this.failure});

  final ApiException? failure;
  final _expired = StreamController<void>.broadcast();
  final user =
      const AppUser(id: 7, name: 'Field Worker', email: 'worker@example.com');

  @override
  Stream<void> get sessionExpired => _expired.stream;

  @override
  Future<AppUser?> currentUser() async => null;

  @override
  Future<AppUser> login(String email, String password) async {
    if (failure != null) throw failure!;
    return user;
  }

  @override
  Future<AppUser> register(String name, String email, String password) async {
    if (failure != null) throw failure!;
    return user;
  }

  @override
  Future<void> logout() async {}

  @override
  Future<void> expireSession() async {}

  Future<void> dispose() => _expired.close();
}

void main() {
  test('register authenticates and logout returns to unauthenticated state',
      () async {
    final repository = _AuthRepository();
    final bloc = AuthBloc(repository);

    final authenticated = bloc.stream
        .firstWhere((state) => state.status == AuthStatus.authenticated);
    bloc.add(
        AuthRegisterRequested('Field Worker', 'worker@example.com', 'secret1'));
    expect((await authenticated).user, repository.user);

    final signedOut = bloc.stream
        .firstWhere((state) => state.status == AuthStatus.unauthenticated);
    bloc.add(AuthLogoutRequested());
    expect((await signedOut).status, AuthStatus.unauthenticated);

    await bloc.close();
    await repository.dispose();
  });

  test('login errors are exposed in the auth state', () async {
    final repository = _AuthRepository(
        failure: ApiException('Invalid email or password', statusCode: 401));
    final bloc = AuthBloc(repository);

    final failed = bloc.stream.firstWhere((state) => state.error != null);
    bloc.add(AuthLoginRequested('worker@example.com', 'wrong-password'));
    expect((await failed).error, 'Invalid email or password');

    await bloc.close();
    await repository.dispose();
  });
}
