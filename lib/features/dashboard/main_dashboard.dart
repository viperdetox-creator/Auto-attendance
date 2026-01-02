import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../attendance/attendance_screen.dart';
import '../manual/manual_punch_screen.dart';
import '../settings/settings_screen.dart';

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

  final LocationService _locationService = LocationService();
  late final GeofenceService _geofenceService;

  bool _initialChecked = false;

  final List<Widget> _pages = const [
    AttendanceScreen(),
    ManualPunchScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();

    _geofenceService = GeofenceService(
      centerLat: 9.413304,
      centerLng: 76.641557,
      radiusInMeters: 50,
    );

    /// 🔥 MOST IMPORTANT FIX
    /// Load today attendance BEFORE UI logic starts
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final attendanceService = context.read<AttendanceService>();

      try {
        // 1️⃣ Load DB state (sets isPunchedIn correctly)
        await attendanceService.loadTodayAttendance();

        // 2️⃣ Start geofence tracking
        _startTracking(attendanceService);
      } catch (e, st) {
        // Prevent Flutter's error page (which displays source code) from showing
        debugPrint('Error initializing dashboard: $e\n$st');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Dashboard initialization failed: $e')),
          );
        }
      }
    });
  }

  void _startTracking(AttendanceService attendanceService) async {
    try {
      final allowed = await _locationService.ensurePermission();
      if (!allowed) return;

      _locationService.getPositionStream().listen(
        (position) {
          try {
            // First GPS fix
            if (!_initialChecked) {
              _initialChecked = true;

              _geofenceService.check(position);
              if (_geofenceService.isInside && !attendanceService.isPunchedIn) {
                attendanceService.handleGeofenceEnter();
              }
              return;
            }

            // Entry / Exit detection
            final changed = _geofenceService.check(position);
            if (!changed) return;

            if (_geofenceService.isInside) {
              attendanceService.handleGeofenceEnter();
            } else {
              attendanceService.handleGeofenceExit();
            }
          } catch (e, st) {
            debugPrint('Error processing position update: $e\n$st');
          }
        },
        onError: (e, st) {
          debugPrint('Position stream error: $e\n$st');
        },
      );
    } catch (e, st) {
      debugPrint('Error starting tracking: $e\n$st');
    }
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
          BottomNavigationBarItem(icon: Icon(Icons.touch_app), label: 'Manual'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
