import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

class _MainDashboardState extends State<MainDashboard>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final LocationService _locationService = LocationService();
  late final GeofenceService _geofenceService;
  bool _initialChecked = false;
  late AnimationController _animationController;
  late Animation<double> _graceAnimation;

  final List<Widget> _pages = [
    const AttendanceScreen(),
    const ManualPunchScreen(),
    const HistoryScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();

    // Animation for grace circle
    _animationController = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );
    _graceAnimation = Tween<double>(begin: 0, end: 0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _geofenceService = GeofenceService(
      centerLat: 9.413304,
      centerLng: 76.641557,
      radiusInMeters: 50,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final attendanceService = context.read<AttendanceService>();
      try {
        await attendanceService.loadTodayAttendance();
        await attendanceService.fetchHistory(); // Load monthly grace too
        _animateGrace(attendanceService.monthlyGraceTotal,
            250); // FIXED: Use monthly total
        _startTracking(attendanceService);
      } catch (e) {
        debugPrint('Init Error: $e');
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _animateGrace(int used, int total) {
    final percentage = used / total;
    _graceAnimation =
        Tween<double>(begin: _graceAnimation.value, end: percentage).animate(
            CurvedAnimation(
                parent: _animationController, curve: Curves.easeOut));
    _animationController.forward(from: 0);
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '--:--';
    final time = dateTime.toLocal();
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$hour12:$minute $period';
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

  Widget _buildGraceCircle(int used, int total) {
    return Container(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[100],
            ),
          ),

          // Progress circle
          AnimatedBuilder(
            animation: _graceAnimation,
            builder: (context, child) {
              return SizedBox(
                width: 200,
                height: 200,
                child: CustomPaint(
                  painter: _GraceCirclePainter(
                    progress: _graceAnimation.value,
                    color: Color(0xFF4F46E5),
                    backgroundColor: Colors.grey[300]!,
                  ),
                ),
              );
            },
          ),

          // Center text
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$used/$total',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              SizedBox(height: 4),
              Text(
                'mins used',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: (used / total) > 0.8
                      ? Colors.orange[100]
                      : Color(0xFF4F46E5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${((used / total) * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: (used / total) > 0.8
                        ? Colors.orange[800]
                        : Color(0xFF4F46E5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(bool isInside, AttendanceService attendanceService) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isInside ? Colors.green[50] : Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isInside ? Icons.location_on : Icons.location_off,
                  color: isInside ? Colors.green : Colors.red,
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isInside ? 'Inside College Area' : 'Outside College Area',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      isInside
                          ? 'Auto-attendance active'
                          : 'Auto-attendance inactive',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Divider(height: 1, color: Colors.grey[200]),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTimeCard(
                label: 'Punch In Time',
                time: _formatTime(attendanceService.punchIn),
                icon: Icons.login,
                color: Colors.blue,
                isActive: attendanceService.isPunchedIn,
              ),
              SizedBox(width: 12),
              _buildTimeCard(
                label: 'Punch Out Time',
                time: _formatTime(attendanceService.finalPunchOut),
                icon: Icons.logout,
                color: Colors.green,
                isActive: !attendanceService.isPunchedIn &&
                    attendanceService.finalPunchOut != null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeCard({
    required String label,
    required String time,
    required IconData icon,
    required Color color,
    required bool isActive,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              time,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            SizedBox(height: 4),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isActive ? color.withOpacity(0.1) : Colors.grey[100],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isActive ? 'Completed' : 'Pending',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isActive ? color : Colors.grey[500],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final attendanceService = context.watch<AttendanceService>();

    return Scaffold(
      backgroundColor: Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF111827),
        elevation: 0,
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!.exists) {
              var userData = snapshot.data!.data() as Map<String, dynamic>;
              String name = userData['name'] ?? "Faculty Member";
              String dept = userData['department'] ?? "General";

              return Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(0xFF4F46E5).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        name.substring(0, 1),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                      Text(
                        dept,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }
            return Text("Loading...");
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined),
            color: Colors.grey[600],
            onPressed: () {},
          ),
        ],
      ),
      body: _currentIndex == 0
          ? SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 16),

                  // Status Card
                  _buildStatusCard(
                      _geofenceService.isInside, attendanceService),

                  SizedBox(height: 24),

                  // Grace Balance Card
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Monthly Grace Balance',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                        SizedBox(height: 20),

                        // Grace Circle - FIXED: Use monthlyGraceTotal
                        _buildGraceCircle(
                            attendanceService.monthlyGraceTotal, 250),

                        SizedBox(height: 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(
                                  'Grace Used',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  // FIXED: Use monthlyGraceTotal
                                  '${attendanceService.monthlyGraceTotal} min',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF4F46E5),
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  'Grace Left',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  // FIXED: Calculate from monthlyGraceTotal
                                  '${250 - attendanceService.monthlyGraceTotal} min',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 32),

                  // Quick Actions
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() => _currentIndex = 1);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF4F46E5),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: Icon(Icons.touch_app_rounded),
                            label: Text(
                              'Manual Punch',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 32),
                ],
              ),
            )
          : _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            backgroundColor: Colors.white,
            selectedItemColor: Color(0xFF4F46E5),
            unselectedItemColor: Colors.grey[500],
            selectedLabelStyle: TextStyle(fontWeight: FontWeight.w500),
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_filled),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.touch_app_outlined),
                activeIcon: Icon(Icons.touch_app),
                label: 'Manual',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history_outlined),
                activeIcon: Icon(Icons.history),
                label: 'History',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GraceCirclePainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _GraceCirclePainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress circle
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
