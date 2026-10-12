import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/customers_bloc.dart';
import '../blocs/notes_bloc.dart';
import '../blocs/sites_bloc.dart';
import '../widgets/dialogs.dart';
import 'customer_detail_page.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  final _search = TextEditingController();
  static const _avatarColors = <Color>[
    Color(0xFFE3E9EE),
    Color(0xFFF4E7C5),
    Color(0xFFDCE6F5),
    Color(0xFFE8DDF0),
    Color(0xFFDDEBC9),
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<CustomersBloc, CustomersState>(
        builder: (context, customersState) =>
            BlocBuilder<SitesBloc, SitesState>(
          builder: (context, sitesState) => BlocBuilder<NotesBloc, NotesState>(
            builder: (context, notesState) {
              if (customersState.loading) {
                return const Center(child: CircularProgressIndicator());
              }
              final query = _search.text.trim().toLowerCase();
              final customers = customersState.customers.where((customer) {
                return query.isEmpty ||
                    customer.name.toLowerCase().contains(query) ||
                    customer.contactInfo.toLowerCase().contains(query);
              }).toList();
              final siteCounts = <String, int>{};
              for (final site in sitesState.sites) {
                siteCounts.update(site.customerId, (count) => count + 1,
                    ifAbsent: () => 1);
              }
              final noteCounts = <String, int>{};
              for (final note in notesState.notes) {
                noteCounts.update(note.customerId, (count) => count + 1,
                    ifAbsent: () => 1);
              }

              return Column(
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
                                  '${customersState.customers.length} customers',
                                  style: const TextStyle(
                                      color: Color(0xFF69737C), fontSize: 13)),
                              const SizedBox(height: 4),
                              Text('Customers',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        color: const Color(0xFF15181C),
                                        fontSize: 30,
                                        fontWeight: FontWeight.w800,
                                      )),
                            ],
                          ),
                        ),
                        IconButton.filled(
                          tooltip: 'New customer',
                          onPressed: () {
                            final bloc = context.read<CustomersBloc>();
                            showCustomerForm(context,
                                onSave: (customer) =>
                                    bloc.add(CustomerSaved(customer)));
                          },
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
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
                    child: TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Search customers',
                        prefixIcon: Icon(Icons.search),
                        isDense: true,
                      ),
                    ),
                  ),
                  Expanded(
                    child: customers.isEmpty
                        ? Center(
                            child: Text(query.isEmpty
                                ? 'No customers yet. Add your first customer.'
                                : 'No customers match your search.'))
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                            itemCount: customers.length,
                            itemBuilder: (context, index) {
                              final customer = customers[index];
                              final siteCount = siteCounts[customer.id] ?? 0;
                              final noteCount = noteCounts[customer.id] ?? 0;
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CustomerDetailPage(
                                          customerId: customer.id),
                                    ),
                                  ),
                                  child: SizedBox(
                                    height: 88,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 26,
                                            backgroundColor: _avatarColors[
                                                customer.name.hashCode.abs() %
                                                    _avatarColors.length],
                                            foregroundColor:
                                                const Color(0xFF15181C),
                                            child: Text(
                                                _initials(customer.name),
                                                style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight:
                                                        FontWeight.w800)),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(customer.name,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                        color:
                                                            Color(0xFF15181C),
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w700)),
                                                const SizedBox(height: 3),
                                                Text(
                                                  customer.contactInfo.isEmpty
                                                      ? 'No contact information'
                                                      : customer.contactInfo,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                      color: Color(0xFF69737C),
                                                      fontSize: 12),
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                    '$siteCount ${siteCount == 1 ? 'site' : 'sites'}, $noteCount ${noteCount == 1 ? 'note' : 'notes'}',
                                                    style: const TextStyle(
                                                        color:
                                                            Color(0xFFD9430D),
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w700)),
                                              ],
                                            ),
                                          ),
                                          const Icon(Icons.chevron_right,
                                              color: Color(0xFFA5ADB4)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
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

  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }
}
