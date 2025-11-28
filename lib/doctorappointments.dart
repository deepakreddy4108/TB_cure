import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'main.dart';
import 'patient_details.dart';

class PatientDetailsScreen extends StatelessWidget {
  final String patientid;

  const PatientDetailsScreen({required this.patientid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Patient Details')),
      body: Center(
        child: Text('Patient ID: $patientid'),
      ),
    );
  }
}

class DoctorAppointments extends StatefulWidget {
  @override
  _DoctorAppointmentsState createState() => _DoctorAppointmentsState();
}

class _DoctorAppointmentsState extends State<DoctorAppointments>
    with TickerProviderStateMixin {
  List<dynamic> upcomingAppointments = [];
  List<dynamic> completedAppointments = [];
  List<dynamic> filteredUpcomingAppointments = [];
  List<dynamic> filteredCompletedAppointments = [];
  bool loading = true;
  String activeTab = 'upcoming';

  final _storage = const FlutterSecureStorage();
  TextEditingController _searchController = TextEditingController();

  late AnimationController _fadeController;
  late AnimationController _listController;
  late TabController _tabController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    fetchAppointments();
    _searchController.addListener(_filterAppointments);
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

    _tabController = TabController(length: 2, vsync: this);

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
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchAppointments() async {
    try {
      String? doctorId = await _storage.read(key: 'doctor_id');
      if (doctorId == null) {
        setState(() => loading = false);
        return;
      }

      // Fetch upcoming appointments
      final response = await http.post(
        Uri.parse('${baseUrl}/fetchdoctorappointments.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'doctorid': doctorId,
          'appointment_type': 'upcoming',
        }),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['success']) {
          upcomingAppointments = data['appointments'] ?? [];
          filteredUpcomingAppointments = upcomingAppointments;
        }
      }

      // Fetch completed appointments
      final completedResponse = await http.post(
        Uri.parse('${baseUrl}/fetchdoctorappointments.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'doctorid': doctorId,
          'appointment_type': 'completed',
        }),
      );

      if (completedResponse.statusCode == 200) {
        var data = jsonDecode(completedResponse.body);
        if (data['success']) {
          completedAppointments = data['appointments'] ?? [];
          filteredCompletedAppointments = completedAppointments;
        }
      }

      setState(() => loading = false);
      _listController.forward();
    } catch (error) {
      setState(() => loading = false);
      _showErrorMessage('Error fetching appointments: $error');
    }
  }

  Future<void> updateAppointmentStatus(String appointmentid, String status) async {
    try {
      String formattedStatus = '${status[0].toUpperCase()}${status.substring(1).toLowerCase()}';

      if (formattedStatus != 'Accepted' && formattedStatus != 'Rejected') {
        _showErrorMessage('Invalid status value: $formattedStatus');
        return;
      }

      String? doctorId = await _storage.read(key: 'doctor_id');
      if (doctorId == null || doctorId.isEmpty) {
        _showErrorMessage('Doctor ID is missing!');
        return;
      }

      final response = await http.post(
        Uri.parse('${baseUrl}/fetchdoctorappointments.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'doctorid': doctorId,
          'status': formattedStatus,
          'appointmentid': appointmentid,
        }),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['success']) {
          _showSuccessMessage('Appointment status updated to $formattedStatus');
          await fetchAppointments();
        }
      }
    } catch (error) {
      _showErrorMessage('Error updating status: $error');
    }
  }

  void _filterAppointments() {
    setState(() {
      filteredUpcomingAppointments = upcomingAppointments
          .where((appointment) => appointment['patient_name']
          .toLowerCase()
          .contains(_searchController.text.toLowerCase()))
          .toList();

      filteredCompletedAppointments = completedAppointments
          .where((appointment) => appointment['patient_name']
          .toLowerCase()
          .contains(_searchController.text.toLowerCase()))
          .toList();
    });
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green.shade600,
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
          child: loading
              ? _buildLoadingState()
              : FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _buildModernHeader(),
                _buildInfoCard(),
                _buildSearchBar(),
                _buildTabSelector(),
                Expanded(child: _buildAppointmentsList()),
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
            strokeWidth: 3,
          ),
          SizedBox(height: 16),
          Text(
            'Loading appointments...',
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
          Column(
            children: [
              const Text(
                'Appointments',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                '${upcomingAppointments.length} upcoming, ${completedAppointments.length} completed',
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
    );
  }

  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.info_outline, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Tap appointment cards to view patient details and AI predictions',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search appointments by patient name...',
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.search, color: Color(0xFF3B82F6), size: 20),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => activeTab = 'upcoming'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: activeTab == 'upcoming'
                      ? const Color(0xFF3B82F6)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'Upcoming',
                    style: TextStyle(
                      color: activeTab == 'upcoming' ? Colors.white : const Color(0xFF64748B),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => activeTab = 'completed'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: activeTab == 'completed'
                      ? const Color(0xFF3B82F6)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'Completed',
                    style: TextStyle(
                      color: activeTab == 'completed' ? Colors.white : const Color(0xFF64748B),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsList() {
    List<dynamic> appointments = activeTab == 'upcoming'
        ? filteredUpcomingAppointments
        : filteredCompletedAppointments;

    if (appointments.isEmpty) {
      return _buildEmptyState();
    }

    return SlideTransition(
      position: _slideAnimation,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          return ModernAppointmentCard(
            appointment: appointments[index],
            searchText: _searchController.text,
            onStatusUpdate: updateAppointmentStatus,
            onTap: () => _navigateToPatientDetails(appointments[index]),
            index: index,
          );
        },
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
              Icons.event_note,
              size: 60,
              color: Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No ${activeTab} appointments',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty
                ? 'Try adjusting your search terms'
                : 'New appointments will appear here',
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToPatientDetails(dynamic appointment) async {
    String status = appointment['status'].toLowerCase();
    if (status != 'accepted' && status != 'rejected') {
      _showErrorMessage('You must accept or reject the appointment before viewing details.');
      return;
    }

    try {
      await _storage.write(key: 'appointment_id', value: appointment['appointmentid'].toString());
      await _storage.write(key: 'patient_id', value: appointment['patientid'].toString());
      await _storage.write(key: 'patient_name', value: appointment['patient_name']);
      await _storage.write(key: 'patient_gender', value: appointment['patient_gender']);
      await _storage.write(key: 'patient_problem', value: appointment['patient_problem']);
      await _storage.write(key: 'appointment_date', value: appointment['appointment_date']);
      await _storage.write(key: 'appointment_patient_age', value: appointment['patient_age'].toString());
      await _storage.write(key: 'appointment_patient_mobile_number', value: appointment['patient_mobile_number']);
      await _storage.write(key: 'appointment_patient_address', value: appointment['patient_address']);
      await _storage.write(key: 'appointment_status', value: appointment['status']);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PatientDetails(appointment: appointment),
        ),
      );
    } catch (error) {
      _showErrorMessage("Error storing appointment details");
    }
  }
}

class ModernAppointmentCard extends StatefulWidget {
  final dynamic appointment;
  final String searchText;
  final Function(String, String) onStatusUpdate;
  final VoidCallback onTap;
  final int index;

  const ModernAppointmentCard({
    Key? key,
    required this.appointment,
    required this.searchText,
    required this.onStatusUpdate,
    required this.onTap,
    required this.index,
  }) : super(key: key);

  @override
  _ModernAppointmentCardState createState() => _ModernAppointmentCardState();
}

class _ModernAppointmentCardState extends State<ModernAppointmentCard>
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

  List<TextSpan> _highlightText(String text, String searchText) {
    List<TextSpan> spans = [];
    if (searchText.isEmpty) {
      spans.add(TextSpan(text: text, style: const TextStyle(color: Colors.black)));
      return spans;
    }

    int start = 0;
    while (start < text.length) {
      int index = text.toLowerCase().indexOf(searchText.toLowerCase(), start);
      if (index == -1) {
        spans.add(TextSpan(text: text.substring(start), style: const TextStyle(color: Color(0xFF1E293B))));
        break;
      }
      if (start < index) {
        spans.add(TextSpan(text: text.substring(start, index), style: const TextStyle(color: Color(0xFF1E293B))));
      }
      spans.add(TextSpan(
        text: text.substring(index, index + searchText.length),
        style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold),
      ));
      start = index + searchText.length;
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    bool isPending = widget.appointment['status'].toLowerCase() == 'pending';
    String appointmentDate = widget.appointment['appointment_date'];
    List<String> dateTimeParts = appointmentDate.split(' ');
    String dateOnly = dateTimeParts[0];
    String slot = dateTimeParts.length > 1 ? '${dateTimeParts[1]} ${dateTimeParts[2]}' : 'N/A';

    return AnimatedBuilder(
      animation: _scaleController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) => _scaleController.forward(),
            onTapUp: (_) => _scaleController.reverse(),
            onTapCancel: () => _scaleController.reverse(),
            onTap: widget.onTap,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: isPending
                    ? Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3), width: 2)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: isPending
                        ? const Color(0xFFF59E0B).withOpacity(0.1)
                        : Colors.black.withOpacity(0.08),
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
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.person, color: Color(0xFF3B82F6), size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  children: _highlightText(widget.appointment['patient_name'], widget.searchText),
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                                ),
                              ),
                              Text(
                                widget.appointment['patient_gender'],
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildStatusBadge(widget.appointment['status']),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(Icons.medical_services, 'Problem', widget.appointment['patient_problem']),
                          const SizedBox(height: 8),
                          _buildDetailRow(Icons.calendar_today, 'Date', dateOnly),
                          const SizedBox(height: 8),
                          _buildDetailRow(Icons.access_time, 'Time', slot),
                        ],
                      ),
                    ),

                    if (isPending) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => widget.onStatusUpdate(widget.appointment['appointmentid'].toString(), 'accepted'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_rounded, color: Colors.green, size: 18),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Accept',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => widget.onStatusUpdate(widget.appointment['appointmentid'].toString(), 'rejected'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.close_rounded, color: Colors.red, size: 18),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Reject',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'accepted':
        statusColor = Colors.green;
        statusText = 'Accepted';
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'Rejected';
        statusIcon = Icons.cancel;
        break;
      case 'pending':
        statusColor = const Color(0xFFF59E0B);
        statusText = 'Pending';
        statusIcon = Icons.schedule;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, color: statusColor, size: 16),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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