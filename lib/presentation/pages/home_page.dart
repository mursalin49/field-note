import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/di.dart';
import '../../domain/repositories.dart';
import '../blocs/notes_bloc.dart';
import 'customers_page.dart';
import 'notes_page.dart';
import 'sites_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final _pages = <Widget>[
    const NotesPage(),
    BlocProvider(
      create: (_) => NotesBloc(getIt<NoteRepository>()),
      child: const CustomersPage(),
    ),
    BlocProvider(
      create: (_) => NotesBloc(getIt<NoteRepository>()),
      child: const SitesPage(),
    ),
    const SettingsPage(),
  ];

  static const _destinations = <NavigationDestination>[
    NavigationDestination(
      icon: Icon(Icons.sticky_note_2_outlined),
      selectedIcon: Icon(Icons.sticky_note_2),
      label: 'Notes',
    ),
    NavigationDestination(
      icon: Icon(Icons.business_outlined),
      selectedIcon: Icon(Icons.business),
      label: 'Customers',
    ),
    NavigationDestination(
      icon: Icon(Icons.place_outlined),
      selectedIcon: Icon(Icons.place),
      label: 'Sites',
    ),
    NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: 'Settings',
    ),
  ];

  int _selectedIndex = 0;

  void _onTabSelected(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: true,
        child: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: NavigationBar(
          height: 76,
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onTabSelected,
          destinations: _destinations,
        ),
      ),
    );
  }
}
