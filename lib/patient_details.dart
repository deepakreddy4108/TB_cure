import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'deep_learning_upload.dart'; // Import the upload page

class PatientDetails extends StatelessWidget {
  final Map<String, dynamic> appointment;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  const PatientDetails({Key? key, required this.appointment}) : super(key: key);

  Future<void> saveAppointmentDetails() async {
    // Save each appointment detail with unique keys to avoid conflicts with login data
    await _storage.write(key: 'appointment_id', value: appointment['appointmentid'].toString());
    await _storage.write(key: 'appointment_patient_id', value: appointment['patientid'].toString());
    await _storage.write(key: 'appointment_patient_name', value: appointment['patient_name']);
    await _storage.write(key: 'appointment_patient_gender', value: appointment['patient_gender']);
    await _storage.write(key: 'appointment_patient_problem', value: appointment['patient_problem']);
    await _storage.write(key: 'appointment_appointment_date', value: appointment['appointment_date']);
    await _storage.write(key: 'appointment_patient_age', value: appointment['patient_age'].toString());
    await _storage.write(key: 'appointment_patient_mobile_number', value: appointment['patient_mobile_number']);
    await _storage.write(key: 'appointment_patient_address', value: appointment['patient_address']);
    await _storage.write(key: 'appointment_status', value: appointment['status']);
  }

  void navigateToUpload(BuildContext context) async {
    // Save the details to storage before navigating
    await saveAppointmentDetails();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DeepLearningUpload(appointment: appointment),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Accepted':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      case 'Pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Icon _getStatusIcon(String status) {
    switch (status) {
      case 'Accepted':
        return const Icon(Icons.check_circle, color: Colors.green, size: 35);
      case 'Rejected':
        return const Icon(Icons.cancel, color: Colors.red, size: 35);
      case 'Pending':
        return const Icon(Icons.access_time, color: Colors.orange, size: 35);
      default:
        return const Icon(Icons.help, color: Colors.grey, size: 35);
    }
  }

  // Function to get icon color based on gender
  Color _getGenderIconColor(String gender) {
    return gender.toLowerCase() == 'male' ? Colors.blue : Colors.pink;
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen width and height for responsive scaling
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Details', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF02adec),
      ),
      body: Center(
        child: Container(
          color: const Color(0xFFE8ECF4),
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05), // Dynamic padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildDetailContainer([
                _buildIconTextWidget(Icons.info, 'Appointment ID: ${appointment['appointmentid']}', Colors.indigo, screenWidth, screenHeight),
                _buildIconTextWidget(Icons.person, 'Patient Name: ${appointment['patient_name']}', Colors.blue, screenWidth, screenHeight),
                _buildIconTextWidget(Icons.male, 'Gender: ${appointment['patient_gender']}', _getGenderIconColor(appointment['patient_gender']), screenWidth, screenHeight),
                _buildIconTextWidget(Icons.assignment_ind, 'Age: ${appointment['patient_age']}', Colors.green, screenWidth, screenHeight),
                _buildIconTextWidget(Icons.local_hospital, 'Problem: ${appointment['patient_problem']}', Colors.red, screenWidth, screenHeight),
                _buildIconTextWidget(Icons.date_range, 'Appointment Date: ${appointment['appointment_date']}', Colors.cyan, screenWidth, screenHeight),
                _buildIconTextWidget(Icons.phone, 'Mobile Number: ${appointment['patient_mobile_number']}', Colors.teal, screenWidth, screenHeight),
                _buildIconTextWidget(Icons.location_on, 'Address: ${appointment['patient_address']}', Colors.deepOrange, screenWidth, screenHeight),
                _buildStatusWidget(appointment['status'], screenWidth, screenHeight),
              ]),
              const SizedBox(height: 20), // Adding spacing between buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Back', style: TextStyle(fontSize: screenWidth * 0.05, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08, vertical: screenHeight * 0.015), // Dynamic padding
                      backgroundColor: const Color(0xFF02adec),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => navigateToUpload(context),
                    child: Text('Next', style: TextStyle(fontSize: screenWidth * 0.05, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08, vertical: screenHeight * 0.015), // Dynamic padding
                      backgroundColor: const Color(0xFF02adec),
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

  // This function creates an icon + text pair for each field
  Widget _buildIconTextWidget(IconData icon, String text, Color iconColor, double screenWidth, double screenHeight) {
    return Padding(
      padding: EdgeInsets.only(bottom: screenHeight * 0.02), // Dynamic padding
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: screenWidth * 0.09), // Adjusted icon size based on screen width
          SizedBox(width: screenWidth * 0.04), // Adjusted space between icon and text
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: screenWidth * 0.06, fontWeight: FontWeight.bold, color: Colors.black), // Dynamic font size
            ),
          ),
        ],
      ),
    );
  }

  // This function creates the status widget (icon + text)
  Widget _buildStatusWidget(String status, double screenWidth, double screenHeight) {
    return Row(
      children: [
        _getStatusIcon(status),
        SizedBox(width: screenWidth * 0.04), // Adjusted space between icon and text
        Text(
          'Status: $status',
          style: TextStyle(
            fontSize: screenWidth * 0.06, // Adjusted font size for the status
            fontWeight: FontWeight.bold,
            color: _getStatusColor(status),
          ),
        ),
      ],
    );
  }

  // This function wraps the list of widgets (details) into a container
  Widget _buildDetailContainer(List<Widget> details) {
    return Container(
      padding: EdgeInsets.all(20), // Increased padding for a bigger container
      margin: const EdgeInsets.symmetric(vertical: 10), // Reduced vertical margin
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: details, // Now accepts a list of widgets
      ),
    );
  }
}
