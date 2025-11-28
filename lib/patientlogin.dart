import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'main.dart';
import 'forgetpassword.dart';
import 'role.dart';

class PatientLogin extends StatefulWidget {
  const PatientLogin({Key? key}) : super(key: key);

  @override
  _PatientLoginState createState() => _PatientLoginState();
}

class _PatientLoginState extends State<PatientLogin>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _storage = const FlutterSecureStorage();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      var response = await http.post(
        Uri.parse('$baseUrl/patientlogin.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _usernameController.text.trim(),
          'password': _passwordController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (data['success'] == true) {
          final patientId = data['patient']['patientid'].toString();
          await _storage.write(key: 'patient_id', value: patientId);

          Navigator.pushReplacementNamed(context, '/patientDashboard');
        } else {
          _showModernAlert('Login Failed', data['message'] ?? 'Username or password is incorrect.');
        }
      } else {
        _showModernAlert('Error', 'Server error: ${response.statusCode}');
      }
    } catch (error) {
      _showModernAlert('Error', 'An error occurred while logging in: ${error.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showModernAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.error_outline, color: Colors.red, size: 24),
              ),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          content: Text(message, style: const TextStyle(color: Color(0xFF64748B))),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _onWillPop() async {
    Navigator.pushReplacementNamed(context, '/roleSelection');
    return false;
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF0FDF4),
                Color(0xFFDCFCE7),
                Color(0xFFBBF7D0),
              ],
            ),
          ),
          child: SafeArea(
            child: AnimatedBuilder(
              animation: _fadeController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Center(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
                        child: Column(
                          children: [
                            // Back button
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pushReplacementNamed(context, '/roleSelection');
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.arrow_back_ios_new,
                                      color: Color(0xFF334155),
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: screenHeight * 0.06),

                            // Main login card
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 30,
                                    offset: const Offset(0, 10),
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  children: [
                                    // Header section
                                    Column(
                                      children: [
                                        Container(
                                          width: 80,
                                          height: 80,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                                            ),
                                            borderRadius: BorderRadius.circular(20),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF10B981).withOpacity(0.3),
                                                blurRadius: 20,
                                                offset: const Offset(0, 8),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.person_rounded,
                                            color: Colors.white,
                                            size: 40,
                                          ),
                                        ),

                                        const SizedBox(height: 24),

                                        const Text(
                                          'Welcome Back',
                                          style: TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF1E293B),
                                            letterSpacing: -0.5,
                                          ),
                                        ),

                                        const SizedBox(height: 8),

                                        const Text(
                                          'Sign in to access your health dashboard',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Color(0xFF64748B),
                                            fontWeight: FontWeight.w400,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 40),

                                    // Form section
                                    Form(
                                      key: _formKey,
                                      child: Column(
                                        children: [
                                          // Username field
                                          TextFormField(
                                            controller: _usernameController,
                                            keyboardType: TextInputType.text,
                                            decoration: InputDecoration(
                                              labelText: 'Username',
                                              labelStyle: const TextStyle(
                                                color: Color(0xFF64748B),
                                                fontWeight: FontWeight.w500,
                                              ),
                                              prefixIcon: Container(
                                                margin: const EdgeInsets.all(12),
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF10B981).withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: const Icon(
                                                  Icons.person_outline,
                                                  color: Color(0xFF10B981),
                                                  size: 20,
                                                ),
                                              ),
                                              filled: true,
                                              fillColor: const Color(0xFFF8FAFC),
                                              contentPadding: const EdgeInsets.symmetric(
                                                vertical: 20,
                                                horizontal: 16,
                                              ),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(16),
                                                borderSide: BorderSide.none,
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(16),
                                                borderSide: BorderSide(
                                                  color: Colors.grey.withOpacity(0.2),
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(16),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFF10B981),
                                                  width: 2,
                                                ),
                                              ),
                                            ),
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return 'Please enter your username';
                                              }
                                              return null;
                                            },
                                          ),

                                          const SizedBox(height: 20),

                                          // Password field
                                          TextFormField(
                                            controller: _passwordController,
                                            obscureText: !_isPasswordVisible,
                                            decoration: InputDecoration(
                                              labelText: 'Password',
                                              labelStyle: const TextStyle(
                                                color: Color(0xFF64748B),
                                                fontWeight: FontWeight.w500,
                                              ),
                                              prefixIcon: Container(
                                                margin: const EdgeInsets.all(12),
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF10B981).withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: const Icon(
                                                  Icons.lock_outline,
                                                  color: Color(0xFF10B981),
                                                  size: 20,
                                                ),
                                              ),
                                              suffixIcon: IconButton(
                                                onPressed: () {
                                                  setState(() {
                                                    _isPasswordVisible = !_isPasswordVisible;
                                                  });
                                                },
                                                icon: Icon(
                                                  _isPasswordVisible
                                                      ? Icons.visibility_off_outlined
                                                      : Icons.visibility_outlined,
                                                  color: const Color(0xFF64748B),
                                                ),
                                              ),
                                              filled: true,
                                              fillColor: const Color(0xFFF8FAFC),
                                              contentPadding: const EdgeInsets.symmetric(
                                                vertical: 20,
                                                horizontal: 16,
                                              ),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(16),
                                                borderSide: BorderSide.none,
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(16),
                                                borderSide: BorderSide(
                                                  color: Colors.grey.withOpacity(0.2),
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(16),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFF10B981),
                                                  width: 2,
                                                ),
                                              ),
                                            ),
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return 'Please enter your password';
                                              }
                                              return null;
                                            },
                                          ),

                                          const SizedBox(height: 32),

                                          // Login button
                                          SizedBox(
                                            width: double.infinity,
                                            height: 56,
                                            child: ElevatedButton(
                                              onPressed: _isLoading ? null : handleLogin,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF10B981),
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                                shadowColor: Colors.transparent,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(16),
                                                ),
                                              ),
                                              child: _isLoading
                                                  ? const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                ),
                                              )
                                                  : const Text(
                                                'Sign In',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 24),

                                    // Forgot password
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => const ForgetPassword()),
                                        );
                                      },
                                      child: const Text(
                                        'Forgot Password?',
                                        style: TextStyle(
                                          color: Color(0xFF10B981),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 16),

                                    // Sign up link
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF0FDF4),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFF10B981).withOpacity(0.2),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Text(
                                            "Don't have an account? ",
                                            style: TextStyle(
                                              color: Color(0xFF64748B),
                                              fontSize: 16,
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              Navigator.pushNamed(context, '/PatientSignup');
                                            },
                                            child: const Text(
                                              'Sign Up',
                                              style: TextStyle(
                                                color: Color(0xFF10B981),
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}