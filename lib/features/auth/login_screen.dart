import 'package:flutter/material.dart';
import '../../shared/widgets/app_textfield.dart';
import '../../shared/widgets/primary_button.dart';
import '../dashboard/main_dashboard.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Faculty Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppTextField(hint: 'Username'),
            const SizedBox(height: 12),
            const AppTextField(hint: 'Password', obscure: true),
            const SizedBox(height: 20),
            PrimaryButton(
              text: 'Login',
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MainDashboard(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
