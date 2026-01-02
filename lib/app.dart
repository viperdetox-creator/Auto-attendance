import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'routes/app_routes.dart';
import 'shared/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // 🔥 THIS IS THE KEY LINE
      themeMode: themeController.themeMode,

      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,

      initialRoute: AppRoutes.login,
      routes: AppRoutes.routes,
    );
  }
}
