import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'deep_learning_prediction.dart';
import 'main.dart';

class DeepLearningUpload extends StatefulWidget {
  final Map<String, dynamic> appointment;

  const DeepLearningUpload({Key? key, required this.appointment}) : super(key: key);

  @override
  _DeepLearningUploadState createState() => _DeepLearningUploadState();
}

class _DeepLearningUploadState extends State<DeepLearningUpload> {
  XFile? selectedImage;
  String? doctorId;
  String? appointmentId; // To hold the appointment ID from secure storage
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    fetchStoredData();
  }

  Future<void> fetchStoredData() async {
    try {
      // Fetch doctor ID and appointment ID from secure storage
      final id = await _storage.read(key: 'doctor_id');
      final appId = await _storage.read(key: 'appointment_id');

      if (id == null || appId == null || appId.isEmpty) {
        print('Doctor ID or Appointment ID is null or empty.');
        showErrorDialog('Unable to fetch Doctor ID or Appointment ID. Please check your session.');
        return;
      }

      setState(() {
        doctorId = id;
        appointmentId = appId; // Assign the appointment ID
      });

      // Debugging outputs
      print('Fetched doctor ID: $doctorId');
      print('Fetched appointment ID: $appointmentId');
    } catch (e) {
      print('Error fetching data from secure storage: $e');
      showErrorDialog('Error fetching Doctor ID or Appointment ID. Please try again.');
    }
  }

  Future<void> handleNext() async {
    // Debugging outputs
    print('Selected image: ${selectedImage?.path}');
    print('Doctor ID: $doctorId');
    print('Appointment ID: $appointmentId');

    if (selectedImage != null && doctorId != null && appointmentId != null) {
      try {
        final imagePath = selectedImage!.path;

        // Debugging output before sending data
        print('Preparing to send data to the server.');

        // Pass appointment ID to the PHP backend along with the image and doctor ID
        final response = await saveImageAddressToDB(doctorId!, appointmentId!, imagePath);

        // Debugging output after getting a response
        print('Response from server: $response');

        if (response['success']) {
          String predictionClass = response['prediction'] ?? 'Class not available';
          String predictionValue = response['regression_value'].toString() ?? 'Prediction value not available';

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => DeepLearningPrediction(
                appointment: widget.appointment,
                predictionImage: imagePath,
                predictionClass: predictionClass,
                predictionValue: predictionValue,
              ),
            ),
          );
        }
        else {
          showErrorDialog(response['message'] ?? 'Failed to save image and get prediction.');
        }
      } catch (error) {
        print('Error in handleNext: $error');
        showErrorDialog('An error occurred while processing the image. Please try again.');
      }
    } else if (selectedImage == null) {
      showErrorDialog('Please select an image to proceed with the prediction.');
    } else {
      showErrorDialog('Unable to proceed. Ensure your doctor ID and appointment ID are available.');
    }
  }

  Future<void> handleImageSelect() async {
    final ImagePicker picker = ImagePicker();
    final XFile? result = await picker.pickImage(source: ImageSource.gallery);

    if (result != null) {
      setState(() {
        selectedImage = result;
      });

      // Debugging output
      print('Image selected: ${result.path}');
    } else {
      showErrorDialog('No image selected');
    }
  }

  Future<Map<String, dynamic>> saveImageAddressToDB(String doctorId, String appointmentId, String imagePath) async {
    try {
      // Debugging output
      print('Sending data to backend: doctorId=$doctorId, appointmentId=$appointmentId');

      // Prepare the multipart POST request
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/deeplearningimages.php'));
      request.fields['doctorid'] = doctorId;
      request.fields['appointmentid'] = appointmentId;

      // Check if file exists
      if (File(imagePath).existsSync()) {
        request.files.add(await http.MultipartFile.fromPath('image', imagePath));
      } else {
        throw Exception('Image file does not exist at path: $imagePath');
      }

      final response = await request.send();
      final responseData = await http.Response.fromStream(response);

      // Debugging output
      print('Server response status: ${responseData.statusCode}');
      print('Server response body: ${responseData.body}');

      if (responseData.statusCode != 200) {
        throw Exception('Failed to save image and run deep learning prediction');
      }

      return json.decode(responseData.body);
    } catch (e) {
      print('Error in saveImageAddressToDB: $e');
      rethrow;
    }
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 10),
            Text('Action Required', style: TextStyle(color: Colors.red)),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(fontSize: 16, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF02adec)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Image', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF02adec),
      ),
      body: SingleChildScrollView(
        child: Container(
          color: const Color(0xFFE8ECF4),
          padding: EdgeInsets.all(screenWidth * 0.05),  // Use width for responsive padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset(
                'assets/cbct_device.jpg',
                height: screenHeight * 0.25,  // Responsive height based on screen size
                fit: BoxFit.contain,
              ),
              SizedBox(height: screenHeight * 0.03),
              const Text(
                'Upload Cross Section CBCT Image',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: screenHeight * 0.01),
              const Text(
                'Please select a CBCT image from your device to proceed with the prediction.',
                style: TextStyle(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: screenHeight * 0.03),
              GestureDetector(
                onTap: handleImageSelect,
                child: Container(
                  height: screenHeight * 0.25,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade400,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: selectedImage != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      File(selectedImage!.path),
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  )
                      : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey),
                      SizedBox(height: screenHeight * 0.01),
                      const Text(
                        'Tap to Select Image',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.04),
              ElevatedButton(
                onPressed: handleImageSelect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF02adec),
                  padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Select Image',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF02adec),
                      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02, horizontal: screenWidth * 0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Back',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: handleNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF02adec),
                      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02, horizontal: screenWidth * 0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Next',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
