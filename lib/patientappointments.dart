import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'main.dart';

class PatientAppointments extends StatefulWidget {
  @override
  _PatientAppointmentsState createState() => _PatientAppointmentsState();
}

class _PatientAppointmentsState extends State<PatientAppointments>
    with TickerProviderStateMixin {
  List<dynamic> upcomingAppointments = [];
  List<dynamic> completedAppointments = [];
  List<dynamic> filteredAppointments = [];
  bool loading = true;
  String activeTab = 'upcoming';
  final _storage = const FlutterSecureStorage();
  TextEditingController searchController = TextEditingController();

  late AnimationController _fadeController;
  late AnimationController _listController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    fetchAppointments();
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

  Future<void> fetchAppointments() async {
    try {
      String? patientId = await _storage.read(key: 'patient_id');
      if (patientId == null) {
        setState(() => loading = false);
        _showErrorMessage('Patient ID not found. Please log in again.');
        return;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/patientappointments.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'patientid': patientId}),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['success']) {
          List<dynamic> allAppointments = data['patients'] ?? [];
          categorizeAppointments(allAppointments);
          _listController.forward();
        } else {
          _showErrorMessage(data['message'] ?? 'Failed to load appointments');
        }
      } else {
        _showErrorMessage('Server error: ${response.statusCode}');
      }

      setState(() => loading = false);
    } catch (error) {
      setState(() => loading = false);
      _showErrorMessage('An error occurred while fetching appointments');
    }
  }

  void categorizeAppointments(List<dynamic> appointments) {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    upcomingAppointments.clear();
    completedAppointments.clear();

    for (var appointment in appointments) {
      DateTime appointmentDate = DateFormat('yyyy-MM-dd').parse(appointment['appointment_date']);
      if (appointmentDate.isAfter(today) || appointmentDate.isAtSameMomentAs(today)) {
        upcomingAppointments.add(appointment);
      } else {
        completedAppointments.add(appointment);
      }
    }

    updateFilteredAppointments();
  }

  void handleTabPress(String tab) {
    setState(() {
      activeTab = tab;
      updateFilteredAppointments();
    });
  }

  void updateFilteredAppointments() {
    String query = searchController.text.toLowerCase();
    List<dynamic> appointments = activeTab == 'upcoming' ? upcomingAppointments : completedAppointments;

    if (query.isEmpty) {
      filteredAppointments = appointments;
    } else {
      filteredAppointments = appointments
          .where((appointment) =>
          appointment['patient_name'].toLowerCase().contains(query))
          .toList();
    }
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

  String _getAppointmentDate(String appointmentDateTime) {
    try {
      if (appointmentDateTime.contains(' ')) {
        DateFormat format = DateFormat('yyyy-MM-dd hh:mm a');
        DateTime parsedDateTime = format.parse(appointmentDateTime);
        return DateFormat('MMM dd, yyyy').format(parsedDateTime);
      } else {
        DateFormat format = DateFormat('yyyy-MM-dd');
        DateTime parsedDate = format.parse(appointmentDateTime);
        return DateFormat('MMM dd, yyyy').format(parsedDate);
      }
    } catch (e) {
      return appointmentDateTime;
    }
  }

  String _getAppointmentTime(String? appointmentDateTime) {
    if (appointmentDateTime == null || appointmentDateTime.isEmpty) {
      return 'Time not set';
    }
    try {
      DateFormat format = DateFormat('yyyy-MM-dd hh:mm a');
      DateTime parsedDateTime = format.parse(appointmentDateTime);
      return DateFormat('hh:mm a').format(parsedDateTime);
    } catch (e) {
      return 'Time not available';
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
              Color(0xFFF0FDF4),
              Color(0xFFDCFCE7),
              Color(0xFFBBF7D0),
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
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
            strokeWidth: 3,
          ),
          SizedBox(height: 16),
          Text(
            'Loading your appointments...',
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
                'My Appointments',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              if (!loading)
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
        controller: searchController,
        onChanged: (query) {
          setState(() {
            updateFilteredAppointments();
          });
        },
        decoration: InputDecoration(
          hintText: 'Search appointments by name...',
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.search, color: Color(0xFF10B981), size: 20),
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
              onTap: () => handleTabPress('upcoming'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: activeTab == 'upcoming'
                      ? const Color(0xFF10B981)
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
              onTap: () => handleTabPress('completed'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: activeTab == 'completed'
                      ? const Color(0xFF10B981)
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
    if (filteredAppointments.isEmpty) {
      return _buildEmptyState();
    }

    return SlideTransition(
      position: _slideAnimation,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filteredAppointments.length,
        itemBuilder: (context, index) {
          return ModernAppointmentCard(
            appointment: filteredAppointments[index],
            searchQuery: searchController.text,
            getAppointmentDate: _getAppointmentDate,
            getAppointmentTime: _getAppointmentTime,
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
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(
              Icons.event_note,
              size: 60,
              color: Color(0xFF10B981),
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
            searchController.text.isNotEmpty
                ? 'Try adjusting your search terms'
                : 'Your appointments will appear here',
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

class ModernAppointmentCard extends StatefulWidget {
  final dynamic appointment;
  final String searchQuery;
  final String Function(String) getAppointmentDate;
  final String Function(String?) getAppointmentTime;
  final int index;

  const ModernAppointmentCard({
    Key? key,
    required this.appointment,
    required this.searchQuery,
    required this.getAppointmentDate,
    required this.getAppointmentTime,
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
      spans.add(TextSpan(text: text, style: const TextStyle(color: Color(0xFF1E293B))));
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
        style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold),
      ));
      start = index + searchText.length;
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    String status = widget.appointment['status']?.toLowerCase() ?? 'pending';

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
              border: _getStatusBorder(status),
              boxShadow: [
                BoxShadow(
                  color: _getStatusColor(status).withOpacity(0.1),
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
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.person, color: Color(0xFF10B981), size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                children: _highlightText(widget.appointment['patient_name'], widget.searchQuery),
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                              ),
                            ),
                            Text(
                              'Age: ${widget.appointment['patient_age']}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildStatusBadge(status),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(Icons.medical_services, 'Problem', widget.appointment['patient_problem']),
                        const SizedBox(height: 8),
                        _buildDetailRow(Icons.calendar_today, 'Date', widget.getAppointmentDate(widget.appointment['appointment_date'])),
                        const SizedBox(height: 8),
                        _buildDetailRow(Icons.access_time, 'Time', widget.getAppointmentTime(widget.appointment['appointment_date'])),
                      ],
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

  Widget _buildStatusBadge(String status) {
    Color statusColor = _getStatusColor(status);
    String statusText = _getStatusText(status);
    IconData statusIcon = _getStatusIcon(status);

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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return const Color(0xFFF59E0B);
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'accepted':
        return 'Accepted';
      case 'rejected':
        return 'Rejected';
      case 'pending':
      default:
        return 'Pending';
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'accepted':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'pending':
      default:
        return Icons.schedule;
    }
  }

  Border? _getStatusBorder(String status) {
    Color statusColor = _getStatusColor(status);
    return Border.all(color: statusColor.withOpacity(0.3), width: 2);
  }
}