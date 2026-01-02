import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/attendance_service.dart';

class ManualPunchScreen extends StatefulWidget {
  const ManualPunchScreen({super.key});

  @override
  State<ManualPunchScreen> createState() => _ManualPunchScreenState();
}

class _ManualPunchScreenState extends State<ManualPunchScreen> {
  bool _isPunchedIn = false;

  Future<void> _manualPunch() async {
    final attendanceService = context.read<AttendanceService>();

    await attendanceService.handlePunch(punchType: 'manual');

    setState(() {
      _isPunchedIn = !_isPunchedIn;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isPunchedIn
              ? 'Manual Punch In Successful'
              : 'Manual Punch Out Successful',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manual Attendance')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _infoCard(),
            const SizedBox(height: 20),
            _dateTimeCard(),
            const SizedBox(height: 20),
            _punchButton(),
          ],
        ),
      ),
    );
  }

  Widget _infoCard() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Use manual attendance only if automatic punching fails.',
          style: TextStyle(fontSize: 14),
        ),
      ),
    );
  }

  Widget _dateTimeCard() {
    final now = DateTime.now();

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Date'),
            trailing: Text('${now.day}/${now.month}/${now.year}'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Time'),
            trailing: Text(
              '${now.hour}:${now.minute.toString().padLeft(2, '0')}',
            ),
          ),
        ],
      ),
    );
  }

  Widget _punchButton() {
    return ElevatedButton.icon(
      icon: Icon(_isPunchedIn ? Icons.logout : Icons.login),
      label: Text(_isPunchedIn ? 'Manual Punch Out' : 'Manual Punch In'),
      onPressed: _manualPunch,
    );
  }
}
