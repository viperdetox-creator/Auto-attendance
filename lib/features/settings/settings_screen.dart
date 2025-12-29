import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _profileSection(),
          const Divider(),
          _csvSection(),
        ],
      ),
    );
  }

  Widget _profileSection() {
    return Column(
      children: const [
        ListTile(
          leading: Icon(Icons.person),
          title: Text('Faculty Name'),
          subtitle: Text('John Doe'),
        ),
        ListTile(
          leading: Icon(Icons.apartment),
          title: Text('Department'),
          subtitle: Text('Computer Science'),
        ),
      ],
    );
  }

  Widget _csvSection() {
    return ListTile(
      leading: const Icon(Icons.download),
      title: const Text('Download Attendance CSV'),
      onTap: () {},
    );
  }
}
