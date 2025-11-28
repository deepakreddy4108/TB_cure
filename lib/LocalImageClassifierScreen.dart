import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'dart:typed_data';
import 'dart:math';

class TBDetectionScreen extends StatefulWidget {
  const TBDetectionScreen({super.key});

  @override
  State<TBDetectionScreen> createState() => _TBDetectionScreenState();
}

class _TBDetectionScreenState extends State<TBDetectionScreen>
    with TickerProviderStateMixin {
  File? _image;
  String _result = '';
  bool _isLoading = false;
  double _confidence = 0.0;
  final ImagePicker _picker = ImagePicker();

  Interpreter? _interpreter;
  bool _modelLoaded = false;
  bool _isOffline = false;

  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  // TB Facts for offline mode
  final List<String> _tbFacts = [
    "🫁 TB primarily affects the lungs but can impact any part of the body",
    "🔬 Early detection is crucial - AI can help identify TB patterns in chest X-rays",
    "💪 With proper treatment, TB is completely curable in most cases",
    "🌍 TB is one of the top 10 causes of death worldwide from infectious diseases",
    "⚡ Our AI model processes images locally - no internet needed for diagnosis",
    "🎯 Modern AI can detect TB with over 95% accuracy in chest X-rays",
    "🏥 This offline capability ensures healthcare access in remote areas",
    "🔒 Your medical data stays private - all processing happens on your device"
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadModel();
    _checkConnectivity();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _interpreter?.close();
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    // Simple connectivity check
    try {
      final result = await InternetAddress.lookup('google.com');
      setState(() {
        _isOffline = result.isEmpty || result[0].rawAddress.isEmpty;
      });
    } catch (_) {
      setState(() {
        _isOffline = true;
      });
      _showOfflineSnackbar();
    }
  }

  void _showOfflineSnackbar() {
    final randomFact = _tbFacts[Random().nextInt(_tbFacts.length)];

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 5),
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.shade600,
                Colors.purple.shade600,
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.offline_bolt,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Offline Mode Active',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      randomFact,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/tb_classifier.tflite');
      setState(() {
        _modelLoaded = true;
      });
      _slideController.forward();
      print("TB Detection Model loaded successfully!");
    } catch (e) {
      print("Error loading TB model: $e");
      _showErrorDialog("Failed to load TB detection model. Please ensure the model file is properly added to assets.");
    }
  }

  Future<List<double>> _preprocessImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();

      img.Image? image = img.decodeImage(bytes);
      if (image == null) throw Exception("Could not decode image");

      // Ensure RGB format (chest X-rays might be grayscale)
      if (image.numChannels == 1) {
        // Convert grayscale to RGB by duplicating the single channel
        final rgbImage = img.Image(
          width: image.width,
          height: image.height,
          numChannels: 3,
        );

        for (int y = 0; y < image.height; y++) {
          for (int x = 0; x < image.width; x++) {
            final grayValue = image.getPixel(x, y).r;
            rgbImage.setPixelRgb(x, y, grayValue, grayValue, grayValue);
          }
        }
        image = rgbImage;
      }

      // Resize to 224x224 (model input size)
      img.Image resizedImage = img.copyResize(image, width: 224, height: 224);

      // Convert to RGB and normalize (0-1)
      List<double> input = [];
      for (int y = 0; y < 224; y++) {
        for (int x = 0; x < 224; x++) {
          img.Pixel pixel = resizedImage.getPixel(x, y);
          input.add(pixel.r / 255.0); // Red
          input.add(pixel.g / 255.0); // Green
          input.add(pixel.b / 255.0); // Blue
        }
      }

      return input;
    } catch (e) {
      throw Exception("Error preprocessing chest X-ray: $e");
    }
  }

  Future<void> _classifyImage() async {
    if (_image == null || _interpreter == null) return;

    setState(() {
      _isLoading = true;
      _result = '';
      _confidence = 0.0;
    });

    try {
      // Preprocess image
      List<double> input = await _preprocessImage(_image!);

      // Prepare input tensor (1, 224, 224, 3)
      var inputTensor = List.generate(1, (i) =>
          List.generate(224, (j) =>
              List.generate(224, (k) =>
                  List.generate(3, (l) => input[(j * 224 + k) * 3 + l])
              )
          )
      );

      // Prepare output tensor
      var outputTensor = List.filled(1, List.filled(1, 0.0)).map((e) => List<double>.from(e)).toList();

      // Run inference
      _interpreter!.run(inputTensor, outputTensor);

      // Get prediction result
      double confidence = outputTensor[0][0];

      // Interpret results for TB detection (updated logic)
      String result;
      double confPercent;

      if (confidence > 0.5) {
        result = "TB Detected";
        confPercent = confidence * 100;
      } else {
        result = "Normal";
        confPercent = (1 - confidence) * 100;
      }

      setState(() {
        _result = result;
        _confidence = confPercent;
      });

      // Show result snackbar
      _showResultSnackbar(result, confPercent);

    } catch (e) {
      _showErrorDialog("TB analysis failed: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showResultSnackbar(String result, double confidence) {
    final isTB = result.contains("TB");

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 4),
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isTB
                  ? [Colors.red.shade400, Colors.red.shade600]
                  : [Colors.green.shade400, Colors.green.shade600],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isTB ? Icons.warning_rounded : Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Analysis Complete',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$result with ${confidence.toStringAsFixed(1)}% confidence',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TB Detection AI'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isOffline ? _pulseAnimation.value : 1.0,
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isOffline
                        ? Colors.orange.withOpacity(0.8)
                        : Colors.green.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isOffline ? Icons.wifi_off : Icons.wifi,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isOffline ? 'OFFLINE' : 'ONLINE',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            SlideTransition(
              position: _slideAnimation,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _modelLoaded
                        ? [Colors.green.shade50, Colors.green.shade100]
                        : [Colors.orange.shade50, Colors.orange.shade100],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _modelLoaded ? Colors.green.shade300 : Colors.orange.shade300,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _modelLoaded ? Colors.green.shade600 : Colors.orange.shade600,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _modelLoaded ? Icons.biotech : Icons.hourglass_empty,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _modelLoaded ? 'TB Detection AI Ready' : 'Loading TB Model...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _modelLoaded ? Colors.green.shade800 : Colors.orange.shade800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _modelLoaded
                                ? 'Advanced AI for tuberculosis detection'
                                : 'Initializing neural networks...',
                            style: TextStyle(
                              fontSize: 12,
                              color: _modelLoaded ? Colors.green.shade600 : Colors.orange.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade600,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.offline_bolt, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'LOCAL',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.shade50,
                    Colors.purple.shade50,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade600,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.medical_information,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tuberculosis Detection',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload chest X-ray for AI-powered TB analysis\nCompletely offline • HIPAA compliant • Instant results',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue.shade600,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Image Display
            Container(
              height: 320,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.grey.shade50,
                    Colors.grey.shade100,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: _image == null
                  ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.upload_file,
                      size: 60,
                      color: Colors.blue.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Upload Chest X-Ray',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select an image to begin TB analysis',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              )
                  : ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    Image.file(
                      _image!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                    if (_isLoading)
                      Container(
                        color: Colors.black.withOpacity(0.7),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: 3,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Analyzing chest X-ray...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_rounded),
                    label: const Text('Camera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_rounded),
                    label: const Text('Gallery'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Analyze Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _image == null || _isLoading || !_modelLoaded ? null : _classifyImage,
                icon: _isLoading
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Icon(Icons.biotech_rounded, size: 24),
                label: Text(
                  _isLoading ? 'Analyzing X-Ray...' : 'Detect TB (AI Analysis)',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 5,
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Result Display
            if (_result.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _result.toLowerCase().contains('normal')
                        ? [Colors.green.shade50, Colors.green.shade100]
                        : [Colors.red.shade50, Colors.red.shade100],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _result.toLowerCase().contains('normal')
                        ? Colors.green.shade300
                        : Colors.red.shade300,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _result.toLowerCase().contains('normal')
                            ? Colors.green.shade600
                            : Colors.red.shade600,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        _result.toLowerCase().contains('normal')
                            ? Icons.health_and_safety_rounded
                            : Icons.coronavirus_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'TB Detection Result',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _result.toLowerCase().contains('normal')
                            ? Colors.green.shade800
                            : Colors.red.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _result,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _result.toLowerCase().contains('normal')
                            ? Colors.green.shade800
                            : Colors.red.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Confidence: ${_confidence.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _result.toLowerCase().contains('normal')
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _confidence / 100,
                        backgroundColor: Colors.white.withOpacity(0.5),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _result.toLowerCase().contains('normal')
                              ? Colors.green.shade600
                              : Colors.red.shade600,
                        ),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade600,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.security, size: 16, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Processed securely on your device',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_result.toLowerCase().contains('tb')) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.yellow.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.yellow.shade300),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Please consult a healthcare professional for proper diagnosis and treatment.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 90, // Higher quality for medical images
      );

      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _result = '';
          _confidence = 0.0;
        });
      }
    } catch (e) {
      _showErrorDialog('Error selecting image: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('Error'),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue.shade600,
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}