import 'package:flutter/material.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Dashboard'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _facultyCard(),
            const SizedBox(height: 16),
            _statusCard(),
            const SizedBox(height: 16),
            _punchDetailsCard(),
            const SizedBox(height: 16),
            _graceTimeCard(),
            const SizedBox(height: 16),
            _attendanceResultCard(),
          ],
        ),
      ),
    );
  }

  // ------------------ UI SECTIONS ------------------

  Widget _facultyCard() {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: const Text(
          'Faculty Name',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text('Computer Science Department'),
      ),
    );
  }

  Widget _statusCard() {
    return Card(
      color: Colors.green.shade50,
      child: ListTile(
        leading: const Icon(Icons.location_on, color: Colors.green),
        title: const Text(
          'Inside College Area',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text('Auto attendance active'),
      ),
    );
  }

  Widget _punchDetailsCard() {
    return Card(
      elevation: 2,
      child: Column(
        children: const [
          ListTile(
            leading: Icon(Icons.login),
            title: Text('Punch In Time'),
            trailing: Text(
              '09:12 AM',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Divider(height: 1),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Final Punch Out Time'),
            trailing: Text(
              '04:38 PM',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _graceTimeCard() {
    return Card(
      color: Colors.blue.shade50,
      child: ListTile(
        leading: const Icon(Icons.timer, color: Colors.blue),
        title: const Text(
          'Grace Time Remaining',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: const Text(
          '230 min',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _attendanceResultCard() {
    return Card(
      color: Colors.green.shade100,
      child: ListTile(
        leading: const Icon(Icons.check_circle, color: Colors.green),
        title: const Text(
          'Today’s Attendance Status',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: const Text(
          'PRESENT',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
