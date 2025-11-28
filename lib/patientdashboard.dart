import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'main.dart';

class PatientDashboard extends StatefulWidget {
  @override
  _PatientDashboardState createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard>
    with TickerProviderStateMixin {
  final List<String> ads = [
    'assets/images/t1.jpeg',
    'assets/images/t2.jpg',

  ];

  int currentIndex = 0;
  String? patientId;
  String? patientName;
  String? profileImageUrl;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _initAnimations();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    print('Dashboard initialized. Initiating profile image and name fetch...');
    _autoScrollAds();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
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

  void _autoScrollAds() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _pageController.hasClients) {
        int nextPage = (currentIndex + 1) % ads.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        _autoScrollAds();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  final _storage = FlutterSecureStorage();

  Future<String?> _getPatientId() async {
    try {
      final id = await _storage.read(key: 'patient_id');
      print('Patient ID fetched from storage: $id');
      return id;
    } catch (e) {
      print('Error reading Patient ID from storage: $e');
      return null;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (patientId == null) {
      _getPatientId().then((id) {
        if (id == null) {
          print("Error: Patient ID not found in storage.");
          return;
        }
        setState(() {
          patientId = id;
        });
        if (profileImageUrl == null || patientName == null) {
          print('Profile data is missing. Fetching profile...');
          loadProfileImage();
        }
      });
    }
  }

  Future<void> loadProfileImage() async {
    if (patientId == null) {
      print('Error: Cannot fetch profile. Patient ID is null.');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/patientdashboard.php?patientid=$patientId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final imageName = data['profile_image'];
          final fetchedName = data['name'];

          setState(() {
            patientName = fetchedName?.split(' ')[0] ?? 'Patient';
            profileImageUrl = imageName != null
                ? '$baseUrl/img/patient_profile_images/$imageName?ts=${DateTime.now().millisecondsSinceEpoch}'
                : null;
          });
          print('Profile loaded successfully.');
        } else {
          print('Error: ${data['message']}');
        }
      } else {
        print('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching profile: $e');
    }
  }

  void openProfile() {
    Navigator.pushNamed(
      context,
      '/PatientProfile',
      arguments: {'patientId': patientId},
    ).then((result) {
      if (result == 'updated') {
        print('Profile updated. Fetching updated profile image and name...');
        loadProfileImage();
      }
    });
  }

  void handleLogout() {
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
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.logout, color: Colors.red, size: 24),
              ),
              const SizedBox(width: 12),
              const Text('Confirm Logout', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          content: const Text('Are you sure you want to logout?',
              style: TextStyle(color: Color(0xFF64748B))),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacementNamed(context, '/patientLogin');
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        handleLogout();
        return false;
      },
      child: Scaffold(
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
                  Expanded(
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            _buildStatsCards(),
                            const SizedBox(height: 24),
                            _buildModernAds(),
                            const SizedBox(height: 24),
                            _buildQuickActions(),
                            const SizedBox(height: 24),
                            _buildSecondaryActions(),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: _buildModernBottomNav(),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: openProfile,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white,
                    backgroundImage: profileImageUrl != null ? NetworkImage(profileImageUrl!) : null,
                    child: profileImageUrl == null
                        ? const Icon(Icons.person, size: 40, color: Color(0xFF10B981))
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome back,',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      patientName ?? 'Patient',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Text(
                      'Take care of your health',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/PatientNotifications'),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Next\nAppointment',
            'Today',
            Icons.calendar_today,
            const Color(0xFF3B82F6),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Health\nScore',
            '85%',
            Icons.favorite,
            const Color(0xFFEF4444),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Total\nVisits',
            '12',
            Icons.local_hospital,
            const Color(0xFF10B981),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernAds() {
    return Container(
      height: 180,
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
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  currentIndex = index;
                });
              },
              itemCount: ads.length,
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF10B981).withOpacity(0.8),
                        const Color(0xFF059669).withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Image.asset(
                    ads[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                    const Center(child: Icon(Icons.image, size: 60, color: Colors.white)),
                  ),
                );
              },
            ),
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: ads.map((ad) {
                  int index = ads.indexOf(ad);
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: index == currentIndex ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: index == currentIndex ? Colors.white : Colors.white54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Book Appointment',
                Icons.calendar_month_rounded,
                const Color(0xFF3B82F6),
                    () => Navigator.pushNamed(context, '/BookAppointment'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                'My Appointments',
                Icons.event_rounded,
                const Color(0xFF10B981),
                    () => Navigator.pushNamed(context, '/Appointments', arguments: patientId),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                'Operations',
                Icons.healing_rounded,
                const Color(0xFFF59E0B),
                    () => Navigator.pushNamed(context, '/PatientOperationDetails', arguments: patientId),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSecondaryActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Health Resources',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Connect Doctor',
                Icons.person_add_rounded,
                const Color(0xFF8B5CF6),
                    () => Navigator.pushNamed(context, '/ConnectWithDoctor'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                'Health Tips',
                Icons.lightbulb_rounded,
                const Color(0xFFEF4444),
                    () => Navigator.pushNamed(context, '/Tips', arguments: patientId),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernBottomNav() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF10B981),
        unselectedItemColor: const Color(0xFF64748B),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_rounded),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout_rounded, color: Colors.red),
            label: 'Logout',
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
            // Already on home
              break;
            case 1:
              Navigator.pushNamed(context, '/PatientSearch', arguments: patientId);
              break;
            case 2:
              handleLogout();
              break;
          }
        },
      ),
    );
  }
}