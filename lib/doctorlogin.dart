import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'main.dart';
import 'role.dart';

class DoctorLogin extends StatefulWidget {
  const DoctorLogin({Key? key}) : super(key: key);

  @override
  _DoctorLoginState createState() => _DoctorLoginState();
}

class _DoctorLoginState extends State<DoctorLogin>
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
        Uri.parse('$baseUrl/doctorlogin.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _usernameController.text.trim(),
          'password': _passwordController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          var doctor = data['doctor'];
          var doctorId = doctor['doctorid'].toString();

          await _storage.write(
              key: 'logged_in_doctor', value: jsonEncode(doctor));
          await _storage.write(key: 'doctor_id', value: doctorId);

          Navigator.pushNamed(
            context,
            '/doctorDashboard',
            arguments: doctorId,
          );
        } else {
          _showModernAlert('Login Failed',
              data['message'] ?? 'Username or password is incorrect.');
        }
      } else {
        _showModernAlert('Error', 'Server error: ${response.statusCode}');
      }
    } catch (error) {
      _showModernAlert(
          'Error', 'An error occurred while logging in: ${error.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showModernAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.error_outline,
                    color: Colors.red.shade700, size: 24),
              ),
              const SizedBox(width: 12),
              Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          content: Text(message,
              style: const TextStyle(color: Color(0xFF64748B))),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const RoleSelection()),
              (Route<dynamic> route) => false,
        );
        return false;
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF8FAFC),
                Color(0xFFE2E8F0),
                Color(0xFFCBD5E1),
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
                        padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.06),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Back Button
                            GestureDetector(
                              onTap: () {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                      const RoleSelection()),
                                      (Route<dynamic> route) => false,
                                );
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
                            SizedBox(height: screenHeight * 0.04),

                            // Card
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    const Icon(Icons.medical_services,
                                        color: Color(0xFF3B82F6), size: 60),
                                    const SizedBox(height: 16),
                                    const Text(
                                      "Welcome Back",
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      "Sign in to your healthcare provider account",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                    const SizedBox(height: 30),
                                    TextFormField(
                                      controller: _usernameController,
                                      decoration: _buildInputDecoration(
                                          label: "Username",
                                          icon: Icons.person_outline),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your username';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: !_isPasswordVisible,
                                      decoration: _buildInputDecoration(
                                        label: "Password",
                                        icon: Icons.lock_outline,
                                        isPassword: true,
                                        isVisible: _isPasswordVisible,
                                        onToggleVisibility: () {
                                          setState(() {
                                            _isPasswordVisible =
                                            !_isPasswordVisible;
                                          });
                                        },
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your password';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 20),

                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () {
                                          Navigator.pushNamed(
                                              context, '/forgetPasswordDoctor');
                                        },
                                        child: const Text(
                                          'Forgot Password?',
                                          style: TextStyle(
                                            color: Color(0xFF3B82F6),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child: ElevatedButton(
                                        onPressed: _isLoading
                                            ? null
                                            : () => handleLogin(),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                          const Color(0xFF3B82F6),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius.circular(16),
                                          ),
                                        ),
                                        child: _isLoading
                                            ? const CircularProgressIndicator(
                                          color: Colors.white,
                                        )
                                            : const Text(
                                          "Login",
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight:
                                              FontWeight.w600),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // Sign Up Section
                                    Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: [
                                        const Text(
                                          "Don't have an account? ",
                                          style: TextStyle(
                                              color: Color(0xFF64748B)),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.pushNamed(
                                                context, '/doctorSignup');
                                          },
                                          child: const Text(
                                            "Sign Up",
                                            style: TextStyle(
                                              color: Color(0xFF3B82F6),
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
                            const SizedBox(height: 20),
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

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData icon,
    bool isPassword = false,
    VoidCallback? onToggleVisibility,
    bool isVisible = false,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF94A3B8)),
      suffixIcon: isPassword
          ? IconButton(
        icon: Icon(
          isVisible ? Icons.visibility : Icons.visibility_off,
          color: const Color(0xFF94A3B8),
        ),
        onPressed: onToggleVisibility,
      )
          : null,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding:
      const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }
}
