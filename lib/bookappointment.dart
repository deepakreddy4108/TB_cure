import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'main.dart';

class BookAppointment extends StatefulWidget {
  @override
  _BookAppointmentState createState() => _BookAppointmentState();
}

class _BookAppointmentState extends State<BookAppointment> {
  final _storage = FlutterSecureStorage();
  TextEditingController doctorIdController = TextEditingController();
  TextEditingController patientProblemController = TextEditingController(); // Controller for Patient Problem
  DateTime appointmentDate = DateTime.now();
  String selectedTimeSlot = '08:00 AM'; // Default time slot
  bool isLoading = false;
  String? patientId;

  final List<String> timeSlots = [
    for (int i = 8; i < 18; i++)
      for (int j = 0; j < 60; j += 30)
        DateFormat('hh:mm a').format(DateTime(0, 1, 1, i, j))
  ];

  @override
  void initState() {
    super.initState();
    _getPatientId();
  }

  Future<void> _getPatientId() async {
    patientId = await _storage.read(key: 'patient_id');
    print('Retrieved Patient ID: $patientId');
  }

  Future<void> handleBookAppointment() async {
    if (patientId == null) {
      _showErrorDialog('Unable to retrieve patient ID. Please log in again.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      String formattedDate = DateFormat('yyyy-MM-dd').format(appointmentDate);
      String appointmentDateTime = '$formattedDate $selectedTimeSlot';

      var requestBody = json.encode({
        'doctorid': int.tryParse(doctorIdController.text) ?? 0,
        'patientid': int.tryParse(patientId ?? '0') ?? 0,
        'appointment_date': appointmentDateTime,
        'patient_problem': patientProblemController.text, // Include Patient Problem
      });

      var response = await http.post(
        Uri.parse('$baseUrl/book_appointment.php'),
        headers: {"Content-Type": "application/json"},
        body: requestBody,
      );

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        if (jsonResponse['success']) {
          _showSuccessDialog('Appointment booked successfully');
        } else {
          _showErrorDialog(jsonResponse['message'] ?? 'An error occurred');
        }
      } else {
        _showErrorDialog('Server returned an error: ${response.statusCode}');
      }
    } catch (error) {
      _showErrorDialog('An error occurred while booking the appointment');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.popAndPushNamed(context, '/patientDashboard');
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: appointmentDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && pickedDate != appointmentDate) {
      setState(() {
        appointmentDate = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width; // Screen width for responsiveness
    return Scaffold(
      appBar: AppBar(
        title: Text('Book Appointment'),
        backgroundColor: Color(0xFF02adec),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildDoctorIdField(),
            SizedBox(height: 16),
            GestureDetector(
              onTap: () => _selectDate(context),
              child: AbsorbPointer(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Appointment Date',
                    border: OutlineInputBorder(),
                  ),
                  controller: TextEditingController(
                    text: DateFormat('yyyy-MM-dd').format(appointmentDate),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField(
              value: selectedTimeSlot,
              items: timeSlots.map((slot) {
                return DropdownMenuItem(
                  value: slot,
                  child: Text(slot),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedTimeSlot = value.toString();
                });
              },
              decoration: InputDecoration(
                labelText: 'Select Time Slot',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: patientProblemController,
              decoration: InputDecoration(
                labelText: 'Patient Problem',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24),
            Center(
              child: SizedBox(
                width: screenWidth * 0.75, // 25% increased width
                child: ElevatedButton(
                  onPressed: isLoading ? null : handleBookAppointment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF02adec), // Matching app bar color
                    padding: EdgeInsets.symmetric(vertical: 16),
                    textStyle: TextStyle(fontSize: 16, color: Colors.white), // Text color changed to white
                  ),
                  child: isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Book Appointment', style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDoctorIdField() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: doctorIdController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Doctor ID',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.search),
          onPressed: () async {
            final selectedDoctorId = await Navigator.pushNamed(context, '/PatientSearch');
            if (selectedDoctorId != null) {
              setState(() {
                doctorIdController.text = selectedDoctorId.toString();
              });
            }
          },
        ),
      ],
    );
  }
}
