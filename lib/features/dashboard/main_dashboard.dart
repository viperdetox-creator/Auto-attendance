import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../attendance/attendance_screen.dart';
import '../manual/manual_punch_screen.dart';
import '../history/history_screen.dart';
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

  // 1. Updated List with all 4 pages
  final List<Widget> _pages = [
    const AttendanceScreen(),
    const ManualPunchScreen(),
    const HistoryScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _geofenceService = GeofenceService(
      centerLat: 9.413304,
      centerLng: 76.641557,
      radiusInMeters: 50,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final attendanceService = context.read<AttendanceService>();
      try {
        await attendanceService.loadTodayAttendance();
        _startTracking(attendanceService);
      } catch (e) {
        debugPrint('Init Error: $e');
      }
    });
  }

  void _startTracking(AttendanceService attendanceService) async {
    final allowed = await _locationService.ensurePermission();
    if (!allowed) return;

    _locationService.getPositionStream().listen((position) {
      if (!_initialChecked) {
        _initialChecked = true;
        _geofenceService.check(position);
        if (_geofenceService.isInside && !attendanceService.isPunchedIn) {
          attendanceService.handlePunch(punchType: 'auto');
        }
        return;
      }

      final changed = _geofenceService.check(position);
      if (!changed) return;

      if (_geofenceService.isInside) {
        if (!attendanceService.isPunchedIn) {
          attendanceService.handlePunch(punchType: 'auto');
        }
      } else {
        if (attendanceService.isPunchedIn) {
          attendanceService.handlePunch(punchType: 'auto');
        }
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
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        // Crucial for 4+ items: prevents icons from shifting/disappearing
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.touch_app_rounded),
            label: 'Manual',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
