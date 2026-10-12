import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities.dart';
import '../blocs/customers_bloc.dart';
import '../blocs/notes_bloc.dart';
import '../blocs/sites_bloc.dart';
import '../widgets/dialogs.dart';
import 'site_detail_page.dart';

class SitesPage extends StatefulWidget {
  const SitesPage({super.key});

  @override
  State<SitesPage> createState() => _SitesPageState();
}

class _SitesPageState extends State<SitesPage> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _addSite() async {
    final customers = context.read<CustomersBloc>().state.customers;
    if (customers.isEmpty) {
      showSnack(context, 'Add a customer before creating a site.');
      return;
    }
    final customerId = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Choose a customer'),
        children: [
          for (final customer in customers)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, customer.id),
              child: Text(customer.name),
            ),
        ],
      ),
    );
    if (customerId == null || !mounted) return;
    final bloc = context.read<SitesBloc>();
    await showSiteForm(
      context,
      customerId: customerId,
      onSave: (site) => bloc.add(SiteSaved(site)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _addSite,
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<SitesBloc, SitesState>(
        builder: (context, sitesState) =>
            BlocBuilder<CustomersBloc, CustomersState>(
          builder: (context, customersState) =>
              BlocBuilder<NotesBloc, NotesState>(
            builder: (context, notesState) {
              final query = _search.text.trim().toLowerCase();
              final sites = sitesState.sites.where((site) {
                return query.isEmpty ||
                    site.name.toLowerCase().contains(query) ||
                    site.address.toLowerCase().contains(query) ||
                    site.customerName.toLowerCase().contains(query);
              }).toList();
              final notesBySite = <String, int>{};
              for (final note in notesState.notes) {
                notesBySite.update(note.siteId, (count) => count + 1,
                    ifAbsent: () => 1);
              }

              if (sitesState.loading || customersState.loading) {
                return const Center(child: CircularProgressIndicator());
              }

              final customerNames = {
                for (final customer in customersState.customers)
                  customer.id: customer.name,
              };
              final groups = <String, List<Site>>{};
              for (final site in sites) {
                groups.putIfAbsent(site.customerId, () => []).add(site);
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${sitesState.sites.length} sites for ${customersState.customers.length} customers',
                                style: const TextStyle(
                                  color: Color(0xFF69737C),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text('Sites',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontSize: 30,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF15181C),
                                      )),
                            ],
                          ),
                        ),
                        IconButton.filled(
                          onPressed: _addSite,
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFFFF5A1F),
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                    child: TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Search sites or addresses',
                        prefixIcon: Icon(Icons.search),
                        isDense: true,
                      ),
                    ),
                  ),
                  Expanded(
                    child: sites.isEmpty
                        ? Center(
                            child: Text(query.isEmpty
                                ? 'No sites yet. Add your first site.'
                                : 'No sites match your search.'))
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                            children: [
                              for (final entry in groups.entries) ...[
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 8, 0, 8),
                                  child: Text(
                                    customerNames[entry.key] ?? 'Customer',
                                    style: const TextStyle(
                                      color: Color(0xFF69737C),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                for (final site in entry.value)
                                  Card(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 7),
                                      leading: Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFECEEEC),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        child: const Icon(Icons.place_outlined,
                                            color: Color(0xFF15181C)),
                                      ),
                                      title: Text(site.name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700)),
                                      subtitle: Text(
                                          site.address.isEmpty
                                              ? 'No address'
                                              : site.address,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 9, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFEDE4),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            child: Text(
                                              '${notesBySite[site.id] ?? 0}',
                                              style: const TextStyle(
                                                color: Color(0xFFD9430D),
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.chevron_right,
                                              color: Color(0xFFA5ADB4)),
                                        ],
                                      ),
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              SiteDetailPage(siteId: site.id),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ],
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
