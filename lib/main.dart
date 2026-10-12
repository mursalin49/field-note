import 'package:flutter/material.dart';

import 'app.dart';
import 'core/di.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDi();
  runApp(const FieldNotesApp());
}
