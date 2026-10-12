import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WatchState<T> extends Equatable {
  const WatchState({this.loaded = false, this.value});
  final bool loaded;
  final T? value; // null + loaded => the record no longer exists
  @override
  List<Object?> get props => [loaded, value];
}

/// Live view of a single record (details screens).
class WatchCubit<T> extends Cubit<WatchState<T>> {
  WatchCubit(Stream<T?> stream) : super(WatchState<T>()) {
    _sub = stream.listen((v) => emit(WatchState<T>(loaded: true, value: v)));
  }
  late final StreamSubscription<T?> _sub;

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}
