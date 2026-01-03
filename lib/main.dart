import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'app.dart';
import 'core/theme/theme_controller.dart';
import 'core/services/attendance_service.dart';
import 'data/database_helper.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/signup_screen.dart'; // 1. ADD THIS IMPORT
import 'features/dashboard/main_dashboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyCm57xgXyvRLHTwY5cfDwp_DrwhljUKCno",
      appId: "1:859293807314:android:346d3ab5415259645df30b",
      messagingSenderId: "859293807314",
      projectId: "auto-attendance-624d7",
      storageBucket: "auto-attendance-624d7.firebasestorage.app",
    ),
  );

  await DatabaseHelper.instance.database;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(create: (_) => AttendanceService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Auto Attendance',

      // 2. DEFINE THE ROUTES HERE
      routes: {
        '/signup': (context) => const SignupScreen(),
        '/login': (context) => const LoginScreen(),
      },

      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData) {
            return const MainDashboard();
          }

          return const LoginScreen();
        },
      ),
    );
  }
}
