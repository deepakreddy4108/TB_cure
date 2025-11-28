import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'main.dart';

class PatientSignup extends StatefulWidget {
  final VoidCallback navigateToLogin;

  const PatientSignup({Key? key, required this.navigateToLogin}) : super(key: key);

  @override
  _PatientSignupState createState() => _PatientSignupState();
}

class _PatientSignupState extends State<PatientSignup> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController contactNoController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController question1Controller = TextEditingController();
  final TextEditingController answer1Controller = TextEditingController();
  final TextEditingController question2Controller = TextEditingController();
  final TextEditingController answer2Controller = TextEditingController();
  final TextEditingController question3Controller = TextEditingController();
  final TextEditingController answer3Controller = TextEditingController();
  String gender = 'male';

  File? imageFile;

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> handleSignup() async {
    final contactNumber = "+91 ${contactNoController.text.trim()}";

    if (!RegExp(r'^\+91 [6-9]\d{9}$').hasMatch(contactNumber)) {
      _showAlert('Error', 'Invalid contact number. Please enter a valid Indian number.', false);
      return;
    }

    final formData = {
      'name': nameController.text,
      'username': usernameController.text,
      'password': passwordController.text,
      'contactNo': contactNumber,
      'age': ageController.text,
      'gender': gender,
      'address': addressController.text,
      'question_1': question1Controller.text,
      'ans_q1': answer1Controller.text,
      'question_2': question2Controller.text,
      'ans_q2': answer2Controller.text,
      'question_3': question3Controller.text,
      'ans_q3': answer3Controller.text,
    };

    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/patientsignup.php'));
    request.fields.addAll(formData);

    if (imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath('profile_image', imageFile!.path));
    }

    final response = await request.send();
    final responseString = await response.stream.bytesToString();
    final responseData = json.decode(responseString);

    if (responseData['message'] == 'Patient registered successfully with profile image and security questions') {
      _showAlert('Success', 'Patient account is created', true);
    } else {
      _showAlert('Error', responseData['message'], false);
    }
  }

  void _showAlert(String title, String message, bool success) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                if (success) {
                  Navigator.pop(context); // Navigate back to the previous screen (login)
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use MediaQuery to get the screen dimensions
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double padding = screenWidth * 0.05; // 5% padding based on screen width
    final double avatarRadius = screenWidth * 0.2; // 20% screen width for avatar size
    final double textFieldPadding = screenWidth * 0.04; // Adjust padding for text fields
    final double fontSize = screenWidth * 0.045; // Adjust font size according to screen width

    return Scaffold(
      backgroundColor: const Color(0xFFE8ECF4),
      appBar: AppBar(
        title: const Text(
          'Patient Signup',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF02ADEC),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        padding: EdgeInsets.all(padding),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 50),
              GestureDetector(
                onTap: pickImage,
                child: CircleAvatar(
                  radius: avatarRadius,
                  backgroundImage: imageFile != null ? FileImage(imageFile!) : null,
                  backgroundColor: Colors.grey,
                  child: imageFile == null
                      ? const Center(
                    child: Icon(
                      Icons.camera_alt,
                      size: 40,
                      color: Colors.white,
                    ),
                  )
                      : null,
                ),
              ),
              const SizedBox(height: 20),
              _buildInputField('Name', nameController, false, fontSize: fontSize, padding: textFieldPadding),
              _buildInputField('Username', usernameController, false, fontSize: fontSize, padding: textFieldPadding),
              _buildInputField('Password', passwordController, true, fontSize: fontSize, padding: textFieldPadding),
              _buildContactNumberField(fontSize: fontSize, padding: textFieldPadding),
              _buildInputField('Age', ageController, false, fontSize: fontSize, padding: textFieldPadding, keyboardType: TextInputType.number),
              _buildInputField('Address', addressController, false, fontSize: fontSize, padding: textFieldPadding),
              _buildGenderSelection(fontSize: fontSize),
              const SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(padding),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'In case you forget your password, answer these questions to reset it: So frame the questions wisely.',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),
              _buildInputField('Security Question 1', question1Controller, false, fontSize: fontSize, padding: textFieldPadding),
              _buildInputField('Answer 1', answer1Controller, false, fontSize: fontSize, padding: textFieldPadding),
              _buildInputField('Security Question 2', question2Controller, false, fontSize: fontSize, padding: textFieldPadding),
              _buildInputField('Answer 2', answer2Controller, false, fontSize: fontSize, padding: textFieldPadding),
              _buildInputField('Security Question 3', question3Controller, false, fontSize: fontSize, padding: textFieldPadding),
              _buildInputField('Answer 3', answer3Controller, false, fontSize: fontSize, padding: textFieldPadding),
              const SizedBox(height: 20),
              _buildSignupButton(padding),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, bool obscureText,
      {TextInputType keyboardType = TextInputType.text, required double fontSize, required double padding}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: 8),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: fontSize),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[700], fontSize: fontSize),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: padding),
        ),
      ),
    );
  }

  Widget _buildContactNumberField({required double fontSize, required double padding}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 70,
            padding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey),
            ),
            child: const Text(
              '+91',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: contactNoController,
              keyboardType: TextInputType.phone,
              style: TextStyle(fontSize: fontSize),
              decoration: InputDecoration(
                labelText: 'Contact Number',
                labelStyle: TextStyle(color: Colors.grey[700], fontSize: fontSize),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: padding),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderSelection({required double fontSize}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 20,
        children: [
          ChoiceChip(
            label: const Text('Male'),
            selected: gender == 'male',
            onSelected: (selected) {
              setState(() {
                gender = selected ? 'male' : gender;
              });
            },
          ),
          ChoiceChip(
            label: const Text('Female'),
            selected: gender == 'female',
            onSelected: (selected) {
              setState(() {
                gender = selected ? 'female' : gender;
              });
            },
          ),
          ChoiceChip(
            label: const Text('Other'),
            selected: gender == 'other',
            onSelected: (selected) {
              setState(() {
                gender = selected ? 'other' : gender;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSignupButton(double padding) {
    return ElevatedButton(
      onPressed: handleSignup,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF02ADEC),
        padding: EdgeInsets.symmetric(horizontal: padding * 1.5, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text(
        'Signup',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }
}
