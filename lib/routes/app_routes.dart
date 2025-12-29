import 'package:flutter/material.dart';
import '../features/auth/login_screen.dart';
import '../features/attendance/attendance_screen.dart';
import '../features/history/history_screen.dart';

class AppRoutes {
  static const login = '/login';
  static const attendance = '/attendance';
  static const history = '/history';

  static final Map<String, WidgetBuilder> routes = {
    login: (context) => const LoginScreen(),
    attendance: (context) => const AttendanceScreen(),
    history: (context) => const HistoryScreen(),
  };
}
