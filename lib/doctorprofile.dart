import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'editdoctorprofile.dart';
import 'main.dart'; // Import main.dart to use baseUrl

class DoctorProfile extends StatefulWidget {
  @override
  _DoctorProfileState createState() => _DoctorProfileState();
}

class _DoctorProfileState extends State<DoctorProfile> {
  Map<String, dynamic>? doctorData;
  bool isLoading = true;
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    fetchDoctorProfile();
  }

  Future<void> fetchDoctorProfile() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Retrieve doctor ID from secure storage
      String? doctorId = await _storage.read(key: 'doctor_id');
      if (doctorId == null || doctorId.isEmpty) {
        debugPrint('Doctor ID not found in secure storage');
      } else {
        debugPrint('Doctor ID: $doctorId');
      }

      // Make the HTTP POST request
      final response = await _dio.post(
        '$baseUrl/doctorprofile.php', // Use baseUrl
        data: FormData.fromMap({'doctorid': doctorId}),
        options: Options(
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        ),
      );

      // Process the response
      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          doctorData = response.data['doctor'];
          isLoading = false;
        });
      } else {
        showAlertDialog(context, 'Error', response.data['message'] ?? 'Failed to fetch doctor profile');
      }
    } catch (error) {
      showAlertDialog(context, 'Error', 'An error occurred while fetching the doctor profile.');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void showAlertDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFe8ecf4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF02adec),
        title: const Text(
          'My Profile',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              if (doctorData != null) {
                // Pass doctorId to EditDoctorProfile and wait for the result
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditDoctorProfile(doctorId: doctorData!['doctorid']),
                  ),
                );

                // If result is true, refresh the profile data and signal the update
                if (result == true) {
                  await fetchDoctorProfile(); // Refresh profile data
                  setState(() {}); // Trigger a rebuild to show updated data
                  Navigator.pop(context, true); // Send a signal that the profile was updated
                }
              } else {
                showAlertDialog(context, 'Error', 'No data to edit.');
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(
        child: SpinKitFadingCircle(
          color: Color(0xFF02adec),
          size: 50.0,
        ),
      )
          : doctorData != null
          ? SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.05),
            child: Column(
              children: [
                const SizedBox(height: 50),
                Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 5,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 30),
                      CircleAvatar(
                        radius: 82.5,
                        backgroundImage: doctorData?['profile_image'] != null &&
                            doctorData?['profile_image'].isNotEmpty
                            ? NetworkImage(
                            '$baseUrl/img/doctor_profile_images/${doctorData!['profile_image']}?${DateTime.now().millisecondsSinceEpoch}')
                            : const AssetImage('assets/placeholder_image.png')
                        as ImageProvider,
                        backgroundColor: Colors.grey[200],
                      ),
                      const SizedBox(height: 30),
                      _buildInfoRow('Doctor ID', doctorData!['doctorid'].toString()),
                      _buildInfoRow('Name', doctorData?['name'] ?? 'N/A'),
                      _buildInfoRow('Username', doctorData?['username'] ?? 'N/A'),
                      _buildInfoRow('Gender', doctorData?['gender'] ?? 'N/A'),
                      _buildInfoRow('Contact Number', doctorData?['contactno'] ?? 'N/A'),
                      _buildInfoRow('Specialization', doctorData?['specialization'] ?? 'N/A'),
                      _buildInfoRow('Experience', '${doctorData?['experience'] ?? '0'} years'),
                      _buildInfoRow('Hospital Name', doctorData?['hospital_name'] ?? 'N/A'),
                      _buildInfoRow('Hospital Location', doctorData?['hospital_location'] ?? 'N/A'),
                    ],
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      )
          : const Center(
        child: Text('No data available'),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.left,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value ?? 'N/A',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.left,
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}
