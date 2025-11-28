import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'main.dart';

class ConnectWithDoctor extends StatefulWidget {
  @override
  _ConnectWithDoctorsState createState() => _ConnectWithDoctorsState();
}

class _ConnectWithDoctorsState extends State<ConnectWithDoctor>
    with TickerProviderStateMixin {
  List<dynamic> doctors = [];
  List<dynamic> filteredDoctors = [];
  TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  bool isLoading = true;

  late AnimationController _fadeController;
  late AnimationController _listController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    fetchDoctors();
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

  Future<void> fetchDoctors() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/connect_with_doctor.php'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          setState(() {
            doctors = data['doctors'];
            filteredDoctors = doctors;
            isLoading = false;
          });
          _listController.forward();
        } else {
          _showErrorMessage('Failed to load doctors');
        }
      } else {
        _showErrorMessage('Server error: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorMessage('An error occurred while fetching doctors');
    }

    setState(() => isLoading = false);
  }

  void filterDoctors(String query) {
    setState(() {
      searchQuery = query;
      filteredDoctors = doctors.where((doctor) {
        return doctor['name'].toLowerCase().contains(query.toLowerCase()) ||
            doctor['doctorid'].toString().contains(query) ||
            doctor['specialization'].toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  void launchWhatsApp(String phoneNumber) async {
    final message = "Hello Doctor, I'd like to schedule a consultation to discuss some dental concerns. Please let me know your availability.";
    final whatsappUrl = "https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}";

    try {
      if (await canLaunch(whatsappUrl)) {
        await launch(whatsappUrl);
      } else {
        _showErrorMessage('Could not open WhatsApp');
      }
    } catch (e) {
      _showErrorMessage('Error opening WhatsApp: $e');
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
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _buildModernHeader(),
                _buildInfoCard(),
                _buildSearchBar(),
                Expanded(
                  child: isLoading
                      ? _buildLoadingState()
                      : filteredDoctors.isEmpty
                      ? _buildEmptyState()
                      : _buildDoctorsList(),
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
                'Connect with Doctor',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              if (!isLoading)
                Text(
                  '${doctors.length} doctors available',
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
          colors: [Color(0xFF10B981), Color(0xFF059669)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.3),
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
            child: const Icon(Icons.medical_services, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Connect with qualified doctors and schedule consultations via WhatsApp',
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
        controller: searchController,
        onChanged: filterDoctors,
        decoration: InputDecoration(
          hintText: 'Search by name, ID, or specialization...',
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
            'Loading doctors...',
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
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(
              Icons.person_search,
              size: 60,
              color: Color(0xFF10B981),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No doctors found',
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
                : 'No doctors are currently available',
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorsList() {
    return SlideTransition(
      position: _slideAnimation,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filteredDoctors.length,
        itemBuilder: (context, index) {
          return ModernDoctorCard(
            doctor: filteredDoctors[index],
            searchQuery: searchQuery,
            launchWhatsApp: launchWhatsApp,
            index: index,
          );
        },
      ),
    );
  }
}

class ModernDoctorCard extends StatefulWidget {
  final dynamic doctor;
  final String searchQuery;
  final Function(String) launchWhatsApp;
  final int index;

  const ModernDoctorCard({
    Key? key,
    required this.doctor,
    required this.searchQuery,
    required this.launchWhatsApp,
    required this.index,
  }) : super(key: key);

  @override
  _ModernDoctorCardState createState() => _ModernDoctorCardState();
}

class _ModernDoctorCardState extends State<ModernDoctorCard>
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
                      // Profile Image with Status Indicator
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF10B981).withOpacity(0.2),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: widget.doctor['profile_image'] != null
                                ? CircleAvatar(
                              radius: 32,
                              backgroundImage: NetworkImage(
                                '$baseUrl/img/doctor_profile_images/${widget.doctor['profile_image']}',
                              ),
                            )
                                : CircleAvatar(
                              radius: 32,
                              backgroundColor: const Color(0xFF10B981),
                              child: Text(
                                widget.doctor['name'][0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(width: 16),

                      // Doctor Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                children: _highlightText('Dr. ${widget.doctor['name']}', widget.searchQuery),
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                              ),
                            ),

                            const SizedBox(height: 4),

                            RichText(
                              text: TextSpan(
                                children: _highlightText(widget.doctor['specialization'], widget.searchQuery),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF10B981)),
                              ),
                            ),

                            const SizedBox(height: 4),

                            RichText(
                              text: TextSpan(
                                children: _highlightText('ID: ${widget.doctor['doctorid']}', widget.searchQuery),
                                style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Experience Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${widget.doctor['experience']}y exp',
                          style: const TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Doctor Details
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          Icons.phone_outlined,
                          'Contact',
                          widget.doctor['contactno'],
                        ),
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          Icons.work_outline,
                          'Experience',
                          '${widget.doctor['experience']} years',
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
                    onTap: () => widget.launchWhatsApp(widget.doctor['contactno']),
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