import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'setoperation.dart';

class DeepLearningPrediction extends StatelessWidget {
  final Map<String, dynamic> appointment;
  final String predictionImage;
  final String predictionClass;  // To store the prediction class
  final String predictionValue;  // To store the prediction value

  const DeepLearningPrediction({
    Key? key,
    required this.appointment,
    required this.predictionImage,
    required this.predictionClass,
    required this.predictionValue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialize ScreenUtil to use the screen size
    ScreenUtil.init(context, designSize: Size(375, 812), minTextAdapt: true);

    double screenHeight = MediaQuery.of(context).size.height;

    // Safely parse predictionValue into double and round it to 2 decimals
    double? regressionValue;
    try {
      regressionValue = double.tryParse(predictionValue);
      if (regressionValue != null) {
        regressionValue = double.parse(regressionValue.toStringAsFixed(2));  // Round to 2 decimals
      }
    } catch (e) {
      regressionValue = null; // If parsing fails, set to null or use a fallback value
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prediction Page', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF02adec),
      ),
      body: Container(
        color: const Color(0xFFE8ECF4),
        padding: EdgeInsets.all(20.w), // Use ScreenUtil for responsive padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Uploaded Image:',
                  style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: Colors.black),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20.h),
                kIsWeb
                    ? Image.network(
                  predictionImage,
                  height: screenHeight * 0.4,
                  width: double.infinity,
                  fit: BoxFit.contain,
                )
                    : Image.file(
                  File(predictionImage),
                  height: screenHeight * 0.4,
                  width: double.infinity,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: 20.h),
                Text(
                  'Predicted Result:',
                  style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: Colors.black),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20.h),
                Container(
                  constraints: BoxConstraints(maxHeight: screenHeight * 0.2),
                  child: SingleChildScrollView(
                    child: Text(
                      regressionValue != null
                          ? regressionValue.toString() // Display the rounded regression value
                          : predictionValue, // Display the fallback message or the value
                      style: TextStyle(fontSize: 20.sp, color: Colors.black),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  'Prediction Class:',
                  style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: Colors.black),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10.h),
                Text(
                  predictionClass,  // Display the predicted class (label)
                  style: TextStyle(fontSize: 20.sp, color: Colors.black),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            SizedBox(height: 40.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Back', style: TextStyle(fontSize: 18.sp, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 15.h),
                    backgroundColor: const Color(0xFF02adec),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SetOperation()),
                    );
                  },
                  child: Text('Next', style: TextStyle(fontSize: 18.sp, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 15.h),
                    backgroundColor: const Color(0xFF02adec),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
