import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'main.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Profile icon package

class DoctorSearch extends StatefulWidget {
  @override
  _DoctorSearchState createState() => _DoctorSearchState();
}

class _DoctorSearchState extends State<DoctorSearch> {
  final _searchController = TextEditingController();
  final _storage = const FlutterSecureStorage();
  List<dynamic> _patients = [];
  bool _isLoading = false;

  Future<void> _searchPatients(String query) async {
    setState(() {
      _isLoading = true;
    });

    String? doctorId = await _storage.read(key: 'doctor_id');
    print('Doctor ID: $doctorId'); // Debugging statement

    try {
      var response = await http.post(
        Uri.parse('$baseUrl/doctorsearch.php'), // Use baseUrl here
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'doctorId': doctorId,
          'query': query.isEmpty ? null : query,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        setState(() {
          _patients = data['patients'] ?? [];
        });
      } else {
        throw Exception('Failed to load patients');
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _searchPatients(''); // Load all patients initially
  }

  @override
  Widget build(BuildContext context) {
    // Get screen width and height for responsiveness
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white, // Ensure the background is white
      appBar: AppBar(
        title: Text('Search Patients', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF02adec),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: screenHeight * 0.02),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: _searchPatients,
              decoration: InputDecoration(
                hintText: 'Search by ID or Name',
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Color(0xFF02adec)),
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            _isLoading
                ? Center(child: CircularProgressIndicator(color: Color(0xFF02adec)))
                : Expanded(
              child: ListView.builder(
                itemCount: _patients.length,
                itemBuilder: (context, index) {
                  var patient = _patients[index];
                  return PatientCard(
                    name: patient['patient_name'],
                    gender: patient['patient_gender'],
                    mobile: patient['patient_mobile_number'],
                    address: patient['patient_address'],
                    appointmentDate: patient['appointment_date'],
                    profileImage: patient['profile_image'],
                    query: _searchController.text,
                    screenHeight: screenHeight,
                    screenWidth: screenWidth,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PatientCard extends StatelessWidget {
  final String name;
  final String gender;
  final String mobile;
  final String address;
  final String appointmentDate;
  final String profileImage;
  final String query;
  final double screenWidth;
  final double screenHeight;

  const PatientCard({
    required this.name,
    required this.gender,
    required this.mobile,
    required this.address,
    required this.appointmentDate,
    required this.profileImage,
    required this.query,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  Widget build(BuildContext context) {
    // Full URL for profile images
    final String profileImageUrl = profileImage == '0'
        ? ''
        : '$baseUrl/img/patient_profile_images/$profileImage';

    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile image section
          Container(
            width: screenWidth * 0.18, // Use responsive width
            height: screenWidth * 0.18, // Use responsive height
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10), // Square with curved edges
              color: Color(0xFF02adec).withOpacity(0.2), // Matching the app theme
              image: profileImage == '0'
                  ? null
                  : DecorationImage(
                image: NetworkImage(profileImageUrl),
                fit: BoxFit.cover,
              ),
            ),
            child: profileImage == '0'
                ? Center(
              child: FaIcon(
                FontAwesomeIcons.user,
                size: screenWidth * 0.1, // Use responsive size
                color: Color(0xFF02adec),
              ),
            )
                : null,
          ),
          SizedBox(width: screenWidth * 0.05), // Add responsive spacing
          // Patient details section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center, // Center align details vertically
              children: [
                _highlightName(name),
                SizedBox(height: screenHeight * 0.01), // Use responsive spacing
                _buildDetailRow('Gender:', gender),
                _buildDetailRow('Mobile:', mobile),
                _buildDetailRow('Address:', address),
                _buildDetailRow('Appointment Date:', appointmentDate),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _highlightName(String name) {
    if (query.isEmpty) {
      return Text(
        name,
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), // Increased font size by 2
      );
    }

    List<InlineSpan> spans = [];
    String lowerName = name.toLowerCase();
    String lowerQuery = query.toLowerCase();

    int start = 0;
    int indexOfHighlight;

    while ((indexOfHighlight = lowerName.indexOf(lowerQuery, start)) != -1) {
      if (indexOfHighlight > start) {
        spans.add(TextSpan(
          text: name.substring(start, indexOfHighlight),
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
        ));
      }

      spans.add(TextSpan(
        text: name.substring(indexOfHighlight, indexOfHighlight + query.length),
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF02adec)),
      ));

      start = indexOfHighlight + query.length;
    }

    if (start < name.length) {
      spans.add(TextSpan(
        text: name.substring(start),
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120, // Fixed width for consistent alignment
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17), // Increased font size
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[700], fontSize: 17), // Increased font size
            ),
          ),
        ],
      ),
    );
  }
}
