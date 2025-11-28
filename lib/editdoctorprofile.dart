import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'main.dart'; // Assumes main.dart contains the baseUrl

class EditDoctorProfile extends StatefulWidget {
  final int doctorId;

  const EditDoctorProfile({Key? key, required this.doctorId}) : super(key: key);

  @override
  _EditDoctorProfileState createState() => _EditDoctorProfileState();
}

class _EditDoctorProfileState extends State<EditDoctorProfile> {
  final _formKey = GlobalKey<FormState>();
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _contactController;
  late TextEditingController _specializationController;
  late TextEditingController _experienceController;
  late TextEditingController _hospitalNameController;
  late TextEditingController _hospitalLocationController;

  bool isLoading = true;
  XFile? _imageFile;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadProfileData();
  }

  void _initializeControllers() {
    _nameController = TextEditingController();
    _usernameController = TextEditingController(); // Renamed email to username
    _contactController = TextEditingController();
    _specializationController = TextEditingController();
    _experienceController = TextEditingController();
    _hospitalNameController = TextEditingController();
    _hospitalLocationController = TextEditingController();
  }

  Future<void> _loadProfileData() async {
    print("Loading profile data for doctor ID: ${widget.doctorId}");
    try {
      final response = await _dio.post(
        '$baseUrl/doctorprofile.php',
        data: FormData.fromMap({'doctorid': widget.doctorId.toString()}),
      );
      print("Response received: ${response.statusCode}");
      print("Response body: ${response.data}");

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['doctor'];
        setState(() {
          _nameController.text = data['name'] ?? '';
          _usernameController.text = data['username'] ?? '';
          _contactController.text = data['contactno'] ?? '';
          _specializationController.text = data['specialization'] ?? '';
          _experienceController.text = data['experience'].toString();
          _hospitalNameController.text = data['hospital_name'] ?? '';
          _hospitalLocationController.text = data['hospital_location'] ?? '';
          _profileImageUrl = data['profile_image'] != null && data['profile_image'].isNotEmpty
              ? '$baseUrl/img/doctor_profile_images/${data['profile_image']}'
              : null;
          isLoading = false;
        });
      } else {
        print("Failed to load profile details: ${response.data}");
        _showError('Failed to load profile details.');
      }
    } catch (error) {
      print("Error loading profile data: $error");
      _showError('An error occurred while loading profile data.');
    }
  }

  Future<void> _updateProfile() async {
    print("Attempting to update profile for doctor ID: ${widget.doctorId}");
    if (_formKey.currentState?.validate() ?? false) {
      try {
        int experience = int.tryParse(_experienceController.text) ?? 0;

        final formData = FormData.fromMap({
          'doctorid': widget.doctorId.toString(),
          'name': _nameController.text,
          'username': _usernameController.text,
          'contactno': _contactController.text,
          'specialization': _specializationController.text,
          'experience': experience,
          'hospital_name': _hospitalNameController.text,
          'hospital_location': _hospitalLocationController.text,
          if (_imageFile != null) 'profile_image': await MultipartFile.fromFile(_imageFile!.path),
        });

        print("FormData prepared: ${formData.fields}");
        if (_imageFile != null) {
          print("Image selected: ${_imageFile!.path}");
        }

        final response = await _dio.post(
          '$baseUrl/editdoctorprofile.php',
          data: formData,
        );

        print("Update response: ${response.statusCode}");
        print("Response body: ${response.data}");

        if (response.statusCode == 200 && response.data['success'] == true) {
          print("Profile updated successfully.");
          Navigator.pop(context, true);
        } else {
          print("Profile update failed: ${response.data}");
          _showError(response.data['message'] ?? 'Update failed.');
        }
      } catch (error) {
        print("Error during profile update: $error");
        _showError('An error occurred while updating the profile.');
      }
    } else {
      print("Form validation failed.");
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
      print("Image selected: ${_imageFile!.path}");
    } else {
      print("No image selected.");
      _showError('No image selected.');
    }
  }

  void _showError(String message) {
    print("Error: $message");
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFE8ECF4),
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: const Color(0xFF02adec),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Center(
                  child: CircleAvatar(
                    radius: screenWidth * 0.18,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _imageFile != null
                        ? FileImage(File(_imageFile!.path))
                        : (_profileImageUrl != null
                        ? NetworkImage(_profileImageUrl!) as ImageProvider
                        : null),
                    child: _imageFile == null && _profileImageUrl == null
                        ? const Icon(
                      Icons.camera_alt,
                      size: 50,
                      color: Colors.white,
                    )
                        : null,
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
              _buildTextField(_nameController, 'Name'),
              _buildTextField(_usernameController, 'Username'),
              _buildTextField(_contactController, 'Contact Number'),
              _buildTextField(_specializationController, 'Specialization'),
              _buildTextField(_experienceController, 'Experience (years)'),
              _buildTextField(_hospitalNameController, 'Hospital Name'),
              _buildTextField(_hospitalLocationController, 'Hospital Location'),
              SizedBox(height: screenHeight * 0.03),
              ElevatedButton(
                onPressed: _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF02adec),
                  padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                ),
                child: const Text(
                  'Save Changes',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          fillColor: Colors.white,
          filled: true,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '$label is required';
          }
          return null;
        },
      ),
    );
  }
}
