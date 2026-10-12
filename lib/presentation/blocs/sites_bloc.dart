import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities.dart';
import '../../domain/repositories.dart';

class SitesState extends Equatable {
  const SitesState({this.sites = const [], this.loading = true});
  final List<Site> sites;
  final bool loading;
  @override
  List<Object?> get props => [sites, loading];
}

abstract class SitesEvent {}

class SitesStarted extends SitesEvent {}

class SiteSaved extends SitesEvent {
  SiteSaved(this.site);
  final Site site;
}

class SiteDeleted extends SitesEvent {
  SiteDeleted(this.id);
  final String id;
}

/// [customerId] == null -> all sites; otherwise only that customer's sites.
class SitesBloc extends Bloc<SitesEvent, SitesState> {
  SitesBloc(this._repo, {this.customerId}) : super(const SitesState()) {
    on<SitesStarted>((e, emit) => emit.forEach<List<Site>>(_repo.watchSites(customerId: customerId),
        onData: (l) => SitesState(sites: l, loading: false)));
    on<SiteSaved>((e, emit) => _repo.save(e.site));
    on<SiteDeleted>((e, emit) => _repo.delete(e.id));
    add(SitesStarted());
  }
  final SiteRepository _repo;
  final String? customerId;
}
