import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePhotoStore extends ChangeNotifier {
  ProfilePhotoStore(this._prefs);

  final SharedPreferences _prefs;

  String? photoPath(int userId) => _prefs.getString(_key(userId));

  Future<void> save(int userId, String path) async {
    final saved = await _prefs.setString(_key(userId), path);
    if (!saved) throw StateError('Could not save the profile photo path.');
    notifyListeners();
  }

  Future<void> remove(int userId) async {
    final removed = await _prefs.remove(_key(userId));
    if (!removed && _prefs.containsKey(_key(userId))) {
      throw StateError('Could not remove the profile photo path.');
    }
    if (removed) notifyListeners();
  }

  String _key(int userId) => 'profile_photo_$userId';
}
