import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di.dart';
import 'core/theme.dart';
import 'domain/repositories.dart';
import 'presentation/blocs/auth_bloc.dart';
import 'presentation/blocs/customers_bloc.dart';
import 'presentation/blocs/notes_bloc.dart';
import 'presentation/blocs/settings_cubit.dart';
import 'presentation/blocs/sites_bloc.dart';
import 'presentation/blocs/sync_cubit.dart';
import 'presentation/pages/auth_page.dart';
import 'presentation/pages/home_page.dart';

class FieldNotesApp extends StatelessWidget {
  const FieldNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthBloc(getIt<AuthRepository>())..add(AuthStarted())),
        BlocProvider(create: (_) => SettingsCubit(getIt<SettingsRepository>())),
        BlocProvider(create: (_) => SyncCubit(getIt<SyncRepository>())),
        BlocProvider(create: (_) => CustomersBloc(getIt<CustomerRepository>())),
        BlocProvider(create: (_) => SitesBloc(getIt<SiteRepository>())), // all sites (pickers/filters)
        BlocProvider(create: (_) => NotesBloc(getIt<NoteRepository>())), // notes tab (search + filters)
      ],
      child: MaterialApp(
        title: 'Field Notes',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: BlocConsumer<AuthBloc, AuthState>(
          listenWhen: (a, b) => a.status != b.status,
          listener: (context, state) {
            final sync = context.read<SyncCubit>();
            state.status == AuthStatus.authenticated ? sync.start() : sync.stop();
          },
          builder: (context, state) => switch (state.status) {
            AuthStatus.unknown => const Scaffold(body: Center(child: CircularProgressIndicator())),
            AuthStatus.authenticated => const HomePage(),
            AuthStatus.unauthenticated => const AuthPage(),
          },
        ),
      ),
    );
  }
}
