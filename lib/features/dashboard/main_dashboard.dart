import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // New Import
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
      centerLat: 9.41285,
      centerLng: 76.64225,
      radiusInMeters: 100,
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
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        title: StreamBuilder<DocumentSnapshot>(
          // Listen to the specific user document in Firestore
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!.exists) {
              var userData = snapshot.data!.data() as Map<String, dynamic>;
              String name = userData['name'] ?? "Faculty Member";
              String dept = userData['department'] ?? "General";

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(dept,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              );
            }
            // Fallback while loading or if data doesn't exist
            return Text(user?.email ?? "Loading...",
                style: const TextStyle(fontSize: 16));
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Home',
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
