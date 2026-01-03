import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/utils/pdf_helper.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        // This still fetches user profile info from Firebase
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          String name = "Faculty Member";
          String dept = "Department";

          if (snapshot.hasData && snapshot.data!.exists) {
            var data = snapshot.data!.data() as Map<String, dynamic>;
            name = data['name'] ?? name;
            dept = data['department'] ?? dept;
          }

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 10),
            children: [
              _profileSection(name, dept),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(),
              ),
              _themeSection(themeController),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(),
              ),
              _reportSection(context),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(),
              ),
              _logoutSection(),
            ],
          );
        },
      ),
    );
  }

  Widget _profileSection(String name, String dept) {
    return Column(
      children: [
        ListTile(
          leading: const CircleAvatar(
            backgroundColor: Colors.indigo,
            child: Icon(Icons.person, color: Colors.white),
          ),
          title: const Text('Faculty Name',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          subtitle: Text(name,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
        ),
        ListTile(
          leading: const Icon(Icons.business, color: Colors.indigo),
          title: const Text('Department',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          subtitle: Text(dept,
              style: const TextStyle(fontSize: 16, color: Colors.black87)),
        ),
      ],
    );
  }

  Widget _themeSection(ThemeController controller) {
    return ExpansionTile(
      leading: const Icon(Icons.palette, color: Colors.indigo),
      title: const Text("App Appearance"),
      children: [
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
      ],
    );
  }

  Widget _reportSection(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
      title: const Text('Generate Attendance Report'),
      subtitle: const Text('Offline PDF Export'),
      trailing: const Icon(Icons.download, color: Colors.grey),
      onTap: () async {
        // Show a loading snackbar
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          const SnackBar(
            content: Text("Generating PDF from local database..."),
            duration: Duration(seconds: 2),
          ),
        );

        try {
          // Calls your updated SQLite-based helper
          await PdfExportService.generateAttendancePdf();
        } catch (e) {
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(
            SnackBar(
              content: Text("Export failed: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }

  Widget _logoutSection() {
    return ListTile(
      leading: const Icon(Icons.exit_to_app, color: Colors.red),
      title: const Text('Sign Out',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
      onTap: () => FirebaseAuth.instance.signOut(),
    );
  }
}
