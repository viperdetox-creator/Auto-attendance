import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _profileSection(),
          const Divider(),

          _themeSection(themeController),
          const Divider(),

          _csvSection(),
        ],
      ),
    );
  }

  // 🔹 Faculty profile info
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

  // 🔹 Theme switch section (NEW)
  Widget _themeSection(ThemeController controller) {
    return Column(
      children: [
        const ListTile(leading: Icon(Icons.palette), title: Text('App Theme')),
        RadioListTile<ThemeMode>(
          title: const Text('Light Mode'),
          value: ThemeMode.light,
          groupValue: controller.themeMode,
          onChanged: (_) => controller.setLightMode(),
        ),
        RadioListTile<ThemeMode>(
          title: const Text('Dark Mode'),
          value: ThemeMode.dark,
          groupValue: controller.themeMode,
          onChanged: (_) => controller.setDarkMode(),
        ),
        RadioListTile<ThemeMode>(
          title: const Text('System Default'),
          value: ThemeMode.system,
          groupValue: controller.themeMode,
          onChanged: (_) => controller.setSystemMode(),
        ),
      ],
    );
  }

  // 🔹 CSV download
  Widget _csvSection() {
    return ListTile(
      leading: const Icon(Icons.download),
      title: const Text('Download Attendance CSV'),
      onTap: () {
        // TODO: CSV export logic
      },
    );
  }
}
