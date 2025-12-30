import 'package:flutter/material.dart';

import '../attendance/attendance_screen.dart';
import '../manual/manual_punch_screen.dart';
import '../settings/settings_screen.dart';

// 🔹 BACKEND IMPORTS
import '../../core/services/location_service.dart';
import '../../core/services/geofence_service.dart';
import '../../core/services/attendance_service.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  // 🔹 BACKEND OBJECTS
  final LocationService _locationService = LocationService();
  late final GeofenceService _geofenceService;
  final AttendanceService _attendanceService = AttendanceService();

  bool _initialChecked = false;

  @override
  void initState() {
    super.initState();

    // 🔹 DEFINE COLLEGE LOCATION
    _geofenceService = GeofenceService(
      centerLat: 9.413304,
      centerLng: 76.641557,
      radiusInMeters: 150,
    );

    // 🔹 CONNECT BACKEND → UI 
    _pages = [
      AttendanceScreen(service: _attendanceService),
      const ManualPunchScreen(),
      const SettingsScreen(),
    ];

    // 🔹 START BACKEND AFTER UI LOADS
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startTracking();
    });
  }

  // 🔹 GEOFENCING + ATTENDANCE LOGIC
  void _startTracking() async {
    debugPrint('==============================');
    debugPrint('BACKEND TRACKING STARTED');

    final allowed = await _locationService.ensurePermission();
    debugPrint('LOCATION PERMISSION: $allowed');

    if (!allowed) {
      debugPrint('Permission denied. Tracking stopped.');
      return;
    }

    _locationService.getPositionStream().listen((position) {
      debugPrint(
        'LOCATION UPDATE -> lat:${position.latitude}, lng:${position.longitude}',
      );

      // 🔹 FIRST LOCATION FIX (already inside)
      if (!_initialChecked) {
        _initialChecked = true;

        _geofenceService.check(position);
        if (_geofenceService.isInside) {
          _attendanceService.onEnter(DateTime.now());
          debugPrint('AUTO PUNCH IN (INITIAL INSIDE)');
        }
        return;
      }

      // 🔹 NORMAL ENTRY / EXIT
      final changed = _geofenceService.check(position);
      if (!changed) return;

      if (_geofenceService.isInside) {
        _attendanceService.onEnter(DateTime.now());
        debugPrint('AUTO PUNCH IN');
      } else {
        _attendanceService.onExit(DateTime.now());
        debugPrint('AUTO PUNCH OUT');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.touch_app),
            label: 'Manual',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
