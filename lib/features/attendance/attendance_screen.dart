import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/attendance_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  @override
  void initState() {
    super.initState();

    // Load attendance after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AttendanceService>().loadTodayAttendance();
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<AttendanceService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Dashboard'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _statusCard(service),
              const SizedBox(height: 16),
              _punchCard(context, service),
              const SizedBox(height: 16),
              _attendanceStatusCard(service),
              const SizedBox(height: 16),

              // ✅ NEW: CIRCULAR GRACE UI
              _graceProgressCard(service),

              const SizedBox(height: 20),
              _manualPunchButton(context, service),
            ],
          ),
        ),
      ),
    );
  }

  // ================= STATUS CARD =================
  Widget _statusCard(AttendanceService service) {
    return Card(
      color: service.isInside ? Colors.green.shade100 : Colors.red.shade100,
      child: ListTile(
        leading: Icon(
          service.isInside ? Icons.location_on : Icons.location_off,
          color: service.isInside ? Colors.green : Colors.red,
        ),
        title: Text(
          service.isInside ? 'Inside College Area' : 'Outside College Area',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          service.isInside
              ? 'Auto attendance active'
              : 'Auto attendance inactive',
        ),
      ),
    );
  }

  // ================= PUNCH CARD =================
  Widget _punchCard(BuildContext context, AttendanceService service) {
    return Card(
      elevation: 2,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.login),
            title: const Text('Punch In Time'),
            trailing: Text(
              service.punchIn == null
                  ? '--'
                  : TimeOfDay.fromDateTime(service.punchIn!).format(context),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Final Punch Out Time'),
            trailing: Text(
              service.finalPunchOut == null
                  ? '--'
                  : TimeOfDay.fromDateTime(
                      service.finalPunchOut!,
                    ).format(context),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ================= FULL / HALF + GRACE USED =================
  Widget _attendanceStatusCard(AttendanceService service) {
    if (service.dayType == null) {
      return const SizedBox();
    }

    final isHalfDay = service.dayType == 'HALF';

    return Card(
      color: isHalfDay ? Colors.orange.shade100 : Colors.green.shade100,
      child: ListTile(
        leading: Icon(
          isHalfDay ? Icons.warning_amber : Icons.check_circle,
          color: isHalfDay ? Colors.orange : Colors.green,
        ),
        title: Text(
          isHalfDay ? 'HALF DAY' : 'FULL DAY',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Grace Used Today: ${service.graceMinutes} minutes'),
      ),
    );
  }

  // ================= CIRCULAR GRACE PROGRESS =================
  Widget _graceProgressCard(AttendanceService service) {
    const int totalGrace = 250;

    if (service.dayType == null) {
      return const SizedBox();
    }

    final int graceLeft = totalGrace - service.graceMinutes;
    final double progress = (graceLeft / totalGrace).clamp(0.0, 1.0);

    Color color;
    if (graceLeft < 50) {
      color = Colors.red;
    } else if (graceLeft < 150) {
      color = Colors.orange;
    } else {
      color = Colors.green;
    }

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Monthly Grace Balance',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 150,
              height: 150,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 10,
                    color: color,
                    backgroundColor: Colors.grey.shade300,
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Grace Left',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        '$graceLeft min',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= MANUAL PUNCH =================
  Widget _manualPunchButton(BuildContext context, AttendanceService service) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.fingerprint),
        label: const Text('Manual Punch'),
        onPressed: () async {
          await service.handlePunch(punchType: 'manual');

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Punch recorded successfully')),
          );
        },
      ),
    );
  }
}
