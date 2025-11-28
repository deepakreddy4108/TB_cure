import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'main.dart';

class OperationDetailsPage extends StatefulWidget {
  OperationDetailsPage({Key? key}) : super(key: key);

  @override
  _OperationDetailsPageState createState() => _OperationDetailsPageState();
}

class _OperationDetailsPageState extends State<OperationDetailsPage>
    with TickerProviderStateMixin {
  final _storage = const FlutterSecureStorage();

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
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
    super.dispose();
  }

  Future<Map<String, dynamic>?> fetchOperationDetails() async {
    final appointmentId = await _storage.read(key: 'appointment_id');
    if (appointmentId == null || appointmentId.isEmpty) {
      debugPrint("No appointment ID found in storage.");
      return null;
    }

    final url = Uri.parse('$baseUrl/operation_details.php?appointmentid=$appointmentId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] && data['data'] != null) {
        return data['data'];
      }
    }
    return null;
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
                Expanded(
                  child: FutureBuilder<Map<String, dynamic>?>(
                    future: fetchOperationDetails(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildLoadingState();
                      } else if (snapshot.hasError) {
                        return _buildErrorState('Error fetching details.');
                      } else if (!snapshot.hasData || snapshot.data == null) {
                        return _buildErrorState('No operation details available.');
                      } else {
                        return _buildDetailContent(snapshot.data!);
                      }
                    },
                  ),
                ),
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
            'Operation Details',
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

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
            strokeWidth: 3,
          ),
          SizedBox(height: 16),
          Text(
            'Loading operation details...',
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

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Error Loading Details',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailContent(Map<String, dynamic> data) {
    final imagePath = '$baseUrl/img/deeplearning_images/${data['image_address']}';

    return SlideTransition(
      position: _slideAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            // Image Section
            if (data['image_address'] != null)
              _buildImageSection(imagePath)
            else
              _buildNoImageSection(),

            const SizedBox(height: 24),

            // Patient Information Section
            _buildInfoSection(
              'Patient Information',
              Icons.person_rounded,
              const Color(0xFF3B82F6),
              [
                _buildDetailItem('Patient Name', data['patient_name'], Icons.person_outline),
                _buildDetailItem('Patient ID', data['patientid'].toString(), Icons.badge_outlined),
                _buildDetailItem('Age', data['patient_age'].toString(), Icons.cake_outlined),
                _buildDetailItem('Gender', data['patient_gender'], Icons.wc_outlined),
                _buildDetailItem('Mobile Number', data['mobile_number'], Icons.phone_outlined),
                _buildDetailItem('Patient Problem', data['patient_problem'], Icons.health_and_safety_outlined),
              ],
            ),

            const SizedBox(height: 20),

            // Medical Information Section
            _buildInfoSection(
              'Medical Details',
              Icons.medical_services_rounded,
              const Color(0xFF10B981),
              [
                _buildDetailItem('Doctor ID', data['doctorid'].toString(), Icons.medical_information_outlined),
                _buildDetailItem('Prediction', data['prediction'], Icons.analytics_outlined),
                _buildDetailItem('Teeth Measurements', data['teeth_measurements'].toString(), Icons.straighten_outlined),
                _buildDetailItem('Material Used', data['teeth_material'], Icons.architecture_outlined),
                _buildDetailItem('Operation Description', data['operation_description'], Icons.description_outlined),
              ],
            ),

            const SizedBox(height: 20),

            // Schedule Information Section
            _buildInfoSection(
              'Schedule Information',
              Icons.schedule_rounded,
              const Color(0xFFF59E0B),
              [
                _buildDetailItem('Operation Date', _formatDate(data['operation_date']), Icons.calendar_today_outlined),
                _buildDetailItem('Time Slot', _formatSlot(data['operation_date']), Icons.access_time_outlined),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(String imagePath) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.network(
            imagePath,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_not_supported, size: 60, color: Color(0xFF94A3B8)),
                      SizedBox(height: 12),
                      Text('Image not available', style: TextStyle(color: Color(0xFF64748B))),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNoImageSection() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, size: 60, color: Color(0xFF94A3B8)),
            SizedBox(height: 12),
            Text(
              'No Image Available',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, IconData icon, Color color, List<Widget> children) {
    return Container(
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
      child: Column(
        children: [
          // Section Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),

          // Section Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF64748B)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateTime) {
    try {
      final date = DateTime.parse(dateTime);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateTime.split(' ')[0];
    }
  }

  String _formatSlot(String dateTime) {
    try {
      final date = DateTime.parse(dateTime);
      final hour = date.hour;
      final minute = date.minute;
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      final parts = dateTime.split(' ');
      if (parts.length < 2) return 'Invalid Slot';
      final timeParts = parts[1].split(':');
      if (timeParts.length < 2) return 'Invalid Slot';

      final hour = int.parse(timeParts[0]);
      final minute = timeParts[1];
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

      return '$displayHour:$minute $period';
    }
  }
}