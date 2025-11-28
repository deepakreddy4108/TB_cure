import 'package:flutter/material.dart';
import 'getstarted.dart';
import 'role.dart';
import 'doctorlogin.dart';
import 'patientlogin.dart';
import 'doctordashboard.dart';
import 'doctorsignup.dart';
import 'patientdashboard.dart';
import 'addpatient.dart';
import 'doctorappointments.dart';
import 'displayoperationdetails.dart';
import 'doctorprofile.dart';
import 'doctorsearch.dart';
import 'patientprofile.dart';
import 'patientsearch.dart';
import 'editpatientprofile.dart';
import 'patientsignup.dart';
import 'setoperation.dart';
import 'tips.dart';
import 'bookappointment.dart';
import 'patientappointments.dart';
import 'patientoperationdetails.dart';
import 'editdoctorprofile.dart';
import 'connect_with_doctor.dart';
import 'forgetpassword.dart';
import 'patient_notifications.dart';
import 'doctor_notifications.dart';
import 'connect_with_patient.dart';
import 'operation_details.dart';
import 'subscription_page.dart'; // 🔹 Import subscription page

const String baseUrl = 'http://14.139.187.229:8081/tbcure';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TbCure',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/', // 🔹 We’ll keep '/' for subscription first
      routes: {
        '/': (context) => const SubscriptionPage(), // 🔹 Subscription page appears first
        '/getStarted': (context) => const GetStarted(),
        '/roleSelection': (context) => const RoleSelection(),
        '/doctorLogin': (context) => const DoctorLogin(),
        '/patientLogin': (context) => const PatientLogin(),
        '/doctorDashboard': (context) => DoctorDashboard(),
        '/doctorSignup': (context) => DoctorSignup(),
        '/patientDashboard': (context) => PatientDashboard(),
        '/AddPatient': (context) => AddPatient(),
        '/DoctorAppointments': (context) => DoctorAppointments(),
        '/DisplayOperationDetails': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return DisplayOperationDetails(doctorId: args['doctorId']);
        },
        '/DoctorProfile': (context) => DoctorProfile(),
        '/Appointments': (context) => PatientAppointments(),
        '/PatientOperationDetails': (context) => PatientOperationDetails(),
        '/ConnectWithDoctor': (context) => ConnectWithDoctor(),
        '/EditPatientProfile': (context) => EditPatientProfile(),
        '/forgetPasswordDoctor': (context) => const ForgetPassword(),
        '/PatientNotifications': (context) => const PatientNotifications(),
        '/DoctorNotifications': (context) => const DoctorNotifications(),
        '/ConnectWithPatients': (context) => ConnectWithPatients(),
        '/OperationDetailsPage': (context) => OperationDetailsPage(),
        '/BookAppointment': (context) => PatientAppointments(),
      },
    );
  }
}
