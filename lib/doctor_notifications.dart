import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'main.dart';

class DoctorNotifications extends StatefulWidget {
  const DoctorNotifications({Key? key}) : super(key: key);

  @override
  _DoctorNotificationsState createState() => _DoctorNotificationsState();
}

class _DoctorNotificationsState extends State<DoctorNotifications>
    with TickerProviderStateMixin {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  List notifications = [];
  bool isLoading = true;

  late AnimationController _fadeController;
  late AnimationController _listController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initializeDoctorIdAndFetchNotifications();
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
    super.dispose();
  }

  Future<void> _initializeDoctorIdAndFetchNotifications() async {
    try {
      final doctorId = await _storage.read(key: 'doctor_id');
      if (doctorId != null) {
        await fetchNotifications(doctorId);
      } else {
        _showModernError('Doctor ID not found in storage. Please log in again.');
      }
    } catch (e) {
      _showModernError('Failed to retrieve Doctor ID: $e');
    }
  }

  Future<void> fetchNotifications(String doctorId) async {
    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/doctor_notifications.php?doctorid=$doctorId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            notifications = data['notifications'];
            isLoading = false;
          });
          _listController.forward();
        } else {
          _showModernError(data['message'] ?? 'Failed to load notifications.');
        }
      } else {
        _showModernError('Server error: ${response.statusCode}');
      }
    } catch (error) {
      _showModernError('An error occurred while fetching notifications: $error');
    }

    setState(() => isLoading = false);
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/doctor_notifications.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'action': 'markAsRead', 'notificationid': notificationId}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          await _initializeDoctorIdAndFetchNotifications();
          _showSuccessMessage('Notification marked as read');
        } else {
          _showModernError(data['message']);
        }
      } else {
        _showModernError('Failed to mark notification as read.');
      }
    } catch (e) {
      _showModernError('An error occurred while marking notification as read: $e');
    }
  }

  Future<void> deleteNotification(int notificationId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/doctor_notifications.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'action': 'delete', 'notificationid': notificationId}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          await _initializeDoctorIdAndFetchNotifications();
          _showSuccessMessage('Notification deleted successfully');
        } else {
          _showModernError(data['message']);
        }
      } else {
        _showModernError('Failed to delete notification.');
      }
    } catch (e) {
      _showModernError('An error occurred while deleting notification: $e');
    }
  }

  void _showModernError(String message) {
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

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Text(
              message,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  int get unreadCount => notifications.where((n) => n['is_read'] == 0).length;

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
                  child: isLoading
                      ? _buildLoadingState()
                      : notifications.isEmpty
                      ? _buildEmptyState()
                      : _buildNotificationsList(),
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
                    'Notifications',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  if (!isLoading && notifications.isNotEmpty)
                    Text(
                      '$unreadCount unread of ${notifications.length} total',
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
            'Loading notifications...',
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
              Icons.notifications_none_rounded,
              size: 60,
              color: Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No notifications',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You\'re all caught up! New notifications\nwill appear here when they arrive.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    return SlideTransition(
      position: _slideAnimation,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          return ModernNotificationCard(
            notification: notifications[index],
            onMarkAsRead: notifications[index]['is_read'] == 0
                ? () => markAsRead(notifications[index]['id'])
                : null,
            onDelete: () => _showDeleteConfirmation(notifications[index]['id']),
            index: index,
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(int notificationId) {
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
                child: const Icon(Icons.delete_outline, color: Colors.red, size: 24),
              ),
              const SizedBox(width: 12),
              const Text('Delete Notification', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          content: const Text(
            'Are you sure you want to delete this notification? This action cannot be undone.',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                deleteNotification(notificationId);
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}

class ModernNotificationCard extends StatefulWidget {
  final Map<String, dynamic> notification;
  final VoidCallback? onMarkAsRead;
  final VoidCallback onDelete;
  final int index;

  const ModernNotificationCard({
    Key? key,
    required this.notification,
    this.onMarkAsRead,
    required this.onDelete,
    required this.index,
  }) : super(key: key);

  @override
  _ModernNotificationCardState createState() => _ModernNotificationCardState();
}

class _ModernNotificationCardState extends State<ModernNotificationCard>
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

  String _formatDate(String dateString) {
    try {
      DateTime date = DateTime.parse(dateString);
      DateTime now = DateTime.now();
      Duration difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return dateString;
    }
  }

  IconData _getNotificationIcon() {
    String message = widget.notification['message'].toLowerCase();
    if (message.contains('appointment')) {
      return Icons.event_rounded;
    } else if (message.contains('patient')) {
      return Icons.person_rounded;
    } else if (message.contains('operation')) {
      return Icons.healing_rounded;
    } else {
      return Icons.info_rounded;
    }
  }

  Color _getNotificationColor() {
    String message = widget.notification['message'].toLowerCase();
    if (message.contains('appointment')) {
      return const Color(0xFF3B82F6);
    } else if (message.contains('patient')) {
      return const Color(0xFF10B981);
    } else if (message.contains('operation')) {
      return const Color(0xFFF59E0B);
    } else {
      return const Color(0xFF8B5CF6);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isUnread = widget.notification['is_read'] == 0;
    Color notificationColor = _getNotificationColor();

    return AnimatedBuilder(
      animation: _scaleController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: isUnread
                  ? Border.all(color: notificationColor.withOpacity(0.3), width: 2)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: isUnread
                      ? notificationColor.withOpacity(0.1)
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
                          color: notificationColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getNotificationIcon(),
                          color: notificationColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.notification['message'],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                                color: const Color(0xFF1E293B),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(widget.notification['created_at']),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: notificationColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      if (widget.onMarkAsRead != null)
                        Expanded(
                          child: GestureDetector(
                            onTapDown: (_) => _scaleController.forward(),
                            onTapUp: (_) => _scaleController.reverse(),
                            onTapCancel: () => _scaleController.reverse(),
                            onTap: widget.onMarkAsRead,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_rounded,
                                    color: Colors.green,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Mark as Read',
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
                      if (widget.onMarkAsRead != null) const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTapDown: (_) => _scaleController.forward(),
                          onTapUp: (_) => _scaleController.reverse(),
                          onTapCancel: () => _scaleController.reverse(),
                          onTap: widget.onDelete,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.red,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Delete',
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
              ),
            ),
          ),
        );
      },
    );
  }
}