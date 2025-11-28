import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'main.dart';

class DoctorSignup extends StatefulWidget {
  @override
  _DoctorSignupState createState() => _DoctorSignupState();
}

class _DoctorSignupState extends State<DoctorSignup>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();

  // Text controllers
  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final contactNoController = TextEditingController();
  final specializationController = TextEditingController();
  final experienceController = TextEditingController();
  final hospitalNameController = TextEditingController();
  final hospitalLocationController = TextEditingController();
  final question1Controller = TextEditingController();
  final answer1Controller = TextEditingController();
  final question2Controller = TextEditingController();
  final answer2Controller = TextEditingController();
  final question3Controller = TextEditingController();
  final answer3Controller = TextEditingController();

  String gender = '';
  File? imageFile;
  int currentPage = 0;
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pageController.dispose();
    // Dispose all controllers
    nameController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    contactNoController.dispose();
    specializationController.dispose();
    experienceController.dispose();
    hospitalNameController.dispose();
    hospitalLocationController.dispose();
    question1Controller.dispose();
    answer1Controller.dispose();
    question2Controller.dispose();
    answer2Controller.dispose();
    question3Controller.dispose();
    answer3Controller.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        imageFile = File(pickedFile.path);
      });
    }
  }

  bool isValidIndianNumber(String number) {
    final regex = RegExp(r'^[6-9]\d{9}$');
    return regex.hasMatch(number);
  }

  Future<void> handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    if (gender.isEmpty) {
      _showModernAlert('Validation Error', 'Please select a gender.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/doctorsignup.php'));
      request.fields['action'] = 'DoctorSignup';
      request.fields['name'] = nameController.text;
      request.fields['username'] = usernameController.text;
      request.fields['password'] = passwordController.text;
      request.fields['contactNo'] = '+91 ${contactNoController.text}';
      request.fields['specialization'] = specializationController.text;
      request.fields['experience'] = experienceController.text;
      request.fields['gender'] = gender;
      request.fields['hospital_name'] = hospitalNameController.text;
      request.fields['hospital_location'] = hospitalLocationController.text;
      request.fields['question_1'] = question1Controller.text;
      request.fields['ans_q1'] = answer1Controller.text;
      request.fields['question_2'] = question2Controller.text;
      request.fields['ans_q2'] = answer2Controller.text;
      request.fields['question_3'] = question3Controller.text;
      request.fields['ans_q3'] = answer3Controller.text;

      if (imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath('profile_image', imageFile!.path));
      }

      final response = await request.send();
      final responseString = await response.stream.bytesToString();
      var responseData = json.decode(responseString);

      if (responseData['message'] == 'Doctor registered successfully with security questions') {
        _showModernAlert('Success', responseData['message'], isSuccess: true, onPressed: () {
          Navigator.pushNamedAndRemoveUntil(context, '/doctorLogin', (route) => false);
        });
      } else {
        _showModernAlert('Error', responseData['message']);
      }
    } catch (e) {
      _showModernAlert('Error', 'An error occurred during signup: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showModernAlert(String title, String message, {bool isSuccess = false, VoidCallback? onPressed}) {
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
                  color: (isSuccess ? Colors.green : Colors.red).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                  color: isSuccess ? Colors.green : Colors.red,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          content: Text(message, style: const TextStyle(color: Color(0xFF64748B))),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (onPressed != null) onPressed();
              },
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
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

  void nextPage() {
    if (currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void previousPage() {
    if (currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
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
                        child: const Icon(Icons.arrow_back_ios_new, size: 20),
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 44),
                  ],
                ),
              ),

              // Progress indicator
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: List.generate(3, (index) {
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                        decoration: BoxDecoration(
                          color: index <= currentPage
                              ? const Color(0xFF3B82F6)
                              : Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // Form content
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (page) {
                      setState(() => currentPage = page);
                    },
                    children: [
                      _buildPersonalInfoPage(),
                      _buildProfessionalInfoPage(),
                      _buildSecurityQuestionsPage(),
                    ],
                  ),
                ),
              ),

              // Navigation buttons
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    if (currentPage > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: previousPage,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF3B82F6)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Previous',
                            style: TextStyle(
                              color: Color(0xFF3B82F6),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    if (currentPage > 0) const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : (currentPage == 2 ? handleSignup : nextPage),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                            : Text(
                          currentPage == 2 ? 'Create Account' : 'Next',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
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
    );
  }

  Widget _buildPersonalInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personal Information',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Let\'s start with your basic details',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 32),

            // Profile image
            Center(
              child: GestureDetector(
                onTap: pickImage,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: imageFile != null
                      ? CircleAvatar(
                    radius: 60,
                    backgroundImage: FileImage(imageFile!),
                  )
                      : const CircleAvatar(
                    radius: 60,
                    backgroundColor: Color(0xFF3B82F6),
                    child: Icon(
                      Icons.camera_alt,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Tap to add profile photo',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 14,
                ),
              ),
            ),

            const SizedBox(height: 32),

            _buildModernTextField('Full Name', nameController, Icons.person_outline),
            const SizedBox(height: 20),
            _buildModernTextField('Username', usernameController, Icons.alternate_email),
            const SizedBox(height: 20),
            _buildPasswordField(),
            const SizedBox(height: 20),
            _buildContactField(),
            const SizedBox(height: 24),
            _buildGenderSelection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Professional Details',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tell us about your medical expertise',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 32),

          _buildModernTextField('Specialization', specializationController, Icons.local_hospital),
          const SizedBox(height: 20),
          _buildModernTextField('Years of Experience', experienceController, Icons.timeline, keyboardType: TextInputType.number),
          const SizedBox(height: 20),
          _buildModernTextField('Hospital/Clinic Name', hospitalNameController, Icons.business),
          const SizedBox(height: 20),
          _buildModernTextField('Hospital Location', hospitalLocationController, Icons.location_on),
        ],
      ),
    );
  }

  Widget _buildSecurityQuestionsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Security Questions',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Set up recovery questions for your account',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF3B82F6).withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: const Color(0xFF3B82F6),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'These questions will help you recover your account if you forget your password.',
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF3B82F6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          _buildModernTextField('Security Question 1', question1Controller, Icons.help_outline),
          const SizedBox(height: 12),
          _buildModernTextField('Answer 1', answer1Controller, Icons.edit),
          const SizedBox(height: 20),
          _buildModernTextField('Security Question 2', question2Controller, Icons.help_outline),
          const SizedBox(height: 12),
          _buildModernTextField('Answer 2', answer2Controller, Icons.edit),
          const SizedBox(height: 20),
          _buildModernTextField('Security Question 3', question3Controller, Icons.help_outline),
          const SizedBox(height: 12),
          _buildModernTextField('Answer 3', answer3Controller, Icons.edit),
        ],
      ),
    );
  }

  Widget _buildModernTextField(String label, TextEditingController controller, IconData icon, {TextInputType? keyboardType, bool obscureText = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Color(0xFF64748B),
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF3B82F6), size: 20),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: passwordController,
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
            color: const Color(0xFF3B82F6).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.lock_outline, color: Color(0xFF3B82F6), size: 20),
        ),
        suffixIcon: IconButton(
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
          icon: Icon(
            _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
            color: const Color(0xFF64748B),
          ),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a password';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }

  Widget _buildContactField() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: const Text(
            '+91',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: contactNoController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Contact Number',
              labelStyle: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter contact number';
              }
              if (!isValidIndianNumber(value)) {
                return 'Enter valid Indian mobile number';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGenderSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gender',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: ['Male', 'Female', 'Other'].map((genderOption) {
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    gender = genderOption;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: gender == genderOption
                        ? const Color(0xFF3B82F6)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: gender == genderOption
                          ? const Color(0xFF3B82F6)
                          : Colors.grey.withOpacity(0.2),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      genderOption,
                      style: TextStyle(
                        color: gender == genderOption ? Colors.white : const Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}