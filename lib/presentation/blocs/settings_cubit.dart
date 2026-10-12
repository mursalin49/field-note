import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities.dart';
import '../../domain/repositories.dart';

/// State = the "Default Note Status". Stored locally (SharedPreferences), never synced.
class SettingsCubit extends Cubit<NoteStatus> {
  SettingsCubit(this._repo) : super(_repo.defaultStatus);
  final SettingsRepository _repo;

  Future<void> setDefaultStatus(NoteStatus s) async {
    await _repo.setDefaultStatus(s);
    emit(s);
  }
}
