import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities.dart';

/// Token lives in the secure keystore; small non-secret values in SharedPreferences.
class SessionStore {
  SessionStore(this._prefs, this._secure);
  final SharedPreferences _prefs;
  final FlutterSecureStorage _secure;
  String? _token;
  bool _tokenLoaded = false;

  Future<String?> get token async {
    if (!_tokenLoaded) {
      _token = await _secure.read(key: 'token');
      _tokenLoaded = true;
    }
    return _token;
  }

  AppUser? get user {
    final raw = _prefs.getString('user');
    if (raw == null) return null;
    final m = jsonDecode(raw) as Map<String, dynamic>;
    return AppUser(
      id: m['id'] as int,
      name: m['name'] as String,
      email: m['email'] as String,
      profilePhotoUrl: m['profilePhotoUrl'] as String?,
    );
  }

  int? get lastUserId => _prefs.getInt('last_user_id');

  Future<void> save(String token, AppUser u) async {
    _token = token;
    _tokenLoaded = true;
    await _secure.write(key: 'token', value: token);
    await _prefs.setString(
      'user',
      jsonEncode({
        'id': u.id,
        'name': u.name,
        'email': u.email,
        'profilePhotoUrl': u.profilePhotoUrl,
      }),
    );
    await _prefs.setInt('last_user_id', u.id);
  }

  Future<void> clear() async {
    _token = null;
    _tokenLoaded = true;
    await _secure.delete(key: 'token');
    await _prefs.remove('user');
  }

  Future<void> clearAll() async {
    await clear();
    await _prefs.remove('last_user_id');
    await clearSync();
  }

  String? get lastSyncIso => _prefs.getString('last_sync');
  DateTime? get lastSync => lastSyncIso == null ? null : DateTime.tryParse(lastSyncIso!);
  Future<void> setLastSync(DateTime d) => _prefs.setString('last_sync', d.toUtc().toIso8601String());
  Future<void> clearSync() => _prefs.remove('last_sync');
}
