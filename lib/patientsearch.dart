import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'main.dart'; // Import main.dart to access baseUrl

class PatientSearch extends StatefulWidget {
  @override
  _PatientSearchState createState() => _PatientSearchState();
}

class _PatientSearchState extends State<PatientSearch> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String searchValue = '';
  List<dynamic> results = [];
  List<dynamic> filteredResults = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    fetchDoctors(); // Initial fetch of all doctors
  }

  Future<void> fetchDoctors() async {
    setState(() {
      loading = true;
    });

    try {
      final url = '$baseUrl/patientsearch.php';
      print('Fetching doctors from: $url'); // Debugging URL

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}'); // Debugging response status

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('Response body: ${response.body}'); // Debugging response body

        if (jsonData['success']) {
          setState(() {
            results = jsonData['results'];
            filteredResults = results;
            print('Fetched results: $results'); // Debugging fetched results
          });
        } else {
          _showAlert('No results', jsonData['message']);
          print('No results: ${jsonData['message']}'); // Debugging no results
        }
      } else {
        _showAlert('Error', 'Server error: ${response.statusCode}');
        print('Server error: ${response.statusCode}'); // Debugging server error
      }
    } catch (error) {
      _showAlert('Error', 'An error occurred while fetching doctors');
      print('Error occurred while fetching doctors: $error'); // Debugging exception error
    } finally {
      setState(() {
        loading = false;
      });
      print('Loading complete'); // Debugging loading completion
    }
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void _filterResults(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredResults = results;
      });
    } else {
      setState(() {
        filteredResults = results.where((doctor) {
          return doctor['name'].toLowerCase().contains(query.toLowerCase());
        }).toList();
      });
    }
  }

  /// Constructs the full URL for the profile image.
  String getFullProfileImagePath(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return ''; // Return empty string for invalid paths
    }

    // Ensure the correct path
    return '$baseUrl/img/doctor_profile_images/$imagePath';
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double padding = screenWidth * 0.05; // 5% padding from the screen width

    return Scaffold(
      backgroundColor: Color(0xFFE8ECF4),
      appBar: AppBar(
        title: const Text(
          'Doctors List',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF02adec),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(padding), // Responsive padding
        child: Column(
          children: [
            _buildSearchBox(screenWidth), // Pass screenWidth to adjust the search box size
            loading
                ? Center(
              child: CircularProgressIndicator(color: const Color(0xFF02adec)),
            )
                : Expanded(child: _buildResultsList(screenWidth, screenHeight)), // Pass screen width & height to results list
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBox(double screenWidth) {
    return Container(
      width: screenWidth * 0.9, // Adjust width based on screen size
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search by Name',
          prefixIcon: Icon(Icons.search, color: Color(0xFF02adec)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
        onChanged: (value) {
          searchValue = value;
          _filterResults(searchValue);
        },
      ),
    );
  }

  Widget _buildResultsList(double screenWidth, double screenHeight) {
    return ListView.builder(
      itemCount: filteredResults.length,
      itemBuilder: (context, index) {
        final item = filteredResults[index];
        final String? rawImagePath = item['profile_image'];
        final String profileImage = getFullProfileImagePath(rawImagePath);

        return Container(
          margin: EdgeInsets.symmetric(vertical: screenHeight * 0.02), // 2% vertical margin
          padding: EdgeInsets.all(screenWidth * 0.04), // 4% padding
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              profileImage.isNotEmpty
                  ? Container(
                width: screenWidth * 0.25, // 25% width
                height: screenWidth * 0.25, // 25% height
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    profileImage,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      print('Error loading image: $error'); // Debugging image load error
                      return Container(
                        color: Colors.grey[300],
                        child: Center(
                          child: Icon(Icons.person, color: Colors.white, size: screenWidth * 0.15),
                        ),
                      );
                    },
                  ),
                ),
              )
                  : Container(
                width: screenWidth * 0.25,
                height: screenWidth * 0.25,
                color: Colors.grey[300],
                child: Center(
                  child: Icon(Icons.person, color: Colors.white, size: screenWidth * 0.15),
                ),
              ),
              SizedBox(width: screenWidth * 0.05), // 5% width for spacing
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Doctor ID: ${item['doctorid']}',
                      style: TextStyle(fontSize: screenWidth * 0.05, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Doctor Name: ',
                          style: TextStyle(fontSize: screenWidth * 0.045, fontWeight: FontWeight.bold),
                        ),
                        Flexible(
                          child: _highlightText(item['name'], searchValue),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hospital Name: ${item['hospital_name']}',
                      style: TextStyle(fontSize: screenWidth * 0.04),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hospital Location: ${item['hospital_location']}',
                      style: TextStyle(fontSize: screenWidth * 0.04),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Mobile Number: ${item['contactno']}',
                      style: TextStyle(fontSize: screenWidth * 0.04),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Experience: ${item['experience']} years',
                      style: TextStyle(fontSize: screenWidth * 0.04),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _highlightText(String text, String searchQuery) {
    if (searchQuery.isEmpty) {
      return Text(
        text,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      );
    }

    final spans = <TextSpan>[];
    final lowerText = text.toLowerCase();
    final lowerQuery = searchQuery.toLowerCase();

    int start = 0;
    int index;

    while ((index = lowerText.indexOf(lowerQuery, start)) != -1) {
      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: TextStyle(color: Colors.black),
        ));
      }
      spans.add(TextSpan(
        text: text.substring(index, index + lowerQuery.length),
        style: TextStyle(color: Color(0xFF02adec), fontWeight: FontWeight.bold),
      ));
      start = index + lowerQuery.length;
    }

    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: TextStyle(color: Colors.black),
      ));
    }

    return Text.rich(
      TextSpan(children: spans),
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }
}
