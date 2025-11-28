import 'package:flutter/material.dart';
import 'getstarted.dart';

class RoleSelection extends StatefulWidget {
  const RoleSelection({Key? key}) : super(key: key);

  @override
  _RoleSelectionState createState() => _RoleSelectionState();
}

class _RoleSelectionState extends State<RoleSelection>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

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

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => GetStarted()),
              (Route<dynamic> route) => false,
        );
        return false;
      },
      child: Scaffold(
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
            child: AnimatedBuilder(
              animation: _fadeController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.06,
                        vertical: screenHeight * 0.02,
                      ),
                      child: Column(
                        children: [
                          // Back button
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(builder: (context) => GetStarted()),
                                        (Route<dynamic> route) => false,
                                  );
                                },
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
                            ],
                          ),

                          SizedBox(height: screenHeight * 0.06),

                          // Header section
                          Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.4),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.people_alt_outlined,
                                  size: 40,
                                  color: Color(0xFF475569),
                                ),
                              ),

                              SizedBox(height: screenHeight * 0.03),

                              const Text(
                                'Choose Your Role',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E293B),
                                  letterSpacing: -0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),

                              SizedBox(height: screenHeight * 0.015),

                              Text(
                                'Select how you\'d like to use our platform',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: const Color(0xFF64748B),
                                  fontWeight: FontWeight.w400,
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),

                          SizedBox(height: screenHeight * 0.08),

                          // Role options
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ModernRoleOption(
                                  icon: Icons.medical_services_rounded,
                                  roleName: 'Doctor',
                                  description: 'Manage patients and appointments',
                                  color: const Color(0xFF3B82F6),
                                  onTap: () {
                                    Navigator.pushNamed(context, '/doctorLogin');
                                  },
                                  screenWidth: screenWidth,
                                  screenHeight: screenHeight,
                                ),

                                SizedBox(height: screenHeight * 0.03),

                                ModernRoleOption(
                                  icon: Icons.person_rounded,
                                  roleName: 'Patient',
                                  description: 'Book appointments and track health',
                                  color: const Color(0xFF10B981),
                                  onTap: () {
                                    Navigator.pushNamed(context, '/patientLogin');
                                  },
                                  screenWidth: screenWidth,
                                  screenHeight: screenHeight,
                                ),
                              ],
                            ),
                          ),

                          // Bottom info
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: const Color(0xFF64748B),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'You can switch roles anytime from settings',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: const Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: screenHeight * 0.02),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class ModernRoleOption extends StatefulWidget {
  final IconData icon;
  final String roleName;
  final String description;
  final Color color;
  final VoidCallback onTap;
  final double screenWidth;
  final double screenHeight;

  const ModernRoleOption({
    required this.icon,
    required this.roleName,
    required this.description,
    required this.color,
    required this.onTap,
    required this.screenWidth,
    required this.screenHeight,
    Key? key,
  }) : super(key: key);

  @override
  _ModernRoleOptionState createState() => _ModernRoleOptionState();
}

class _ModernRoleOptionState extends State<ModernRoleOption>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _scaleController.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _scaleController.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _scaleController.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isPressed
                      ? widget.color.withOpacity(0.5)
                      : Colors.transparent,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Icon container
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.color,
                      size: 30,
                    ),
                  ),

                  const SizedBox(width: 20),

                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.roleName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Arrow
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: widget.color,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}