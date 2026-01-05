import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _deptController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  // Validation Logic
  String? _validateName(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Please enter your name' : null;
  String? _validateDept(String? value) =>
      (value == null || value.trim().isEmpty)
          ? 'Please enter department'
          : null;
  String? _validatePhone(String? value) =>
      (value == null || value.trim().length != 10) ? 'Enter 10 digits' : null;
  String? _validateEmail(String? value) =>
      (value == null || !value.contains('@')) ? 'Enter valid email' : null;
  String? _validatePassword(String? value) =>
      (value == null || value.length < 6) ? 'Min 6 characters' : null;

  bool get _isFormValid {
    return _validateName(_nameController.text) == null &&
        _validateDept(_deptController.text) == null &&
        _validatePhone(_phoneController.text) == null &&
        _validateEmail(_emailController.text) == null &&
        _validatePassword(_passwordController.text) == null;
  }

  // 🔹 REPLACED: Direct Registration without OTP
  Future<void> _handleSignup() async {
    if (!_isFormValid) return;

    setState(() => _isLoading = true);

    try {
      // 1. Create User in Firebase Authentication (Standard Email/Pass)
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 2. Save Faculty Profile to Firestore immediately
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'uid': userCredential.user!.uid,
        'name': _nameController.text.trim(),
        'department': _deptController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': "+91${_phoneController.text.trim()}",
        'role': 'Faculty',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Registration Successful! Please login to continue."),
            backgroundColor: Colors.green,
          ),
        );
        // Returns to Login Screen
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? "Signup Failed"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            children: [
              _buildLogo(),
              const SizedBox(height: 32),
              const Text(
                "Create Account",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              _buildInputField(
                label: "Full Name",
                controller: _nameController,
                icon: Icons.person_outlined,
                validator: _validateName,
              ),
              const SizedBox(height: 20),
              _buildInputField(
                label: "Department",
                controller: _deptController,
                icon: Icons.school_outlined,
                validator: _validateDept,
              ),
              const SizedBox(height: 20),
              _buildPhoneField(),
              const SizedBox(height: 20),
              _buildInputField(
                label: "Email",
                controller: _emailController,
                icon: Icons.email_outlined,
                validator: _validateEmail,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              _buildPasswordField(),
              const SizedBox(height: 32),
              _buildSignupButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF4F46E5).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(Icons.person_add_outlined,
          size: 40, color: Color(0xFF4F46E5)),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        errorText: validator(controller.text),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildPhoneField() {
    return TextField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      maxLength: 10,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: "Phone Number",
        prefixText: "+91 ",
        counterText: "",
        errorText: _validatePhone(_phoneController.text),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: "Password",
        prefixIcon: const Icon(Icons.lock_outlined),
        suffixIcon: IconButton(
          icon: Icon(
              _isPasswordVisible ? Icons.visibility : Icons.visibility_off),
          onPressed: () =>
              setState(() => _isPasswordVisible = !_isPasswordVisible),
        ),
        errorText: _validatePassword(_passwordController.text),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildSignupButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ElevatedButton(
              onPressed: _isFormValid ? _handleSignup : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                "Register",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _deptController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
