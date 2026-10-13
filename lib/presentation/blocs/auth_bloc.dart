import 'dart:async';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities.dart';
import '../../domain/repositories.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState extends Equatable {
  const AuthState(
      {this.status = AuthStatus.unknown,
      this.user,
      this.busy = false,
      this.error});
  final AuthStatus status;
  final AppUser? user;
  final bool busy;
  final String? error;

  AuthState copyWith({bool? busy, String? error, bool clearError = false}) =>
      AuthState(
          status: status,
          user: user,
          busy: busy ?? this.busy,
          error: clearError ? null : (error ?? this.error));

  @override
  List<Object?> get props => [status, user, busy, error];
}

abstract class AuthEvent {}

class AuthStarted extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  AuthLoginRequested(this.email, this.password);
  final String email, password;
}

class AuthRegisterRequested extends AuthEvent {
  AuthRegisterRequested(this.name, this.email, this.password,
      {this.profilePhoto, this.profilePhotoName = 'profile.jpg'});
  final String name, email, password;
  final Uint8List? profilePhoto;
  final String profilePhotoName;
}

class AuthLogoutRequested extends AuthEvent {}

class AuthSessionExpired extends AuthEvent {}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repo) : super(const AuthState()) {
    on<AuthStarted>((e, emit) async {
      final user = await _repo.currentUser();
      emit(AuthState(
          status: user == null
              ? AuthStatus.unauthenticated
              : AuthStatus.authenticated,
          user: user));
    });
    on<AuthLoginRequested>(
        (e, emit) => _run(
              emit,
              () => _login(e.email, e.password.trim()),
              login: true,
            ));
    on<AuthRegisterRequested>((e, emit) => _run(
          emit,
          () => _repo.register(
            e.name.trim(),
            _normalizeEmail(e.email),
            e.password.trim(),
            profilePhoto: e.profilePhoto,
            profilePhotoName: e.profilePhotoName,
          ),
        ));
    on<AuthLogoutRequested>((e, emit) async {
      try {
        await _repo.logout();
        emit(const AuthState(status: AuthStatus.unauthenticated));
      } catch (_) {
        emit(const AuthState(
          status: AuthStatus.unauthenticated,
          error:
              'You are signed out, but some local data could not be cleared.',
        ));
      }
    });
    on<AuthSessionExpired>((e, emit) async {
      if (state.status != AuthStatus.authenticated) return;
      await _repo.expireSession();
      emit(const AuthState(
          status: AuthStatus.unauthenticated,
          error: 'Session expired. Please sign in again.'));
    });
    _sub = _repo.sessionExpired.listen((_) => add(AuthSessionExpired()));
  }

  final AuthRepository _repo;
  late final StreamSubscription<void> _sub;

  String _normalizeEmail(String email) => email.trim().toLowerCase();

  Future<AppUser> _login(String email, String password) async {
    final typedEmail = email.trim();
    final normalizedEmail = _normalizeEmail(email);
    try {
      return await _repo.login(normalizedEmail, password);
    } on ApiException catch (ex) {
      if (ex.statusCode == 401 && typedEmail != normalizedEmail) {
        return _repo.login(typedEmail, password);
      }
      rethrow;
    }
  }

  Future<void> _run(Emitter<AuthState> emit, Future<AppUser> Function() action,
      {bool login = false}) async {
    emit(state.copyWith(busy: true, clearError: true));
    try {
      final user = await action();
      emit(AuthState(status: AuthStatus.authenticated, user: user));
    } on ApiException catch (ex) {
      final message = login && ex.statusCode == 401
          ? 'Invalid email or password. If this account was created before the Render deploy, create it again first.'
          : ex.message;
      emit(state.copyWith(
          busy: false,
          error: ex.isNetwork
              ? 'You need an internet connection to sign in or register.'
              : message));
    } catch (_) {
      emit(state.copyWith(
          busy: false,
          error:
              'Sign-in failed because the server response was not expected. Please try again.'));
    }
  }

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}
