import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Standard path based on your folder structure
import '../../core/services/attendance_service.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Refresh history and monthly totals when the screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AttendanceService>().fetchHistory();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance History'),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Consumer<AttendanceService>(
        builder: (context, service, child) {
          return Column(
            children: [
              _buildMonthlyGraceCard(service),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Recent Logs",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ),
              Expanded(
                child: service.history.isEmpty
                    ? _buildEmptyState()
                    : _buildHistoryList(service),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMonthlyGraceCard(AttendanceService service) {
    const int limit = 250;
    int used = service.monthlyGraceTotal;
    double progress = (used / limit).clamp(0.0, 1.0);
    Color progressColor = used > 200 ? Colors.red : Colors.orange;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.indigo,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Monthly Grace Usage",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "$used / $limit mins used",
                    style: TextStyle(
                      color: progressColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text("${(progress * 100).toInt()}%"),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade200,
                color: progressColor,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryList(AttendanceService service) {
    return ListView.builder(
      itemCount: service.history.length,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemBuilder: (context, index) {
        final record = service.history[index];
        final isHalfDay = record['attendance_type'] == 'HALF';
        final grace = record['used_grace_minutes'] ?? 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListTile(
            leading: Icon(
              isHalfDay ? Icons.hourglass_bottom_rounded : Icons.check_circle,
              color: isHalfDay ? Colors.orange : Colors.green,
            ),
            title: Text(
              record['date'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "In: ${record['punch_in']?.substring(11, 16) ?? '--:--'} | "
              "Out: ${record['punch_out']?.substring(11, 16) ?? '--:--'}",
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  record['attendance_type'] ?? 'FULL',
                  style: TextStyle(
                    color: isHalfDay ? Colors.orange : Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                if (grace > 0)
                  Text(
                    "-$grace min",
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 48, color: Colors.grey),
          SizedBox(height: 8),
          Text("No logs found yet.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
