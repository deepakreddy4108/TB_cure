import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'main.dart';

class AddPatient extends StatefulWidget {
  @override
  _AddPatientState createState() => _AddPatientState();
}

class _AddPatientState extends State<AddPatient>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _storage = FlutterSecureStorage();
  final PageController _pageController = PageController();

  // Text controllers
  final patientNameController = TextEditingController();
  final patientAgeController = TextEditingController();
  final patientProblemController = TextEditingController();
  final patientMobileNumberController = TextEditingController();
  final patientAddressController = TextEditingController();
  final appointmentDateController = TextEditingController();

  String gender = '';
  String? selectedTimeSlot;
  DateTime appointmentDate = DateTime.now();
  bool isLoading = false;
  int currentPage = 0;

  String? hospitalName;
  String? hospitalLocation;
  int? doctorId;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<String> timeSlots = List.generate(
    20,
        (index) {
      int hour = 8 + (index ~/ 2);
      int minute = (index % 2) * 30;
      return DateFormat('hh:mm a').format(DateTime(0, 0, 0, hour, minute));
    },
  );

  @override
  void initState() {
    super.initState();
    _initAnimations();
    appointmentDateController.text = DateFormat('yyyy-MM-dd').format(appointmentDate);
    fetchDoctorDetails();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
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
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pageController.dispose();
    patientNameController.dispose();
    patientAgeController.dispose();
    patientProblemController.dispose();
    patientMobileNumberController.dispose();
    patientAddressController.dispose();
    appointmentDateController.dispose();
    super.dispose();
  }

  Future<void> fetchDoctorDetails() async {
    try {
      String? doctorDetails = await _storage.read(key: 'logged_in_doctor');
      if (doctorDetails != null) {
        var decodedDetails = json.decode(doctorDetails);
        setState(() {
          doctorId = decodedDetails['doctorid'] != null
              ? int.tryParse(decodedDetails['doctorid'].toString())
              : null;
          hospitalName = decodedDetails['hospital_name'];
          hospitalLocation = decodedDetails['hospital_location'];
        });
        if (doctorId == null || hospitalName == null || hospitalLocation == null) {
          _showModernAlert('Error', 'Doctor details not found', isError: true);
        }
      } else {
        _showModernAlert('Error', 'Doctor details not found', isError: true);
      }
    } catch (e) {
      _showModernAlert('Error', 'Error parsing doctor details.', isError: true);
    }
  }

  Future<void> handleAddPatient() async {
    if (!_formKey.currentState!.validate()) return;
    if (gender.isEmpty) {
      _showModernAlert('Validation Error', 'Please select a gender', isError: true);
      return;
    }
    if (selectedTimeSlot == null) {
      _showModernAlert('Validation Error', 'Please select a time slot', isError: true);
      return;
    }

    setState(() => isLoading = true);

    try {
      String formattedDate = DateFormat('yyyy-MM-dd').format(appointmentDate);
      String patientMobile = '+91 ${patientMobileNumberController.text.trim()}';

      if (!RegExp(r'^\+91\s\d{10}$').hasMatch(patientMobile)) {
        _showModernAlert('Invalid Input', 'Please enter a valid Indian mobile number', isError: true);
        setState(() => isLoading = false);
        return;
      }

      var requestBody = json.encode({
        'doctorid': doctorId,
        'patient_name': patientNameController.text,
        'patient_age': patientAgeController.text,
        'patient_gender': gender,
        'patient_problem': patientProblemController.text,
        'appointment_date': '$formattedDate $selectedTimeSlot',
        'patient_mobile_number': patientMobile,
        'patient_address': patientAddressController.text,
        'hospital_name': hospitalName,
        'hospital_location': hospitalLocation,
      });

      var response = await http.post(
        Uri.parse('$baseUrl/addpatient.php'),
        headers: {"Content-Type": "application/json"},
        body: requestBody,
      );

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        if (jsonResponse['success']) {
          _showModernAlert('Success', 'Patient added successfully', onPressed: () {
            Navigator.pushReplacementNamed(context, '/doctorDashboard');
          });
        } else {
          _showModernAlert('Error', jsonResponse['message'] ?? 'An error occurred', isError: true);
        }
      } else {
        _showModernAlert('Error', 'Server returned an error: ${response.statusCode}', isError: true);
      }
    } catch (error) {
      _showModernAlert('Error', 'An error occurred while adding the patient', isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showModernAlert(String title, String message, {bool isError = false, VoidCallback? onPressed}) {
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
                  color: (isError ? Colors.red : Colors.green).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isError ? Icons.error_outline : Icons.check_circle_outline,
                  color: isError ? Colors.red : Colors.green,
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: appointmentDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF3B82F6),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null && pickedDate != appointmentDate) {
      setState(() {
        appointmentDate = pickedDate;
        appointmentDateController.text = DateFormat('yyyy-MM-dd').format(appointmentDate);
      });
    }
  }

  void nextPage() {
    if (currentPage < 1) {
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
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _buildModernHeader(),
                _buildProgressIndicator(),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (page) {
                        setState(() => currentPage = page);
                      },
                      children: [
                        _buildPatientInfoPage(),
                        _buildAppointmentPage(),
                      ],
                    ),
                  ),
                ),
                _buildNavigationButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
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
            'Add New Patient',
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
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: List.generate(2, (index) {
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < 1 ? 8 : 0),
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
    );
  }

  Widget _buildPatientInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Patient Information',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter the patient\'s basic details',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 32),

          _buildModernTextField('Patient Name', patientNameController, Icons.person_outline),
          const SizedBox(height: 20),
          _buildModernTextField('Patient Age', patientAgeController, Icons.cake_outlined, keyboardType: TextInputType.number),
          const SizedBox(height: 24),
          _buildGenderSelection(),
          const SizedBox(height: 20),
          _buildModernTextField('Patient Problem', patientProblemController, Icons.local_hospital, maxLines: 3),
          const SizedBox(height: 20),
          _buildContactField(),
          const SizedBox(height: 20),
          _buildModernTextField('Patient Address', patientAddressController, Icons.location_on_outlined, maxLines: 2),
        ],
      ),
    );
  }

  Widget _buildAppointmentPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Appointment Details',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Schedule the patient\'s appointment',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 32),

          // Date Picker
          GestureDetector(
            onTap: () => _selectDate(context),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.calendar_today, color: Color(0xFF3B82F6), size: 20),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Appointment Date',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          appointmentDateController.text,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF1E293B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF64748B)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Time Slot Selection
          const Text(
            'Select Time Slot',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, color: const Color(0xFF3B82F6), size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Available Time Slots',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 200,
                  padding: const EdgeInsets.all(16),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 2.5,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: timeSlots.length,
                    itemBuilder: (context, index) {
                      String slot = timeSlots[index];
                      bool isSelected = selectedTimeSlot == slot;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedTimeSlot = slot;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF3B82F6) : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF3B82F6) : Colors.grey.withOpacity(0.3),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              slot,
                              style: TextStyle(
                                color: isSelected ? Colors.white : const Color(0xFF64748B),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTextField(String label, TextEditingController controller, IconData icon, {TextInputType? keyboardType, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
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
          child: _buildModernTextField('Mobile Number', patientMobileNumberController, Icons.phone, keyboardType: TextInputType.phone),
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
                    gender = genderOption.toLowerCase();
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: gender == genderOption.toLowerCase()
                        ? const Color(0xFF3B82F6)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: gender == genderOption.toLowerCase()
                          ? const Color(0xFF3B82F6)
                          : Colors.grey.withOpacity(0.2),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      genderOption,
                      style: TextStyle(
                        color: gender == genderOption.toLowerCase() ? Colors.white : const Color(0xFF64748B),
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

  Widget _buildNavigationButtons() {
    return Container(
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
              onPressed: isLoading
                  ? null
                  : (currentPage == 1 ? handleAddPatient : nextPage),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: isLoading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : Text(
                currentPage == 1 ? 'Add Patient' : 'Next',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}