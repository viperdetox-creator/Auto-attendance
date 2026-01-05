import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Internal Imports
import 'core/theme/theme_controller.dart';
import 'core/services/attendance_service.dart';
import 'data/database_helper.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/signup_screen.dart';
import 'features/dashboard/main_dashboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔹 FIREBASE INITIALIZATION
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyCm57xgXyvRLHTwY5cfDwp_DrwhljUKCno",
      appId: "1:859293807314:android:346d3ab5415259645df30b",
      messagingSenderId: "859293807314",
      projectId: "auto-attendance-624d7",
      storageBucket: "auto-attendance-624d7.firebasestorage.app",
    ),
  );

  // 🔹 LOCAL DATABASE INITIALIZATION
  await DatabaseHelper.instance.database;

  // 🔹 BACKGROUND SERVICE INITIALIZATION
  await initializeService();

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

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'my_foreground',
      initialNotificationTitle: 'Auto Attendance Active',
      initialNotificationContent: 'Monitoring college geofence...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service
        .on('setAsForeground')
        .listen((event) => service.setAsForegroundService());
    service
        .on('setAsBackground')
        .listen((event) => service.setAsBackgroundService());
  }

  service.on('stopService').listen((event) => service.stopSelf());

  Timer.periodic(const Duration(minutes: 5), (timer) async {
    final now = DateTime.now();
    bool isWorkHour = now.hour >= 7 && now.hour < 18;
    bool isWeekday = now.weekday < 6;

    if (isWorkHour && isWeekday) {
      try {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);

        double collegeLat = 9.41285;
        double collegeLon = 76.64225;

        double distance = Geolocator.distanceBetween(
            position.latitude, position.longitude, collegeLat, collegeLon);

        if (distance <= 100) {
          final date =
              "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
          final time = now.toString().substring(0, 19);

          final existing =
              await DatabaseHelper.instance.getAttendanceByDate(date);
          if (existing == null) {
            await DatabaseHelper.instance.insertPunchIn(
                date: date, punchInTime: time, punchType: "AUTO");

            if (service is AndroidServiceInstance) {
              service.setForegroundNotificationInfo(
                title: "Attendance Marked!",
                content: "Auto-punched in at $time",
              );
            }
          }
        }
        service.invoke(
            'update', {"current_distance": distance.toStringAsFixed(1)});
      } catch (e) {
        debugPrint("Background Error: $e");
      }
    }
  });
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async => true;

// --- MAIN APP ---

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> _isProfileComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_name') != null;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeController>(
      builder: (context, themeController, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Auto Attendance',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme:
                ColorScheme.fromSeed(seedColor: const Color(0xFF4F46E5)),
          ),
          darkTheme: ThemeData.dark(useMaterial3: true),
          themeMode: themeController.themeMode,
          routes: {
            '/signup': (context) => const SignupScreen(),
            '/login': (context) => const LoginScreen(),
            '/dashboard': (context) => const MainDashboard(),
          },
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                    body: Center(child: CircularProgressIndicator()));
              }

              // 🔹 AUTH GATE: If user is logged in
              if (snapshot.hasData) {
                return FutureBuilder<bool>(
                  future: _isProfileComplete(),
                  builder: (context, profileSnapshot) {
                    if (profileSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Scaffold(
                          body: Center(child: CircularProgressIndicator()));
                    }

                    // Once logged in, initialize the service and go to Dashboard
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Provider.of<AttendanceService>(context, listen: false)
                          .initializeUser();
                    });

                    return const MainDashboard();
                  },
                );
              }

              // 🔹 No Firebase session: Show Login
              return const LoginScreen();
            },
          ),
        );
      },
    );
  }
}
