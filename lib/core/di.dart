import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/local/local_db.dart';
import '../data/local/photo_storage.dart';
import '../data/local/profile_photo_store.dart';
import '../data/remote/api_client.dart';
import '../data/repositories/repositories_impl.dart';
import '../data/session_store.dart';
import '../data/sync/connectivity_service.dart';
import '../data/sync/sync_service.dart';
import '../domain/repositories.dart';

final getIt = GetIt.instance;

Future<void> setupDi() async {
  final prefs = await SharedPreferences.getInstance();
  final session = SessionStore(prefs, const FlutterSecureStorage());
  final db = LocalDb();
  final photos = PhotoStorage();
  final api = ApiClient(session);
  final conn = ConnectivityService();

  getIt
    ..registerSingleton<PhotoStorage>(photos)
    ..registerSingleton<ProfilePhotoStore>(ProfilePhotoStore(prefs))
    ..registerSingleton<AuthRepository>(
        AuthRepositoryImpl(api, session, db, photos))
    ..registerSingleton<CustomerRepository>(CustomerRepositoryImpl(db))
    ..registerSingleton<SiteRepository>(SiteRepositoryImpl(db))
    ..registerSingleton<NoteRepository>(NoteRepositoryImpl(db))
    ..registerSingleton<SettingsRepository>(SettingsRepositoryImpl(prefs))
    ..registerSingleton<SyncRepository>(SyncRepositoryImpl(
        SyncService(db, api, session, photos), db, conn, session));
}
