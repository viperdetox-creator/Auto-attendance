import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/attendance_service.dart';

class ManualPunchScreen extends StatefulWidget {
  const ManualPunchScreen({super.key});

  @override
  State<ManualPunchScreen> createState() => _ManualPunchScreenState();
}

class _ManualPunchScreenState extends State<ManualPunchScreen> {
  DateTime _selDate = DateTime.now();
  TimeOfDay _inT = const TimeOfDay(hour: 9, minute: 30);
  TimeOfDay _outT = const TimeOfDay(hour: 15, minute: 30);

  @override
  Widget build(BuildContext context) {
    return Consumer<AttendanceService>(
      builder: (context, service, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Manual Attendance'),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header("Live Status (Sync)"),
                _liveCard(service),
                const SizedBox(height: 30),
                _header("Manual Override (Today/Yesterday)"),
                _overrideCard(service),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _header(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 4),
    child: Text(
      t,
      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
    ),
  );

  Widget _liveCard(AttendanceService service) {
    bool isIn = service.isPunchedIn;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: isIn ? Colors.redAccent : Colors.indigo,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          icon: Icon(isIn ? Icons.logout : Icons.fingerprint),
          label: Text(isIn ? 'Manual Punch Out' : 'Manual Punch In'),
          onPressed: () => service.handlePunch(punchType: 'manual'),
        ),
      ),
    );
  }

  Widget _overrideCard(AttendanceService service) {
    return Card(
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _tile(
              "Date",
              "${_selDate.day}/${_selDate.month}/${_selDate.year}",
              Icons.event,
              () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _selDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 1)),
                  lastDate: DateTime.now(),
                );
                if (d != null) setState(() => _selDate = d);
              },
            ),
            _tile("In Time", _inT.format(context), Icons.login, () async {
              final t = await showTimePicker(
                context: context,
                initialTime: _inT,
              );
              if (t != null) setState(() => _inT = t);
            }),
            _tile("Out Time", _outT.format(context), Icons.logout, () async {
              final t = await showTimePicker(
                context: context,
                initialTime: _outT,
              );
              if (t != null) setState(() => _outT = t);
            }),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _confirm(service),
                child: const Text("Save Manual Record"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(String t, String s, IconData i, VoidCallback onTap) => ListTile(
    leading: Icon(i, color: Colors.indigo),
    title: Text(t),
    subtitle: Text(s, style: const TextStyle(fontWeight: FontWeight.bold)),
    trailing: const Icon(Icons.edit, size: 20),
    onTap: onTap,
  );

  void _confirm(AttendanceService service) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Override"),
        content: const Text(
          "This will replace any existing logs for this date. Proceed?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              service.manualOverridePunch(
                selectedDate: _selDate,
                inTime: _inT,
                outTime: _outT,
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Record Updated")));
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}
