import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/theme/theme_controller.dart';
import 'data/database_helper.dart';

Future<void> main() async {
  // Ensures Flutter engine is ready before async calls
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite database
  await DatabaseHelper.instance.database;

  // Start the app with Provider
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeController(),
      child: const MyApp(),
    ),
  );
}
