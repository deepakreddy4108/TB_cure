import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'main.dart';
import 'dart:convert';

class PatientProfile extends StatefulWidget {
  @override
  _PatientProfileState createState() => _PatientProfileState();
}

class _PatientProfileState extends State<PatientProfile> {
  Map<String, dynamic>? patientData;
  bool isLoading = true;
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    fetchPatientProfile();
  }

  Future<void> fetchPatientProfile() async {
    if (!isLoading) setState(() => isLoading = true);

    try {
      print("Fetching patient profile...");

      // Retrieve patient ID from secure storage
      String? patientId = await _storage.read(key: 'patient_id');
      print("Retrieved patient ID: $patientId");

      if (patientId == null || patientId.isEmpty) {
        print("Error: Patient ID is null or empty.");
        showAlertDialog(context, 'Error', 'Patient ID not found. Please log in again.');
        return;
      }

      print("Sending request to fetch patient profile with ID: $patientId");

      // Prepare JSON data
      final requestData = {
        'patientid': patientId,
      };
      print("Request Data: $requestData");

      // Fetch profile details from the server
      final response = await _dio.post(
        '$baseUrl/patientprofile.php',
        data: requestData, // Sending the request as JSON data
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      print("Response received: ${response.data}");

      // Handling the server response
      if (response.data['success'] == true) {
        print("Profile fetched successfully.");
        setState(() {
          patientData = response.data['patient'];
        });
      } else {
        print("Error: ${response.data['message'] ?? 'Unknown error'}");
        showAlertDialog(context, 'Error', response.data['message'] ?? 'Failed to fetch patient profile.');
      }
    } catch (error) {
      print("Exception occurred: $error");
      showAlertDialog(context, 'Error', 'An error occurred while fetching the patient profile.');
    } finally {
      print("Fetch process completed.");
      setState(() => isLoading = false);
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
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8ECF4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF02adec),
        title: const Text('Your Profile', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.pushNamed(context, '/EditPatientProfile');
              if (result == true) {
                await fetchPatientProfile();
                Navigator.pop(context, 'updated'); // Notify previous screen about the update
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(
        child: SpinKitFadingCircle(
          color: const Color(0xFF02adec),
          size: 50.0,
        ),
      )
          : patientData != null
          ? _buildProfileContainer()
          : const Center(child: Text('No data available')),
    );
  }

  Widget _buildProfileContainer() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
        width: MediaQuery.of(context).size.width * 0.85,
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
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildProfileImage(),
            SizedBox(height: MediaQuery.of(context).size.height * 0.03),
            _buildInfoRow('Patient ID', patientData!['patientid'].toString()),
            _buildInfoRow('Name', patientData!['Name']),
            _buildInfoRow('Age', patientData!['age'].toString()),
            _buildInfoRow('Gender', patientData!['gender']),
            _buildInfoRow('Username', patientData!['username']),
            _buildInfoRow('Contact Number', patientData!['contactno']),
            _buildInfoRow('Address', patientData!['Address']),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    final profileImage = patientData!['profile_image'];

    return Center(
      child: CircleAvatar(
        radius: 60,
        backgroundColor: Colors.blueAccent,
        child: profileImage != null && profileImage.isNotEmpty
            ? ClipOval(
          child: Image.network(
            '$baseUrl/img/patient_profile_images/$profileImage?${DateTime.now().millisecondsSinceEpoch}',
            fit: BoxFit.cover,
            width: 120,
            height: 120,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.person,
                size: 80,
                color: Colors.white,
              );
            },
          ),
        )
            : const Icon(
          Icons.person,
          size: 80,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height * 0.015),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontSize: 18),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}
