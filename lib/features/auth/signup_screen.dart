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
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _rememberMe = false;

  // Form validation
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter your name';
    if (value.trim().length < 3) return 'Name must be at least 3 characters';
    return null;
  }

  String? _validateDept(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter department';
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter email';
    if (!value.contains('@')) return 'Enter a valid email address';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter password';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  bool get _isFormValid {
    return _validateName(_nameController.text) == null &&
        _validateDept(_deptController.text) == null &&
        _validateEmail(_emailController.text) == null &&
        _validatePassword(_passwordController.text) == null;
  }

  // YOUR EXACT FIREBASE LOGIC (unchanged)
  Future<void> _handleSignup() async {
    // 1. Basic Validation (enhanced with form validation)
    if (!_isFormValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fix all errors")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Create user in Firebase Authentication
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 3. Save Name and Dept to Firestore using the UID
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'name': _nameController.text.trim(),
        'department': _deptController.text.trim(),
        'email': _emailController.text.trim(),
        'role': 'Faculty', // Default role
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 4. Success! Go back to Login or the Auth Gate will handle it
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Welcome ${_nameController.text.trim()}!"),
            backgroundColor: Colors.green,
          ),
        );

        // Auto-navigate back to login after success
        Future.delayed(Duration(seconds: 1), () {
          Navigator.pop(context);
        });
      }
    } on FirebaseAuthException catch (e) {
      String message = "Registration Failed";
      if (e.code == 'email-already-in-use') {
        message = "Email already registered";
      } else if (e.code == 'weak-password') {
        message = "Password is too weak";
      } else if (e.code == 'invalid-email') {
        message = "Invalid email address";
      } else {
        message = e.message ?? "Registration Failed";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
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
      // Removed AppBar for cleaner design
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo/Icon
                Container(
                  width: 80.0,
                  height: 80.0,
                  decoration: BoxDecoration(
                    color: Color(0xFF4F46E5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Icon(
                    Icons.person_add_outlined,
                    size: 40.0,
                    color: Color(0xFF4F46E5),
                  ),
                ),

                SizedBox(height: 32.0),

                // Title (Matches your design)
                Column(
                  children: [
                    Text(
                      "Create Account",
                      style: TextStyle(
                        fontSize: 30.0,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      "Register as faculty",
                      style: TextStyle(
                        fontSize: 16.0,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),

                SizedBox(height: 48.0),

                // Full Name Field (Enhanced)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Full Name",
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 8.0),
                    Container(
                      height: 56.0,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: _validateName(_nameController.text) != null
                              ? Colors.red
                              : Colors.grey[300]!,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(left: 16.0),
                            child: Icon(
                              Icons.person_outlined,
                              color: Colors.grey[500],
                              size: 20.0,
                            ),
                          ),
                          SizedBox(width: 12.0),
                          Expanded(
                            child: TextField(
                              controller: _nameController,
                              style: TextStyle(fontSize: 16.0),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: "Enter your full name",
                                hintStyle: TextStyle(color: Colors.grey[400]),
                              ),
                              onChanged: (value) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_validateName(_nameController.text) != null)
                      Padding(
                        padding: EdgeInsets.only(top: 4.0),
                        child: Text(
                          _validateName(_nameController.text)!,
                          style: TextStyle(
                            fontSize: 12.0,
                            color: Colors.red,
                          ),
                        ),
                      ),
                  ],
                ),

                SizedBox(height: 20.0),

                // Department Field (Enhanced)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Department",
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 8.0),
                    Container(
                      height: 56.0,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: _validateDept(_deptController.text) != null
                              ? Colors.red
                              : Colors.grey[300]!,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(left: 16.0),
                            child: Icon(
                              Icons.school_outlined,
                              color: Colors.grey[500],
                              size: 20.0,
                            ),
                          ),
                          SizedBox(width: 12.0),
                          Expanded(
                            child: TextField(
                              controller: _deptController,
                              style: TextStyle(fontSize: 16.0),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: "e.g., Computer Science",
                                hintStyle: TextStyle(color: Colors.grey[400]),
                              ),
                              onChanged: (value) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_validateDept(_deptController.text) != null)
                      Padding(
                        padding: EdgeInsets.only(top: 4.0),
                        child: Text(
                          _validateDept(_deptController.text)!,
                          style: TextStyle(
                            fontSize: 12.0,
                            color: Colors.red,
                          ),
                        ),
                      ),
                  ],
                ),

                SizedBox(height: 20.0),

                // Email Field (Enhanced)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Email",
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 8.0),
                    Container(
                      height: 56.0,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: _validateEmail(_emailController.text) != null
                              ? Colors.red
                              : Colors.grey[300]!,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(left: 16.0),
                            child: Icon(
                              Icons.email_outlined,
                              color: Colors.grey[500],
                              size: 20.0,
                            ),
                          ),
                          SizedBox(width: 12.0),
                          Expanded(
                            child: TextField(
                              controller: _emailController,
                              style: TextStyle(fontSize: 16.0),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: "you@college.edu",
                                hintStyle: TextStyle(color: Colors.grey[400]),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              onChanged: (value) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_validateEmail(_emailController.text) != null)
                      Padding(
                        padding: EdgeInsets.only(top: 4.0),
                        child: Text(
                          _validateEmail(_emailController.text)!,
                          style: TextStyle(
                            fontSize: 12.0,
                            color: Colors.red,
                          ),
                        ),
                      ),
                  ],
                ),

                SizedBox(height: 20.0),

                // Password Field (Enhanced)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Password",
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 8.0),
                    Container(
                      height: 56.0,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: _validatePassword(_passwordController.text) !=
                                  null
                              ? Colors.red
                              : Colors.grey[300]!,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(left: 16.0),
                            child: Icon(
                              Icons.lock_outlined,
                              color: Colors.grey[500],
                              size: 20.0,
                            ),
                          ),
                          SizedBox(width: 12.0),
                          Expanded(
                            child: TextField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              style: TextStyle(fontSize: 16.0),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: "Create a password",
                                hintStyle: TextStyle(color: Colors.grey[400]),
                              ),
                              onChanged: (value) => setState(() {}),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(right: 16.0),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                              child: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: Colors.grey[500],
                                size: 20.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_validatePassword(_passwordController.text) != null)
                      Padding(
                        padding: EdgeInsets.only(top: 4.0),
                        child: Text(
                          _validatePassword(_passwordController.text)!,
                          style: TextStyle(
                            fontSize: 12.0,
                            color: Colors.red,
                          ),
                        ),
                      ),
                  ],
                ),

                SizedBox(height: 20.0),

                // Remember Me (Optional)
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (value) {
                        setState(() {
                          _rememberMe = value ?? false;
                        });
                      },
                      activeColor: Color(0xFF4F46E5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ),
                    Text(
                      "Remember me",
                      style: TextStyle(
                        fontSize: 14.0,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 24.0),

                // Register Button (Enhanced)
                SizedBox(
                  width: double.infinity,
                  height: 56.0,
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF4F46E5),
                          ),
                        )
                      : ElevatedButton(
                          onPressed: _isFormValid ? _handleSignup : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF4F46E5),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            "Register",
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                ),

                SizedBox(height: 32.0),

                // Already have account
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: TextStyle(
                        fontSize: 14.0,
                        color: Colors.grey[600],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context); // Go back to login
                      },
                      child: Text(
                        "Sign In",
                        style: TextStyle(
                          fontSize: 14.0,
                          color: Color(0xFF4F46E5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _deptController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
