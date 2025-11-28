import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'dart:io';
import 'main.dart';
import 'operation_details.dart';

class DisplayOperationDetails extends StatefulWidget {
  final String doctorId;

  const DisplayOperationDetails({Key? key, required this.doctorId}) : super(key: key);

  @override
  _DisplayOperationDetailsState createState() => _DisplayOperationDetailsState();
}

String _formatSlot(String dateTime) {
  try {
    final DateTime parsedDateTime = DateTime.parse(dateTime);
    final String hour = DateFormat('hh').format(parsedDateTime);
    final String minute = DateFormat('mm').format(parsedDateTime);
    final String amPm = DateFormat('a').format(parsedDateTime).toUpperCase();
    return '$hour:$minute $amPm';
  } catch (e) {
    debugPrint("Error parsing slot time: $dateTime");
    return 'Invalid Slot';
  }
}

class _DisplayOperationDetailsState extends State<DisplayOperationDetails>
    with TickerProviderStateMixin {
  List<dynamic> upcoming = [];
  List<dynamic> completed = [];
  List<dynamic> filteredOperations = [];
  bool loading = true;
  bool isDownloading = false;
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
    debugPrint("Initializing state with doctorId: ${widget.doctorId}");
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
      final doctorId = widget.doctorId;
      debugPrint("Fetching operations for doctorId: $doctorId");

      if (doctorId.isEmpty) {
        setState(() => loading = false);
        return;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/fetchoperationdetails.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'doctorid': doctorId}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          List<dynamic> upcomingList = data['data']['upcoming'] ?? [];
          List<dynamic> completedList = data['data']['completed'] ?? [];

          setState(() {
            upcoming = upcomingList;
            completed = completedList;
            filteredOperations = activeTab == 'upcoming' ? upcoming : completed;
            loading = false;
          });
          _listController.forward();
        } else {
          setState(() => loading = false);
          _showErrorMessage(data['message'] ?? 'Failed to load operations');
        }
      } else {
        setState(() => loading = false);
        _showErrorMessage('Server error: ${response.statusCode}');
      }
    } catch (error) {
      setState(() => loading = false);
      _showErrorMessage('Error fetching operations: $error');
    }
  }

  void handleTabPress(String tab) {
    setState(() {
      activeTab = tab;
      _filterOperations();
    });
  }

  void _filterOperations() {
    List<dynamic> sourceList = activeTab == 'upcoming' ? upcoming : completed;
    setState(() {
      filteredOperations = sourceList
          .where((operation) =>
      operation['patient_name'].toString().toLowerCase().contains(searchQuery.toLowerCase()) ||
          operation['appointmentid'].toString().toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    });
  }

  void handleSearch(String query) {
    setState(() {
      searchQuery = query;
      _filterOperations();
    });
  }

  Future<void> navigateToOperationDetails(String appointmentId) async {
    await _storage.write(key: 'appointment_id', value: appointmentId);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => OperationDetailsPage()),
    );
  }

  Future<void> downloadCSV() async {
    setState(() => isDownloading = true);

    try {
      String csvContent = 'Doctor ID, Patient ID, Patient Name, Patient Age, Gender, Mobile Number, Patient Problem, Prediction, Teeth Measurements, Material Used, Operation Description, Operation Date\n';
      List<dynamic> allOperations = [...upcoming, ...completed];

      for (var operation in allOperations) {
        final appointmentId = operation['appointmentid'];
        final operationDetails = await fetchOperationDetails(appointmentId);

        for (var detail in operationDetails) {
          final row = [
            detail['doctorid'],
            detail['patientid'],
            detail['patient_name'],
            detail['patient_age'],
            detail['patient_gender'],
            detail['mobile_number'],
            detail['patient_problem'],
            detail['prediction'],
            detail['teeth_measurements'],
            detail['teeth_material'],
            detail['operation_description'],
            _formatDate(detail['operation_date']),
          ];
          csvContent += row.join(',') + '\n';
        }
      }

      if (Platform.isAndroid) {
        final directory = Directory('/storage/emulated/0/Download');
        if (await directory.exists()) {
          String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
          final file = File('${directory.path}/operation-details_$timestamp.csv');
          await file.writeAsString(csvContent, mode: FileMode.writeOnly, flush: true);
          _showDownloadDialog(file.path);
        }
      }
    } catch (e) {
      _showErrorMessage('Error during CSV download: $e');
    } finally {
      setState(() => isDownloading = false);
    }
  }

  void _showDownloadDialog(String filePath) {
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
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.download_done, color: Colors.green, size: 24),
              ),
              const SizedBox(width: 12),
              const Text('Download Completed', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          content: Text('CSV file has been downloaded at: $filePath',
              style: const TextStyle(color: Color(0xFF64748B))),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
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

  Future<List<Map<String, dynamic>>> fetchOperationDetails(String appointmentId) async {
    try {
      final url = Uri.parse('$baseUrl/operation_details.php?appointmentid=$appointmentId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] && data['data'] != null) {
          final details = data['data'];
          if (details is Map<String, dynamic>) {
            return [details];
          }
          if (details is List) {
            return List<Map<String, dynamic>>.from(details);
          }
        }
        return [];
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  String _formatDate(String date) {
    try {
      final DateTime parsedDate = DateTime.parse(date);
      return DateFormat('dd/MM/yyyy').format(parsedDate);
    } catch (e) {
      return date;
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
      floatingActionButton: loading
          ? null
          : _buildDownloadButton(),
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
                'Operation Details',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                '${upcoming.length} upcoming, ${completed.length} completed',
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
              onTap: () => handleTabPress('upcoming'),
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
              onTap: () => handleTabPress('completed'),
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
            onTap: () => navigateToOperationDetails(filteredOperations[index]['appointmentid'].toString()),
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
              Icons.healing,
              size: 60,
              color: Color(0xFF3B82F6),
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

  Widget _buildDownloadButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: isDownloading ? null : downloadCSV,
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: isDownloading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : const Icon(Icons.file_download_outlined, color: Colors.white),
        label: Text(
          isDownloading ? 'Downloading...' : 'Export CSV',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class ModernOperationCard extends StatefulWidget {
  final dynamic operation;
  final String searchQuery;
  final VoidCallback onTap;
  final int index;

  const ModernOperationCard({
    Key? key,
    required this.operation,
    required this.searchQuery,
    required this.onTap,
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
        style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold),
      ));
      start = index + searchText.length;
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    String appointmentId = widget.operation['appointmentid'].toString();
    String patientName = widget.operation['patient_name'].toString();
    String operationDate = DateFormat('yyyy-MM-dd').format(DateTime.parse(widget.operation['operation_date']));
    String slot = _formatSlot(widget.operation['operation_date']);

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
                            color: const Color(0xFF3B82F6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.assignment, color: Color(0xFF3B82F6), size: 24),
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
                        color: const Color(0xFFF8FAFC),
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