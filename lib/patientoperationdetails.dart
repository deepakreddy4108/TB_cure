import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'main.dart';
import 'operation_details.dart';

class PatientOperationDetails extends StatefulWidget {
  const PatientOperationDetails({Key? key}) : super(key: key);

  @override
  _PatientOperationDetailsState createState() => _PatientOperationDetailsState();
}

class _PatientOperationDetailsState extends State<PatientOperationDetails>
    with TickerProviderStateMixin {
  List<dynamic> upcomingOperations = [];
  List<dynamic> completedOperations = [];
  List<dynamic> filteredOperations = [];
  bool loading = true;
  String activeTab = 'upcoming';
  String searchQuery = '';
  final _storage = const FlutterSecureStorage();
  final TextEditingController _searchController = TextEditingController();

  late AnimationController _fadeController;
  late AnimationController _listController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    fetchOperations();
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
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchOperations() async {
    try {
      String? patientId = await _storage.read(key: 'patient_id');
      if (patientId == null) {
        print('Error: Patient ID not found in Secure Storage.');
        setState(() => loading = false);
        return;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/patientoperationdetails.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'patientid': patientId}),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        if (data['status'] != 'success' || data['data'] == null || data['data']['operations'] == null) {
          print('No operations found in the response.');
          setState(() => loading = false);
          return;
        }

        List<dynamic> operations = data['data']['operations'];
        categorizeOperations(operations);
        _listController.forward();
      } else {
        print('API Error: Status Code ${response.statusCode}');
        _showErrorMessage('Server error: ${response.statusCode}');
      }

      setState(() => loading = false);
    } catch (error) {
      print('Error fetching operations: $error');
      _showErrorMessage('An error occurred while fetching operations');
      setState(() => loading = false);
    }
  }

  void categorizeOperations(List<dynamic> operations) {
    DateTime today = DateTime.now();
    upcomingOperations.clear();
    completedOperations.clear();

    for (var operation in operations) {
      DateTime operationDate = DateFormat('yyyy-MM-dd').parse(operation['operation_date']);
      if (operationDate.isAfter(today) || operationDate.isAtSameMomentAs(today)) {
        upcomingOperations.add(operation);
      } else {
        completedOperations.add(operation);
      }
    }
    setState(() {
      filteredOperations = upcomingOperations;
    });
  }

  void handleTabPress(String tab) {
    setState(() {
      activeTab = tab;
      searchQuery = '';
      _searchController.clear();
      filteredOperations = tab == 'upcoming' ? upcomingOperations : completedOperations;
    });
  }

  Future<void> handleCardTap(String appointmentId) async {
    await _storage.write(key: 'appointment_id', value: appointmentId);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => OperationDetailsPage()),
    );
  }

  void handleSearch(String query) {
    setState(() {
      searchQuery = query;
      filteredOperations = (activeTab == 'upcoming' ? upcomingOperations : completedOperations)
          .where((operation) =>
      operation['patient_name'].toString().toLowerCase().contains(query.toLowerCase()) ||
          operation['appointmentid'].toString().toLowerCase().contains(query.toLowerCase()))
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

  String _formatSlot(String dateTime) {
    try {
      final DateTime parsedDateTime = DateTime.parse(dateTime);
      final String formattedTime = DateFormat('hh:mm a').format(parsedDateTime);
      return formattedTime;
    } catch (e) {
      print('Error parsing dateTime: $e');
      return 'Invalid Time';
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
                Expanded(child: _buildOperationsList()),
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
            'Loading operations...',
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
                'My Operations',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                '${upcomingOperations.length} upcoming, ${completedOperations.length} completed',
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
        controller: _searchController,
        onChanged: handleSearch,
        decoration: InputDecoration(
          hintText: 'Search by patient name or appointment ID...',
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

  Widget _buildOperationsList() {
    if (filteredOperations.isEmpty) {
      return _buildEmptyState();
    }

    return SlideTransition(
      position: _slideAnimation,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filteredOperations.length,
        itemBuilder: (context, index) {
          return ModernOperationCard(
            operation: filteredOperations[index],
            searchQuery: searchQuery,
            onTap: () => handleCardTap(filteredOperations[index]['appointmentid']),
            formatSlot: _formatSlot,
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
              Icons.healing,
              size: 60,
              color: Color(0xFF10B981),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No ${activeTab} operations',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isNotEmpty
                ? 'Try adjusting your search terms'
                : 'Operations will appear here when available',
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

class ModernOperationCard extends StatefulWidget {
  final dynamic operation;
  final String searchQuery;
  final VoidCallback onTap;
  final String Function(String) formatSlot;
  final int index;

  const ModernOperationCard({
    Key? key,
    required this.operation,
    required this.searchQuery,
    required this.onTap,
    required this.formatSlot,
    required this.index,
  }) : super(key: key);

  @override
  _ModernOperationCardState createState() => _ModernOperationCardState();
}

class _ModernOperationCardState extends State<ModernOperationCard>
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
    String appointmentId = widget.operation['appointmentid'].toString();
    String patientName = widget.operation['patient_name'].toString();
    String operationDate = widget.operation['operation_date'].split(' ')[0];
    String slot = widget.formatSlot(widget.operation['operation_date']);

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
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.assignment, color: Color(0xFF10B981), size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  children: _highlightText('ID: $appointmentId', widget.searchQuery),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(height: 4),
                              RichText(
                                text: TextSpan(
                                  children: _highlightText(patientName, widget.searchQuery),
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF64748B)),
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
                          _buildDetailRow(Icons.analytics, 'Prediction', widget.operation['prediction']),
                          const SizedBox(height: 8),
                          _buildDetailRow(Icons.calendar_today, 'Operation Date', operationDate),
                          const SizedBox(height: 8),
                          _buildDetailRow(Icons.access_time, 'Time Slot', slot),
                        ],
                      ),
                    ),
                  ],
                ),
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