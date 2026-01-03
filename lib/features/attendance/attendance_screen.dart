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
              _graceProgressCard(service),
              const SizedBox(height: 24),
              _manualPunchButton(context, service),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusCard(AttendanceService service) {
    // Use isPunchedIn instead of isInside
    final bool isInside = service.isPunchedIn;

    return Card(
      color: isInside ? Colors.green.shade100 : Colors.red.shade100,
      child: ListTile(
        leading: Icon(
          isInside ? Icons.location_on : Icons.location_off,
          color: isInside ? Colors.green : Colors.red,
        ),
        title: Text(
          isInside ? 'Inside College Area' : 'Outside College Area',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          isInside ? 'Auto attendance active' : 'Auto attendance inactive',
        ),
      ),
    );
  }

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

  Widget _attendanceStatusCard(AttendanceService service) {
    final isHalfDay = service.dayType == 'HALF';
    if (service.punchIn == null) return const SizedBox();

    return Card(
      color: isHalfDay ? Colors.orange.shade100 : Colors.green.shade100,
      child: ListTile(
        leading: Icon(
          isHalfDay ? Icons.warning_amber : Icons.check_circle,
          color: isHalfDay ? Colors.orange : Colors.green,
        ),
        title: Text(
          service.dayType ?? 'SHIFT IN PROGRESS',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Grace Used Today: ${service.graceMinutes} minutes'),
      ),
    );
  }

  Widget _graceProgressCard(AttendanceService service) {
    const int totalGrace = 250;
    // FIX: Use monthlyGraceTotal instead of graceMinutes
    final int monthlyGraceUsed = service.monthlyGraceTotal;
    final int graceLeft = (totalGrace - monthlyGraceUsed).clamp(0, totalGrace);
    final double progress = (graceLeft / totalGrace).clamp(0.0, 1.0);

    Color color = graceLeft < 50
        ? Colors.red
        : (graceLeft < 150 ? Colors.orange : Colors.green);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          children: [
            const Text(
              'Monthly Grace Balance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Used: $monthlyGraceUsed / $totalGrace minutes',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: SizedBox(
                width: 180,
                height: 180,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 14,
                      color: color,
                      backgroundColor: Colors.grey.shade200,
                      strokeCap: StrokeCap.round,
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Grace Left',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          Text(
                            '$graceLeft min',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${(progress * 100).toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '0 min',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  '$totalGrace min',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _manualPunchButton(BuildContext context, AttendanceService service) {
    bool isPunchedIn = service.isPunchedIn;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: isPunchedIn ? Colors.redAccent : Colors.indigo,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Icon(isPunchedIn ? Icons.logout : Icons.fingerprint),
        label: Text(
          isPunchedIn ? 'Manual Punch Out' : 'Manual Punch In',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        onPressed: () async {
          await service.handlePunch(punchType: 'manual');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isPunchedIn
                      ? 'Punched Out Successfully'
                      : 'Punched In Successfully',
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
