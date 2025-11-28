import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'main.dart';

class ConnectWithPatients extends StatefulWidget {
  @override
  _ConnectWithPatientsState createState() => _ConnectWithPatientsState();
}

class _ConnectWithPatientsState extends State<ConnectWithPatients>
    with TickerProviderStateMixin {
  final _storage = const FlutterSecureStorage();
  List<dynamic> patients = [];
  List<dynamic> filteredPatients = [];
  TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  bool _isLoading = true;

  late AnimationController _fadeController;
  late AnimationController _listController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    fetchPatients();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _listController = AnimationController(
      duration: const Duration(milliseconds: 1000),
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
      parent: _listController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _listController.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchPatients() async {
    try {
      String? doctorId = await _storage.read(key: 'doctor_id');
      if (doctorId == null) throw Exception('Doctor ID not found');

      final response = await http.post(
        Uri.parse('$baseUrl/connect_with_patient.php'),
        body: {'doctorid': doctorId},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          setState(() {
            patients = data['patients'];
            filteredPatients = patients;
            _isLoading = false;
          });
          _listController.forward();
        } else {
          _showModernError(data['message'] ?? 'Failed to load patients');
        }
      } else {
        _showModernError('Server error: ${response.statusCode}');
      }
    } catch (e) {
      _showModernError('An error occurred: $e');
    }
  }

  void filterPatients(String query) {
    setState(() {
      searchQuery = query;
      filteredPatients = patients.where((patient) {
        return patient['patient_name']
            .toString()
            .toLowerCase()
            .contains(query.toLowerCase()) ||
            patient['patientid'].toString().contains(query);
      }).toList();
    });
  }

  void launchWhatsApp(String phoneNumber) async {
    final message = "Dear Patient, I am your consulting Dentist. I've reviewed your recent dental records and would like to discuss them with you. Please let me know when you're available for a consultation.";
    final whatsappUrl = "https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}";

    try {
      if (await canLaunch(whatsappUrl)) {
        await launch(whatsappUrl);
      } else {
        _showModernError('Could not open WhatsApp');
      }
    } catch (e) {
      _showModernError('Error opening WhatsApp: $e');
    }
  }

  void _showModernError(String message) {
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
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
                // Modern Header
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
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
                              child: const Icon(
                                Icons.arrow_back_ios_new,
                                color: Color(0xFF334155),
                                size: 20,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Column(
                            children: [
                              const Text(
                                'Connect with Patients',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              Text(
                                '${patients.length} patients available',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          const SizedBox(width: 44),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Modern Search Bar
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: searchController,
                          onChanged: filterPatients,
                          decoration: InputDecoration(
                            hintText: 'Search patients by name or ID...',
                            hintStyle: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 16,
                            ),
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(12),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.search,
                                color: Color(0xFF3B82F6),
                                size: 20,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 20,
                              horizontal: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content Area
                Expanded(
                  child: _isLoading
                      ? _buildLoadingState()
                      : filteredPatients.isEmpty
                      ? _buildEmptyState()
                      : _buildPatientsList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
          ),
          SizedBox(height: 16),
          Text(
            'Loading patients...',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(
              Icons.people_outline,
              size: 60,
              color: Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No patients found',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isNotEmpty
                ? 'Try adjusting your search terms'
                : 'No patients are currently available',
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientsList() {
    return SlideTransition(
      position: _slideAnimation,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filteredPatients.length,
        itemBuilder: (context, index) {
          return ModernPatientCard(
            patient: filteredPatients[index],
            searchQuery: searchQuery,
            launchWhatsApp: launchWhatsApp,
            index: index,
          );
        },
      ),
    );
  }
}

class ModernPatientCard extends StatefulWidget {
  final dynamic patient;
  final String searchQuery;
  final Function(String) launchWhatsApp;
  final int index;

  const ModernPatientCard({
    Key? key,
    required this.patient,
    required this.searchQuery,
    required this.launchWhatsApp,
    required this.index,
  }) : super(key: key);

  @override
  _ModernPatientCardState createState() => _ModernPatientCardState();
}

class _ModernPatientCardState extends State<ModernPatientCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  TextSpan _highlightText(String text, String query,
      {TextStyle? normalStyle, TextStyle? highlightStyle}) {
    if (query.isEmpty) return TextSpan(text: text, style: normalStyle);
    final matches = query.toLowerCase();
    final lowerText = text.toLowerCase();
    final startIndex = lowerText.indexOf(matches);

    if (startIndex == -1) {
      return TextSpan(text: text, style: normalStyle);
    }

    final endIndex = startIndex + matches.length;

    return TextSpan(
      children: [
        TextSpan(text: text.substring(0, startIndex), style: normalStyle),
        TextSpan(
            text: text.substring(startIndex, endIndex), style: highlightStyle),
        TextSpan(text: text.substring(endIndex), style: normalStyle),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    String ageText = widget.patient['patient_age'] != null
        ? '${widget.patient['patient_age']} years'
        : 'Age not available';

    return AnimatedBuilder(
      animation: _scaleController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Profile Image
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3B82F6).withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: widget.patient['profile_image'] != '0'
                            ? CircleAvatar(
                          radius: 32,
                          backgroundImage: NetworkImage(
                            '$baseUrl/img/patient_profile_images/${widget.patient['profile_image']}',
                          ),
                        )
                            : CircleAvatar(
                          radius: 32,
                          backgroundColor: const Color(0xFF3B82F6),
                          child: Text(
                            widget.patient['patient_name'][0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Patient Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: _highlightText(
                                widget.patient['patient_name'],
                                widget.searchQuery,
                                normalStyle: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E293B),
                                ),
                                highlightStyle: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF3B82F6),
                                ),
                              ),
                            ),

                            const SizedBox(height: 4),

                            RichText(
                              text: _highlightText(
                                'ID: ${widget.patient['patientid']}',
                                widget.searchQuery,
                                normalStyle: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                                highlightStyle: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF3B82F6),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Active',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Patient Details
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          Icons.person_outline,
                          'Gender',
                          widget.patient['patient_gender'],
                        ),
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          Icons.cake_outlined,
                          'Age',
                          ageText,
                        ),
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          Icons.phone_outlined,
                          'Mobile',
                          widget.patient['patient_mobile_number'],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // WhatsApp Button
                  GestureDetector(
                    onTapDown: (_) => _scaleController.forward(),
                    onTapUp: (_) => _scaleController.reverse(),
                    onTapCancel: () => _scaleController.reverse(),
                    onTap: () => widget.launchWhatsApp(widget.patient['patient_mobile_number']),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF25D366), Color(0xFF128C7E)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF25D366).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.chat,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Connect on WhatsApp',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
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
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}