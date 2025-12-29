import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance History')),
      body: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) {
          return const ListTile(
            leading: Icon(Icons.check_circle_outline),
            title: Text('Punch In: 09:00 AM'),
            subtitle: Text('Punch Out: 04:30 PM'),
          );
        },
      ),
    );
  }
}
