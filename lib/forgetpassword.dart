import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'main.dart';

class ForgetPassword extends StatefulWidget {
  const ForgetPassword({Key? key}) : super(key: key);

  @override
  _ForgetPasswordState createState() => _ForgetPasswordState();
}

class _ForgetPasswordState extends State<ForgetPassword> {
  final _usernameController = TextEditingController();
  final _answer1Controller = TextEditingController();
  final _answer2Controller = TextEditingController();
  final _answer3Controller = TextEditingController();
  final _newPasswordController = TextEditingController();

  String question1 = '';
  String question2 = '';
  String question3 = '';
  bool showQuestions = false;
  bool allowPasswordChange = false;

  Future<void> handleFindAccount() async {
    try {
      print('Attempting to fetch questions...');
      final response = await http.post(
        Uri.parse('$baseUrl/forget_password.php'),
        body: {'action': 'fetch_questions', 'username': _usernameController.text},
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          setState(() {
            question1 = responseData['question_1'];
            question2 = responseData['question_2'];
            question3 = responseData['question_3'];
            showQuestions = true;
          });
        } else {
          showAlertDialog(context, 'Error', responseData['message']);
        }
      } else {
        showAlertDialog(context, 'Error', 'Server returned non-200 status code');
      }
    } catch (e) {
      print('Error fetching questions: $e');
      showAlertDialog(context, 'Error', 'Failed to fetch account details. Please try again.');
    }
  }

  Future<void> handleVerifyAnswers() async {
    try {
      print('Attempting to verify answers...');
      final response = await http.post(
        Uri.parse('$baseUrl/forget_password.php'),
        body: {
          'action': 'verify_answers',
          'username': _usernameController.text,
          'answer1': _answer1Controller.text,
          'answer2': _answer2Controller.text,
          'answer3': _answer3Controller.text,
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          setState(() {
            allowPasswordChange = true;
          });
        } else {
          showAlertDialog(context, 'Error', responseData['message']);
        }
      } else {
        showAlertDialog(context, 'Error', 'Server returned non-200 status code');
      }
    } catch (e) {
      print('Error verifying answers: $e');
      showAlertDialog(context, 'Error', 'Failed to verify answers. Please try again.');
    }
  }

  Future<void> handleResetPassword() async {
    try {
      print('Attempting to reset password...');
      final response = await http.post(
        Uri.parse('$baseUrl/forget_password.php'),
        body: {
          'action': 'reset_password',
          'username': _usernameController.text,
          'new_password': _newPasswordController.text,
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          showAlertDialog(context, 'Success', responseData['message'], onPressed: () {
            Navigator.pushNamedAndRemoveUntil(context, '/doctorLogin', (route) => false);
          });
        } else {
          showAlertDialog(context, 'Error', responseData['message']);
        }
      } else {
        showAlertDialog(context, 'Error', 'Server returned non-200 status code');
      }
    } catch (e) {
      print('Error resetting password: $e');
      showAlertDialog(context, 'Error', 'Failed to reset password. Please try again.');
    }
  }

  void showAlertDialog(BuildContext context, String title, String content, {VoidCallback? onPressed}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (onPressed != null) onPressed();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // MediaQuery for responsive design
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double padding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Forgot Password'),
        backgroundColor: const Color(0xFF02adec),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04), // Responsive padding
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.08), // Responsive padding
                  width: screenWidth * 0.9,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: !showQuestions
                      ? Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Enter Your Username',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF02adec),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.03),
                      TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          prefixIcon: const Icon(Icons.person, color: Color(0xFF02adec)),
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.03),
                      ElevatedButton(
                        onPressed: handleFindAccount,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF02adec),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.12, vertical: screenHeight * 0.02), // Responsive padding
                        ),
                        child: const Text(
                          'Find Account',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  )
                      : Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      buildSecurityQuestionField('Q1: $question1', _answer1Controller),
                      buildSecurityQuestionField('Q2: $question2', _answer2Controller),
                      buildSecurityQuestionField('Q3: $question3', _answer3Controller),
                      SizedBox(height: screenHeight * 0.03),
                      if (!allowPasswordChange)
                        ElevatedButton(
                          onPressed: handleVerifyAnswers,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF02adec),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.12, vertical: screenHeight * 0.02), // Responsive padding
                          ),
                          child: const Text(
                            'Verify Answers',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      if (allowPasswordChange)
                        Column(
                          children: [
                            TextField(
                              controller: _newPasswordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: 'New Password',
                                prefixIcon: const Icon(Icons.lock, color: Color(0xFF02adec)),
                                filled: true,
                                fillColor: Colors.grey[200],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.03),
                            ElevatedButton(
                              onPressed: handleResetPassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF02adec),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.12, vertical: screenHeight * 0.02), // Responsive padding
                              ),
                              child: const Text(
                                'Reset Password',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildSecurityQuestionField(String question, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.01), // Responsive spacing
        TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Your Answer',
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.02), // Responsive spacing
      ],
    );
  }
}
