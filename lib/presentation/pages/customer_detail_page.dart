import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/di.dart';
import '../../domain/entities.dart';
import '../../domain/repositories.dart';
import '../blocs/customers_bloc.dart';
import '../blocs/notes_bloc.dart';
import '../blocs/sites_bloc.dart';
import '../blocs/watch_cubit.dart';
import '../widgets/dialogs.dart';
import 'site_detail_page.dart';

class CustomerDetailPage extends StatelessWidget {
  const CustomerDetailPage({super.key, required this.customerId});
  final String customerId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
            create: (_) => WatchCubit<Customer>(
                getIt<CustomerRepository>().watchCustomer(customerId))),
        BlocProvider(
            create: (_) =>
                SitesBloc(getIt<SiteRepository>(), customerId: customerId)),
        BlocProvider(create: (_) => NotesBloc(getIt<NoteRepository>())),
      ],
      child: BlocConsumer<WatchCubit<Customer>, WatchState<Customer>>(
        listener: (context, state) {
          if (state.loaded && state.value == null) {
            Navigator.of(context).maybePop();
          }
        },
        builder: (context, watchState) {
          final customer = watchState.value;
          if (customer == null) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }
          return Scaffold(
            appBar: AppBar(
              title: const Text('Customer'),
              actions: [
                IconButton(
                  tooltip: 'Edit customer',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {
                    final bloc = context.read<CustomersBloc>();
                    showCustomerForm(context,
                        customer: customer,
                        onSave: (updated) => bloc.add(CustomerSaved(updated)));
                  },
                ),
                IconButton(
                  tooltip: 'Delete customer',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final bloc = context.read<CustomersBloc>();
                    final confirmed = await confirmDialog(
                      context,
                      title: 'Delete customer?',
                      message:
                          'This also deletes all of “${customer.name}”\'s sites and their notes.',
                    );
                    if (!confirmed || !context.mounted) return;
                    bloc.add(CustomerDeleted(customer.id));
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: const Text('Add site'),
              onPressed: () {
                final bloc = context.read<SitesBloc>();
                showSiteForm(context,
                    customerId: customer.id,
                    onSave: (site) => bloc.add(SiteSaved(site)));
              },
            ),
            body: BlocBuilder<SitesBloc, SitesState>(
              builder: (context, sitesState) =>
                  BlocBuilder<NotesBloc, NotesState>(
                builder: (context, notesState) {
                  final notes = notesState.notes
                      .where((note) => note.customerId == customer.id)
                      .toList();
                  final inProgress = notes
                      .where((note) => note.status == NoteStatus.inProgress)
                      .length;
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 96),
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 34,
                            backgroundColor: const Color(0xFFE3E9EE),
                            foregroundColor: const Color(0xFF15181C),
                            child: Text(_initials(customer.name),
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.w800)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(customer.name,
                                    style: const TextStyle(
                                        fontSize: 23,
                                        color: Color(0xFF15181C),
                                        fontWeight: FontWeight.w800)),
                                const SizedBox(height: 4),
                                Text(
                                    'Added ${DateFormat('d MMM y').format(customer.updatedAt.toLocal())}',
                                    style: const TextStyle(
                                        color: Color(0xFF69737C),
                                        fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                radius: 18,
                                backgroundColor: Color(0xFFECEEEC),
                                child: Icon(Icons.contact_phone_outlined,
                                    size: 19, color: Color(0xFF15181C)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  customer.contactInfo.isEmpty
                                      ? 'No contact information'
                                      : customer.contactInfo,
                                  style: const TextStyle(
                                      color: Color(0xFF15181C),
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _statCard('${sitesState.sites.length}', 'Sites'),
                          const SizedBox(width: 8),
                          _statCard('${notes.length}', 'Notes'),
                          const SizedBox(width: 8),
                          _statCard('$inProgress', 'In progress',
                              accent: const Color(0xFF1D5FD1)),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          const Expanded(
                            child: Text('Sites',
                                style: TextStyle(
                                    color: Color(0xFF15181C),
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800)),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              final bloc = context.read<SitesBloc>();
                              showSiteForm(context,
                                  customerId: customer.id,
                                  onSave: (site) => bloc.add(SiteSaved(site)));
                            },
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add site'),
                          ),
                        ],
                      ),
                      if (sitesState.loading)
                        const Padding(
                          padding: EdgeInsets.all(28),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (sitesState.sites.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                              child: Text('No sites yet. Add the first one.')),
                        )
                      else
                        for (final site in sitesState.sites)
                          Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              leading: Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECEEEC),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.place_outlined),
                              ),
                              title: Text(site.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (site.address.isNotEmpty)
                                    Text(site.address,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 3),
                                  Text(
                                      '${notes.where((note) => note.siteId == site.id).length} notes',
                                      style: const TextStyle(
                                          color: Color(0xFFD9430D),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                              trailing: const Icon(Icons.chevron_right,
                                  color: Color(0xFFA5ADB4)),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        SiteDetailPage(siteId: site.id)),
                              ),
                            ),
                          ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _statCard(String value, String label, {Color? accent}) => Expanded(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: accent ?? const Color(0xFF15181C))),
                const SizedBox(height: 3),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Color(0xFF69737C), fontSize: 11)),
              ],
            ),
          ),
        ),
      );

  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }
}
