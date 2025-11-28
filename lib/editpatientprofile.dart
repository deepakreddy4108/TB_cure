import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'main.dart';

class EditPatientProfile extends StatefulWidget {
  const EditPatientProfile({Key? key}) : super(key: key);

  @override
  _EditPatientProfileState createState() => _EditPatientProfileState();
}

class _EditPatientProfileState extends State<EditPatientProfile> {
  final _formKey = GlobalKey<FormState>();
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _usernameController;
  late TextEditingController _contactController;
  late TextEditingController _addressController;
  late TextEditingController _genderController;

  bool isLoading = true;
  XFile? _imageFile;
  String? _profileImageUrl;
  String? _patientId;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadPatientIdAndProfile();
  }

  void _initializeControllers() {
    _nameController = TextEditingController();
    _ageController = TextEditingController();
    _usernameController = TextEditingController();
    _contactController = TextEditingController();
    _addressController = TextEditingController();
    _genderController = TextEditingController();
  }

  Future<void> _loadPatientIdAndProfile() async {
    try {
      _patientId = await _storage.read(key: 'patient_id');

      if (_patientId == null || _patientId!.isEmpty) {
        _showError('Patient ID not found.');
        return;
      }

      final response = await _dio.post(
        '$baseUrl/patientprofile.php',
        data: {'patientid': _patientId, 'fetch_profile': 'true'},
      );

      final responseData = response.data;

      if (response.statusCode == 200 && responseData['success'] == true) {
        final data = responseData['patient'];

        setState(() {
          _nameController.text = data['Name'] ?? '';
          _ageController.text = data['age']?.toString() ?? '';
          _usernameController.text = data['username'] ?? '';
          _contactController.text = data['contactno'] ?? '';
          _addressController.text = data['Address'] ?? '';
          _genderController.text = data['gender'] ?? '';
          _profileImageUrl = data['profile_image'] != null && data['profile_image'].isNotEmpty
              ? '$baseUrl/img/patient_profile_images/${data['profile_image']}?timestamp=${DateTime.now().millisecondsSinceEpoch}'
              : null;
          isLoading = false;
        });
      } else {
        _showError(responseData['message'] ?? 'Failed to load profile details.');
      }
    } catch (error) {
      _showError('An error occurred while loading profile data.');
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        final formData = FormData.fromMap({
          'patientid': _patientId,
          'name': _nameController.text,
          'age': _ageController.text,
          'username': _usernameController.text,
          'contactno': _contactController.text,
          'address': _addressController.text,
          'gender': _genderController.text,
          if (_imageFile != null) 'profile_image': await MultipartFile.fromFile(_imageFile!.path),
        });

        final response = await _dio.post(
          '$baseUrl/editpatientprofile.php',
          data: formData,
        );

        final responseData = response.data;

        if (response.statusCode == 200 && responseData['success'] == true) {
          Navigator.pop(context, true);
        } else {
          _showError(responseData['message'] ?? 'Update failed.');
        }
      } catch (error) {
        _showError('An error occurred while updating the profile.');
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    // MediaQuery for responsive design
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double screenPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFE8ECF4),
      appBar: AppBar(
        title: const Text('Edit Patient Profile'),
        backgroundColor: const Color(0xFF02adec),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.04), // Responsive padding
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: screenWidth * 0.18, // Responsive avatar size
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _imageFile != null
                        ? FileImage(File(_imageFile!.path))
                        : (_profileImageUrl != null
                        ? NetworkImage(_profileImageUrl!) as ImageProvider
                        : const AssetImage('assets/placeholder.png')),
                  ),
                ),
                SizedBox(height: screenHeight * 0.02), // Responsive spacing
                _buildTextField(_nameController, 'Name'),
                _buildTextField(_ageController, 'Age', keyboardType: TextInputType.number),
                _buildTextField(_usernameController, 'Username'),
                _buildTextField(_contactController, 'Contact Number', keyboardType: TextInputType.phone),
                _buildTextField(_addressController, 'Address'),
                _buildTextField(_genderController, 'Gender'),
                SizedBox(height: screenHeight * 0.02), // Responsive spacing
                // Save Changes Button
                ElevatedButton(
                  onPressed: _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF02adec),
                    padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02, horizontal: screenWidth * 0.2), // Responsive padding
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30), // Curved border
                    ),
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white), // White text
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF02adec), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF02adec), width: 2),
          ),
        ),
        validator: (value) => value?.isEmpty ?? true ? '$label is required' : null,
      ),
    );
  }
}
