import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/di.dart';
import '../../domain/entities.dart';
import '../../domain/repositories.dart';
import '../blocs/notes_bloc.dart';
import '../blocs/sites_bloc.dart';
import '../blocs/watch_cubit.dart';
import '../widgets/dialogs.dart';
import '../widgets/note_tile.dart';
import 'note_detail_page.dart';
import 'note_form_page.dart';

class SiteDetailPage extends StatelessWidget {
  const SiteDetailPage({super.key, required this.siteId});
  final String siteId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => WatchCubit<Site>(getIt<SiteRepository>().watchSite(siteId))),
        // notes of this site only
        BlocProvider(create: (_) => NotesBloc(getIt<NoteRepository>(), initial: NotesFilter(siteId: siteId))),
      ],
      child: BlocConsumer<WatchCubit<Site>, WatchState<Site>>(
        listener: (context, s) {
          if (s.loaded && s.value == null) Navigator.of(context).maybePop();
        },
        builder: (context, s) {
          final site = s.value;
          if (site == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
          return Scaffold(
            appBar: AppBar(
              title: Text(site.name),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {
                    final bloc = context.read<SitesBloc>(); // global bloc from app level
                    showSiteForm(context, customerId: site.customerId, site: site, onSave: (u) => bloc.add(SiteSaved(u)));
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final bloc = context.read<SitesBloc>();
                    final ok = await confirmDialog(context, title: 'Delete site?', message: 'This also deletes all notes of this site.');
                    if (!ok || !context.mounted) return;
                    bloc.add(SiteDeleted(site.id));
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: const Text('New note'),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NoteFormPage(siteId: site.id))),
            ),
            body: BlocBuilder<NotesBloc, NotesState>(builder: (context, state) {
              return ListView(padding: const EdgeInsets.only(bottom: 88), children: [
                Card(
                  margin: const EdgeInsets.all(12),
                  child: Column(children: [
                    ListTile(leading: const Icon(Icons.business), title: Text(site.customerName), subtitle: const Text('Customer')),
                    ListTile(leading: const Icon(Icons.home_outlined), title: Text(site.address.isEmpty ? 'No address' : site.address), subtitle: const Text('Address')),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text('Notes (${state.notes.length})', style: Theme.of(context).textTheme.titleMedium),
                ),
                if (!state.loading && state.notes.isEmpty)
                  const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No notes for this site yet.'))),
                for (final n in state.notes)
                  NoteTile(
                    note: n,
                    showSite: false,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NoteDetailPage(noteId: n.id))),
                  ),
              ]);
            }),
          );
        },
      ),
    );
  }
}
