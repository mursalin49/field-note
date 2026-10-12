import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/config.dart';
import '../../domain/repositories.dart';

class SyncState extends Equatable {
  const SyncState({this.online = true, this.syncing = false, this.pending = 0, this.lastSync, this.error});
  final bool online;
  final bool syncing;
  final int pending;
  final DateTime? lastSync;
  final String? error;

  SyncState copyWith({bool? online, bool? syncing, int? pending, DateTime? lastSync, String? error, bool clearError = false}) =>
      SyncState(
        online: online ?? this.online,
        syncing: syncing ?? this.syncing,
        pending: pending ?? this.pending,
        lastSync: lastSync ?? this.lastSync,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props => [online, syncing, pending, lastSync, error];
}

/// Triggers: app start / login, connectivity restored, any local change (debounced), periodic timer, manual.
class SyncCubit extends Cubit<SyncState> {
  SyncCubit(this._repo) : super(const SyncState());
  final SyncRepository _repo;
  final _subs = <StreamSubscription<dynamic>>[];
  Timer? _timer;
  Timer? _debounce;

  Future<void> start() async {
    stop();
    emit(state.copyWith(online: await _repo.isOnline, lastSync: _repo.lastSync));
    _subs
      ..add(_repo.onlineChanges.listen((online) {
        emit(state.copyWith(online: online));
        if (online) sync();
      }))
      ..add(_repo.watchPendingCount().listen((n) => emit(state.copyWith(pending: n))))
      ..add(_repo.localChanges.listen((_) {
        _debounce?.cancel();
        _debounce = Timer(const Duration(seconds: 1), sync);
      }));
    _timer = Timer.periodic(AppConfig.syncInterval, (_) => sync());
    unawaited(sync());
  }

  void stop() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    _timer?.cancel();
    _debounce?.cancel();
  }

  Future<void> sync() async {
    if (state.syncing || isClosed) return;
    emit(state.copyWith(syncing: true, clearError: true));
    try {
      await _repo.sync();
      if (!isClosed) emit(state.copyWith(syncing: false, online: true, lastSync: DateTime.now()));
    } on ApiException catch (e) {
      if (!isClosed) emit(state.copyWith(syncing: false, online: e.isNetwork ? false : state.online, error: e.message));
    } catch (e) {
      if (!isClosed) emit(state.copyWith(syncing: false, error: 'Sync failed'));
    }
  }

  @override
  Future<void> close() {
    stop();
    return super.close();
  }
}
