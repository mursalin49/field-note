import 'dart:async';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities.dart';
import '../../domain/repositories.dart';
import '../local/local_db.dart';
import '../local/photo_storage.dart';
import '../local/profile_photo_store.dart';
import '../remote/api_client.dart';
import '../session_store.dart';
import '../sync/connectivity_service.dart';
import '../sync/sync_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(
      this._api, this._session, this._db, this._photos, this._profilePhotos);
  final ApiClient _api;
  final SessionStore _session;
  final LocalDb _db;
  final PhotoStorage _photos;
  final ProfilePhotoStore _profilePhotos;

  @override
  Stream<void> get sessionExpired => _api.unauthorized;

  @override
  Future<AppUser?> currentUser() async =>
      await _session.token == null ? null : _session.user;

  @override
  Future<AppUser> login(String email, String password) async =>
      _finish(await _api
          .post('/api/auth/login', {'email': email, 'password': password}));

  @override
  Future<AppUser> register(String name, String email, String password,
          {Uint8List? profilePhoto,
          String profilePhotoName = 'profile.jpg'}) async =>
      _finish(
          await _api.register(
            {'name': name, 'email': email, 'password': password},
            profilePhoto: profilePhoto,
            filename: profilePhotoName,
          ),
          profilePhoto: profilePhoto);

  Future<AppUser> _finish(Map<String, dynamic> r,
      {Uint8List? profilePhoto}) async {
    final token = r['token'];
    final userId = r['userId'];
    final name = r['name'];
    final email = r['email'];
    final rawProfilePhotoUrl = r['profilePhotoUrl'];
    if (token is! String ||
        token.isEmpty ||
        userId is! num ||
        name is! String ||
        email is! String ||
        (rawProfilePhotoUrl != null && rawProfilePhotoUrl is! String)) {
      throw ApiException(
          'Sign-in failed because the server response was incomplete.');
    }
    final profilePhotoUrl =
        rawProfilePhotoUrl == null ? null : rawProfilePhotoUrl as String;

    final user = AppUser(
        id: userId.toInt(),
        name: name,
        email: email,
        profilePhotoUrl: profilePhotoUrl);
    // A different account on this device: never show/sync the previous user's data.
    if (_session.lastUserId != null && _session.lastUserId != user.id) {
      await _db.wipe();
      await _photos.deleteAll();
      await _session.clearSync();
    }
    await _session.save(token, user);
    if (profilePhoto != null) {
      await _profilePhotos.cacheRegistrationPhoto(
          user.id, profilePhoto, user.profilePhotoUrl);
    }
    return user;
  }

  @override
  Future<void> logout() async {
    await _session.clear();
    try {
      await _db.wipe();
      await _photos.deleteAll();
    } finally {
      await _session.clearAll();
    }
  }

  /// Token expired: ask for a new login but KEEP local data and the unsynced queue.
  @override
  Future<void> expireSession() => _session.clear();
}

class CustomerRepositoryImpl implements CustomerRepository {
  CustomerRepositoryImpl(this._db);
  final LocalDb _db;
  @override
  Stream<List<Customer>> watchCustomers() => _db.watchCustomers();
  @override
  Stream<Customer?> watchCustomer(String id) => _db.watchCustomer(id);
  @override
  Future<void> save(Customer c) => _db.saveCustomer(c, queue: true);
  @override
  Future<void> delete(String id) => _db.deleteCustomer(id, queue: true);
}

class SiteRepositoryImpl implements SiteRepository {
  SiteRepositoryImpl(this._db);
  final LocalDb _db;
  @override
  Stream<List<Site>> watchSites({String? customerId}) =>
      _db.watchSites(customerId: customerId);
  @override
  Stream<Site?> watchSite(String id) => _db.watchSite(id);
  @override
  Future<void> save(Site s) => _db.saveSite(s, queue: true);
  @override
  Future<void> delete(String id) => _db.deleteSite(id, queue: true);
}

class NoteRepositoryImpl implements NoteRepository {
  NoteRepositoryImpl(this._db);
  final LocalDb _db;
  @override
  Stream<List<FieldNote>> watchNotes(NotesFilter f) => _db.watchNotes(f);
  @override
  Stream<FieldNote?> watchNote(String id) => _db.watchNote(id);

  @override
  Future<void> save(FieldNote n) async {
    final old = await _db.getNote(n.id);
    final photoChanged = n.photoPath != null && n.photoPath != old?.photoPath;
    await _db.saveNote(n, queue: true, queuePhoto: photoChanged);
  }

  @override
  Future<void> delete(String id) => _db.deleteNote(id, queue: true);
}

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._prefs);
  final SharedPreferences _prefs; // local only, never synced
  static const _key = 'default_note_status';

  @override
  NoteStatus get defaultStatus => NoteStatus.fromApi(_prefs.getString(_key));

  @override
  Future<void> setDefaultStatus(NoteStatus s) =>
      _prefs.setString(_key, s.apiValue);
}

class SyncRepositoryImpl implements SyncRepository {
  SyncRepositoryImpl(this._service, this._db, this._conn, this._session);
  final SyncService _service;
  final LocalDb _db;
  final ConnectivityService _conn;
  final SessionStore _session;

  @override
  Future<void> sync() => _service.sync();
  @override
  Stream<int> watchPendingCount() => _db.watchPendingCount();
  @override
  Stream<void> get localChanges => _db.localChanges;
  @override
  Stream<bool> get onlineChanges => _conn.onlineChanges;
  @override
  Future<bool> get isOnline => _conn.isOnline;
  @override
  DateTime? get lastSync => _session.lastSync;
}
