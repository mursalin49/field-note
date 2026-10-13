import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain/entities.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/notes_bloc.dart';
import '../blocs/sites_bloc.dart';
import '../blocs/sync_cubit.dart';
import '../widgets/dialogs.dart';
import '../widgets/note_tile.dart';
import '../widgets/profile_avatar.dart';
import 'note_detail_page.dart';
import 'note_form_page.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});
  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final _search = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _apply(NotesFilter Function(NotesFilter) change) {
    final bloc = context.read<NotesBloc>();
    bloc.add(NotesFilterChanged(change(bloc.state.filter)));
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300),
        () => _apply((f) => f.copyWith(query: v)));
  }

  void _showFilters(NotesFilter current, List<Site> sites) {
    var status = current.status;
    var siteId = current.siteId;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E5E3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(
                      child: Text('Filter notes',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w800)),
                    ),
                    TextButton(
                      onPressed: () => setSheetState(() {
                        status = null;
                        siteId = null;
                      }),
                      child: const Text('Reset'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text('Status',
                    style: TextStyle(
                        color: Color(0xFF69737C),
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final option in [null, ...NoteStatus.values])
                      ChoiceChip(
                        label: Text(option?.label ?? 'All'),
                        selected: status == option,
                        labelStyle: TextStyle(
                          color: status == option
                              ? Colors.white
                              : const Color(0xFF15181C),
                          fontWeight: status == option
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                        onSelected: (_) => setSheetState(() => status = option),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text('Site',
                    style: TextStyle(
                        color: Color(0xFF69737C),
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 210),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final site in sites)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(site.name),
                          subtitle: Text(site.customerName),
                          trailing: siteId == site.id
                              ? const Icon(Icons.check_circle,
                                  color: Color(0xFFFF5A1F))
                              : const Icon(Icons.circle_outlined,
                                  color: Color(0xFFE2E5E3)),
                          onTap: () => setSheetState(() =>
                              siteId = siteId == site.id ? null : site.id),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      _apply((filter) => filter.copyWith(
                            status: status,
                            clearStatus: status == null,
                            siteId: siteId,
                            clearSite: siteId == null,
                          ));
                      Navigator.pop(sheetContext);
                    },
                    child: Text(
                        'Show ${context.read<NotesBloc>().state.notes.length} notes'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sites = context.watch<SitesBloc>().state.sites;
    return BlocBuilder<NotesBloc, NotesState>(builder: (context, state) {
      final f = state.filter;
      return Scaffold(
        floatingActionButton: FloatingActionButton(
          tooltip: 'New note',
          child: const Icon(Icons.add, size: 28),
          onPressed: () {
            if (sites.isEmpty) {
              showSnack(
                  context, 'Add a customer and a site first (Customers tab).');
              return;
            }
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const NoteFormPage()));
          },
        ),
        body: Column(children: [
          const _NotesHeader(),
          const _NotesSyncSummary(),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 10),
            child: TextField(
              controller: _search,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search title, site or customer',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_search.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _search.clear();
                          _apply((f) => f.copyWith(query: ''));
                          setState(() {});
                        },
                      ),
                    IconButton(
                      tooltip: 'Filter notes',
                      icon: const Icon(Icons.tune_rounded),
                      onPressed: () => _showFilters(f, sites),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
            child: Row(children: [
              FilterChip(
                  label: Text('All ${state.notes.length}'),
                  selected: f.status == null,
                  labelStyle: TextStyle(
                    color: f.status == null
                        ? Colors.white
                        : const Color(0xFF15181C),
                    fontWeight:
                        f.status == null ? FontWeight.w600 : FontWeight.w500,
                  ),
                  onSelected: (_) =>
                      _apply((f) => f.copyWith(clearStatus: true))),
              for (final s in NoteStatus.values) ...[
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(s.label),
                  selected: f.status == s,
                  labelStyle: TextStyle(
                    color:
                        f.status == s ? Colors.white : const Color(0xFF15181C),
                    fontWeight:
                        f.status == s ? FontWeight.w600 : FontWeight.w500,
                  ),
                  onSelected: (sel) => _apply((f) => sel
                      ? f.copyWith(status: s)
                      : f.copyWith(clearStatus: true)),
                ),
              ],
            ]),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: state.loading
                ? const Center(child: CircularProgressIndicator())
                : state.notes.isEmpty
                    ? Center(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  f.isActive
                                      ? Icons.search_off
                                      : Icons.note_add_outlined,
                                  size: 42,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  f.isActive
                                      ? 'No notes match your search/filters.'
                                      : 'Your field journal starts here',
                                  textAlign: TextAlign.center,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  f.isActive
                                      ? 'Try changing a filter or search term.'
                                      : 'Create a note to capture the details that matter.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 88),
                        itemCount: state.notes.length,
                        itemBuilder: (_, i) {
                          final n = state.notes[i];
                          return NoteTile(
                            note: n,
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        NoteDetailPage(noteId: n.id))),
                          );
                        },
                      ),
          ),
        ]),
      );
    });
  }
}

class _NotesHeader extends StatelessWidget {
  const _NotesHeader();

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthBloc, AppUser?>((bloc) => bloc.state.user);
    final name = user?.name.split(' ').first ?? 'there';
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Good morning, $name',
                    style: const TextStyle(
                        color: Color(0xFF69737C), fontSize: 13)),
                const SizedBox(height: 4),
                Text('Field Notes',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: const Color(0xFF15181C),
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                        )),
              ],
            ),
          ),
          ProfileAvatar(
            name: user?.name ?? '',
            userId: user?.id,
            radius: 22,
          ),
        ],
      ),
    );
  }
}

class _NotesSyncSummary extends StatelessWidget {
  const _NotesSyncSummary();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncCubit, SyncState>(builder: (context, sync) {
      final offline = !sync.online;
      final error = sync.error != null;
      final background = offline
          ? const Color(0xFFFFF1D6)
          : error
              ? const Color(0xFFFDECE9)
              : const Color(0xFFE4F3EB);
      final accent = offline
          ? const Color(0xFFB45309)
          : error
              ? const Color(0xFFC9301C)
              : const Color(0xFF0E7A4F);
      final title = sync.syncing
          ? 'Syncing changes'
          : offline
              ? 'You’re offline'
              : error
                  ? 'Sync needs attention'
                  : sync.pending > 0
                      ? '${sync.pending} changes waiting to sync'
                      : 'All changes synced';
      final subtitle = offline
          ? 'Changes are saved on this device'
          : error
              ? sync.error!
              : sync.pending > 0
                  ? 'They’ll sync when you reconnect'
                  : sync.lastSync == null
                      ? 'Ready to sync when needed'
                      : 'Last sync ${DateFormat('h:mm a').format(sync.lastSync!.toLocal())}';

      return Container(
        margin: const EdgeInsets.fromLTRB(24, 2, 24, 0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
          border: offline
              ? const Border.fromBorderSide(
                  BorderSide(color: Color(0xFFF3D79B)))
              : null,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: offline ? Colors.white : accent,
              child: Icon(
                offline
                    ? Icons.cloud_off_outlined
                    : error
                        ? Icons.error_outline
                        : Icons.check,
                size: 17,
                color: offline ? accent : Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Color(0xFF15181C),
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Color(0xFF69737C), fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
