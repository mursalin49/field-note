import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities.dart';
import '../../domain/repositories.dart';

class NotesState extends Equatable {
  const NotesState({this.notes = const [], this.filter = const NotesFilter(), this.loading = true});
  final List<FieldNote> notes;
  final NotesFilter filter;
  final bool loading;

  NotesState copyWith({List<FieldNote>? notes, NotesFilter? filter, bool? loading}) =>
      NotesState(notes: notes ?? this.notes, filter: filter ?? this.filter, loading: loading ?? this.loading);

  @override
  List<Object?> get props => [notes, filter, loading];
}

abstract class NotesEvent {}

class NotesFilterChanged extends NotesEvent {
  NotesFilterChanged(this.filter);
  final NotesFilter filter;
}

class NoteSaved extends NotesEvent {
  NoteSaved(this.note);
  final FieldNote note;
}

class NoteDeleted extends NotesEvent {
  NoteDeleted(this.id);
  final String id;
}

class NotesBloc extends Bloc<NotesEvent, NotesState> {
  NotesBloc(this._repo, {NotesFilter initial = const NotesFilter()}) : super(NotesState(filter: initial)) {
    // restartable(): a new filter cancels the previous live query
    on<NotesFilterChanged>((e, emit) async {
      emit(state.copyWith(filter: e.filter));
      await emit.forEach<List<FieldNote>>(_repo.watchNotes(e.filter),
          onData: (list) => state.copyWith(notes: list, loading: false));
    }, transformer: restartable());
    on<NoteSaved>((e, emit) => _repo.save(e.note));
    on<NoteDeleted>((e, emit) => _repo.delete(e.id));
    add(NotesFilterChanged(initial));
  }
  final NoteRepository _repo;
}
