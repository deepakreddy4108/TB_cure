import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'main.dart'; // Import main.dart to access baseUrl

class SetOperation extends StatefulWidget {
  @override
  _SetOperationState createState() => _SetOperationState();
}

class _SetOperationState extends State<SetOperation> {
  final _storage = const FlutterSecureStorage();

  // Controllers for text fields
  final TextEditingController teethMeasurementsController = TextEditingController();
  final TextEditingController materialController = TextEditingController();
  final TextEditingController operationDateController = TextEditingController();
  final TextEditingController predictionController = TextEditingController();
  final TextEditingController operationDescriptionController = TextEditingController();

  String? selectedSlot; // For storing the selected slot
  final List<String> slots = List.generate(20, (index) {
    final hour = 8 + (index ~/ 2);
    final minute = (index % 2) * 30;
    final period = hour < 12 ? "AM" : "PM";
    final adjustedHour = hour > 12 ? hour - 12 : hour;
    return '${adjustedHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  });

  Future<void> submitOperationDetails() async {
    if (teethMeasurementsController.text.isEmpty || materialController.text.isEmpty || selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields.')),
      );
      return;
    }

    try {
      // Retrieve details from secure storage
      String? doctorId = await _storage.read(key: 'doctor_id');
      String? patientId = await _storage.read(key: 'patient_id');
      String? appointmentId = await _storage.read(key: 'appointment_id'); // Added appointment_id
      String? patientName = await _storage.read(key: 'appointment_patient_name');
      String? patientAge = await _storage.read(key: 'appointment_patient_age');
      String? patientGender = await _storage.read(key: 'appointment_patient_gender');
      String? patientMobile = await _storage.read(key: 'appointment_patient_mobile_number');
      String? patientAddress = await _storage.read(key: 'appointment_patient_address');

      // Check if mandatory fields are available
      if (doctorId == null || patientId == null || appointmentId == null || patientName == null || patientAge == null || patientGender == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Missing required information.')),
        );
        return;
      }

      // Combine date and slot for operation_date
      String operationDateTime = '${operationDateController.text} ${_formatSlotTo24Hour(selectedSlot!)}';

      final requestBody = {
        'doctorid': doctorId,
        'patientid': patientId,
        'appointment_id': appointmentId, // Passing appointment_id to PHP
        'patient_name': patientName,
        'patient_age': patientAge,
        'patient_gender': patientGender,
        'patient_mobile': patientMobile,
        'patient_address': patientAddress,
        'prediction': predictionController.text,
        'teeth_measurements': double.tryParse(teethMeasurementsController.text) ?? 0.0,
        'material': materialController.text,
        'operation_date': operationDateTime,
        'operation_description': operationDescriptionController.text,
      };

      final url = '$baseUrl/submitoperationdetails.php';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      var responseData = json.decode(response.body);
      if (responseData['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Operation details submitted successfully.')),
        );
        Navigator.pushReplacementNamed(context, '/doctorDashboard', arguments: {'doctorId': doctorId});
        clearFormFields();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${responseData['message']}')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting operation details: $error')),
      );
    }
  }

  String _formatSlotTo24Hour(String slot) {
    // Convert "08:00 AM" or "06:30 PM" to "08:00:00" or "18:30:00"
    final timeParts = slot.split(' ');
    final hourMinute = timeParts[0].split(':');
    int hour = int.parse(hourMinute[0]);
    final int minute = int.parse(hourMinute[1]);
    final isPM = timeParts[1] == 'PM';
    if (isPM && hour != 12) {
      hour += 12;
    } else if (!isPM && hour == 12) {
      hour = 0;
    }
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:00';
  }

  void clearFormFields() {
    teethMeasurementsController.clear();
    materialController.clear();
    operationDateController.clear();
    predictionController.clear();
    operationDescriptionController.clear();
    selectedSlot = null;
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double horizontalPadding = screenWidth * 0.05;
    double verticalSpacing = screenHeight * 0.02;
    double textFieldHeight = screenHeight * 0.07;
    double buttonHeight = screenHeight * 0.08;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Operation'),
        backgroundColor: const Color(0xFF02adec),
      ),
      body: Container(
        color: Colors.white,
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Container(
                padding: EdgeInsets.all(verticalSpacing),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    buildTextField('Thickness', teethMeasurementsController, TextInputType.number, textFieldHeight),
                    SizedBox(height: verticalSpacing),
                    buildTextField('Materials Required', materialController, TextInputType.text, textFieldHeight),
                    SizedBox(height: verticalSpacing),
                    buildDatePicker(),
                    SizedBox(height: verticalSpacing),
                    buildSlotDropdown(),
                    SizedBox(height: verticalSpacing),
                    buildTextField('Predicted Class', predictionController, TextInputType.text, textFieldHeight),
                    SizedBox(height: verticalSpacing),
                    buildTextField('Operation Description', operationDescriptionController, TextInputType.text, textFieldHeight),
                    SizedBox(height: verticalSpacing),
                    Container(
                      width: double.infinity,
                      height: buttonHeight,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: const Color(0xFF02adec),
                      ),
                      child: TextButton(
                        onPressed: submitOperationDetails,
                        child: const Text(
                          'Submit',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller, TextInputType inputType, double height) {
    return Container(
      height: height,
      child: TextField(
        controller: controller,
        keyboardType: inputType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget buildDatePicker() {
    return GestureDetector(
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(), // Restrict past dates
          lastDate: DateTime(2101),
        );
        if (pickedDate != null) {
          operationDateController.text = pickedDate.toIso8601String().split('T')[0];
        }
      },
      child: AbsorbPointer(
        child: TextField(
          controller: operationDateController,
          decoration: InputDecoration(
            labelText: 'Operation Date (Tap to select)',
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget buildSlotDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedSlot,
      items: slots.map((slot) {
        return DropdownMenuItem<String>(
          value: slot,
          child: Text(slot),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          selectedSlot = value;
        });
      },
      decoration: InputDecoration(
        labelText: 'Select Slot',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
