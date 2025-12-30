import 'package:flutter/material.dart';
import '../../core/services/attendance_service.dart';

class AttendanceScreen extends StatefulWidget {
  final AttendanceService service;

  const AttendanceScreen({
    super.key,
    required this.service,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  @override
  void initState() {
    super.initState();
    widget.service.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.service.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              _statusCard(),
              const SizedBox(height: 16),
              _punchCard(context),
            ],
          ),
        ),
      ),
    );
  }

  // ================= STATUS CARD =================
  Widget _statusCard() {
    return Card(
      color: widget.service.isInside
          ? Colors.green.shade100
          : Colors.red.shade100,
      child: ListTile(
        leading: Icon(
          widget.service.isInside
              ? Icons.location_on
              : Icons.location_off,
          color: widget.service.isInside
              ? Colors.green
              : Colors.red,
        ),
        title: Text(
          widget.service.isInside
              ? 'Inside College Area'
              : 'Outside College Area',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          widget.service.isInside
              ? 'Auto attendance active'
              : 'Auto attendance inactive',
        ),
      ),
    );
  }

  // ================= PUNCH CARD =================
  Widget _punchCard(BuildContext context) {
    return Card(
      elevation: 2,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.login),
            title: const Text('Punch In Time'),
            trailing: Text(
              widget.service.punchIn == null
                  ? '--'
                  : TimeOfDay.fromDateTime(
                      widget.service.punchIn!,
                    ).format(context),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Final Punch Out Time'),
            trailing: Text(
              widget.service.finalPunchOut == null
                  ? '--'
                  : TimeOfDay.fromDateTime(
                      widget.service.finalPunchOut!,
                    ).format(context),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
