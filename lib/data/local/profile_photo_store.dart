import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../remote/api_client.dart';
import 'photo_storage.dart';

class ProfilePhotoStore extends ChangeNotifier {
  ProfilePhotoStore(this._prefs, this._api, this._photos);

  final SharedPreferences _prefs;
  final ApiClient _api;
  final PhotoStorage _photos;
  final _pendingSync = <int, Future<void>>{};

  String? photoPath(int userId) => _prefs.getString(_key(userId));

  Future<void> synchronize(int userId) {
    return _pendingSync.putIfAbsent(userId, () async {
      try {
        await _synchronize(userId);
      } finally {
        _pendingSync.remove(userId);
      }
    });
  }

  Future<void> _synchronize(int userId) async {
    final profile = await _api.getProfile();
    final remoteUrl = profile['profilePhotoUrl'] as String?;
    final localPath = photoPath(userId);
    if (remoteUrl == null) {
      if (localPath == null) return;
      if (_prefs.getString(_remoteKey(userId)) != null) {
        await _photos.deleteProfile(localPath);
        await _prefs.remove(_key(userId));
        await _prefs.remove(_remoteKey(userId));
        notifyListeners();
        return;
      }
      final bytes = await _photos.readBytes(localPath);
      if (bytes == null) {
        await remove(userId);
        return;
      }
      await upload(userId, bytes,
          filename: PhotoStorage.mimeTypeFromPath(localPath)
              .replaceFirst('image/', 'profile.'));
      return;
    }

    if (_prefs.getString(_remoteKey(userId)) == remoteUrl &&
        localPath != null &&
        await _photos.readBytes(localPath) != null) {
      return;
    }
    final bytes = await _api.downloadProfilePhoto();
    final path =
        await _photos.persistProfileBytes(bytes, mimeType: _mimeType(remoteUrl));
    await _save(userId, path, remoteUrl);
  }

  Future<void> upload(int userId, Uint8List bytes,
      {String filename = 'profile.jpg'}) async {
    final response = await _api.uploadProfilePhoto(bytes, filename: filename);
    final remoteUrl = response['profilePhotoUrl'] as String?;
    final path = await _photos.persistProfileBytes(
      bytes,
      mimeType: _mimeType(filename),
    );
    await _save(userId, path, remoteUrl);
  }

  Future<void> save(int userId, String path) async {
    final saved = await _prefs.setString(_key(userId), path);
    if (!saved) throw StateError('Could not save the profile photo path.');
    notifyListeners();
  }

  Future<void> remove(int userId) async {
    await _api.deleteProfilePhoto();
    await _photos.deleteProfile(photoPath(userId));
    final removed = await _prefs.remove(_key(userId));
    await _prefs.remove(_remoteKey(userId));
    if (!removed && _prefs.containsKey(_key(userId))) {
      throw StateError('Could not remove the profile photo path.');
    }
    if (removed) notifyListeners();
  }

  Future<void> cacheRegistrationPhoto(
      int userId, Uint8List bytes, String? remoteUrl) async {
    final path = await _photos.persistProfileBytes(
      bytes,
      mimeType: _mimeType(remoteUrl ?? 'profile.jpg'),
    );
    await _save(userId, path, remoteUrl);
  }

  Future<void> _save(int userId, String path, String? remoteUrl) async {
    final oldPath = photoPath(userId);
    final saved = await _prefs.setString(_key(userId), path);
    if (!saved) throw StateError('Could not save the profile photo path.');
    if (remoteUrl != null) {
      final urlSaved = await _prefs.setString(_remoteKey(userId), remoteUrl);
      if (!urlSaved) throw StateError('Could not save the profile photo URL.');
    } else {
      await _prefs.remove(_remoteKey(userId));
    }
    if (oldPath != path) await _photos.deleteProfile(oldPath);
    notifyListeners();
  }

  String _mimeType(String value) {
    final lower = value.toLowerCase().split('?').first;
    if (lower.endsWith('.png') || lower == 'image/png') return 'image/png';
    if (lower.endsWith('.webp') || lower == 'image/webp') return 'image/webp';
    return 'image/jpeg';
  }

  String _key(int userId) => 'profile_photo_$userId';
  String _remoteKey(int userId) => 'profile_photo_url_$userId';
}
