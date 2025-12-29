import 'package:flutter/material.dart';

class ManualPunchScreen extends StatelessWidget {
  const ManualPunchScreen({super.key});

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
            _punchButtons(),
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
    return Card(
      child: Column(
        children: const [
          ListTile(
            leading: Icon(Icons.calendar_today),
            title: Text('Date'),
            trailing: Text('26 Dec 2025'),
          ),
          Divider(height: 1),
          ListTile(
            leading: Icon(Icons.access_time),
            title: Text('Time'),
            trailing: Text('10:15 AM'),
          ),
        ],
      ),
    );
  }

  Widget _punchButtons() {
    return Column(
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.login),
          label: const Text('Manual Punch In'),
          onPressed: () {},
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          icon: const Icon(Icons.logout),
          label: const Text('Manual Punch Out'),
          onPressed: () {},
        ),
      ],
    );
  }
}
