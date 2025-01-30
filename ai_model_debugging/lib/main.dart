import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: PredictionScreen(),
    );
  }
}

class PredictionScreen extends StatefulWidget {
  const PredictionScreen({super.key});

  @override
  State<PredictionScreen> createState() => PredictionScreenState();
}

class PredictionScreenState extends State<PredictionScreen> {
  String _prediction = 'Loading...';
  double _confidence = 0.0;
  bool _isLoading = true;
  late Interpreter _interpreter;
  final String _imagePath = 'assets/card_test_image1.jpg';
  List<String> _labels = [];

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await _loadLabels();
      await _initializeModel();
      await _predict();
    } catch (e) {
      _updateState(error: 'Error: ${e.toString()}');
    }
  }

  Future<void> _loadLabels() async {
    final labelData = await rootBundle.loadString('assets/labels.txt');
    _labels = labelData
        .split('\n')
        .where((label) => label.trim().isNotEmpty)
        .map((label) => label.trim())
        .toList();
  }

  Future<void> _initializeModel() async {
    _interpreter = await Interpreter.fromAsset('assets/model_unquant.tflite');

    // Verify input tensor requirements
    final inputTensor = _interpreter.getInputTensor(0);
    if (inputTensor.shape[1] != 224 || inputTensor.shape[2] != 224) {
      throw Exception('Model expects input shape ${inputTensor.shape}');
    }
  }

  Future<void> _predict() async {
    try {
      _updateState(loading: true);

      // Load and preprocess image
      final ByteData imageData = await rootBundle.load(_imagePath);
      final image = img.decodeImage(imageData.buffer.asUint8List())!;

      // Convert to proper 4D tensor format [1, 224, 224, 3]
      final inputBuffer = _createInputTensor(image);

      // Prepare output buffer with EXPLICIT double type
      final outputBuffer = List<double>.filled(6, 0.0).reshape([1, 6]);

      // Run inference
      _interpreter.run(inputBuffer, outputBuffer);

      // Process results with EXPLICIT type casting
      final results = (outputBuffer[0] as List<dynamic>).cast<double>();
      final maxConfidence = results.reduce(max);
      final maxIndex = results.indexOf(maxConfidence);

      _updateState(
        prediction: _labels[maxIndex],
        confidence: maxConfidence,
      );
    } catch (e) {
      _updateState(error: 'Prediction Error: ${e.toString()}');
    }
  }

  List<List<List<List<double>>>> _createInputTensor(img.Image image) {
    // Resize to model requirements
    final resized = img.copyResize(image, width: 224, height: 224);

    // Create 4D tensor [1, height, width, channels]
    return List.generate(
        1,
        (batch) => List.generate(
            224,
            (y) => List.generate(224, (x) {
                  final pixel = resized.getPixel(x, y);
                  return [
                    (pixel.r / 127.5) - 1.0, // Normalize to [-1, 1]
                    (pixel.g / 127.5) - 1.0,
                    (pixel.b / 127.5) - 1.0,
                  ];
                })));
  }

  void _updateState({
    String? prediction,
    double? confidence,
    String? error,
    bool loading = false,
  }) {
    if (!mounted) return;

    setState(() {
      _prediction = error ?? prediction ?? _prediction;
      _confidence = confidence ?? _confidence;
      _isLoading = loading;
    });
  }

  @override
  void dispose() {
    _interpreter.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Waste Classification')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Image.asset(
                _imagePath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Text('Failed to load image');
                },
              ),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 10),
                      Text('Processing...'),
                    ],
                  )
                : Column(
                    children: [
                      Text(
                        'Prediction: $_prediction',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Confidence: ${(_confidence * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _predict,
              child: const Text('Classify Again'),
            ),
          ],
        ),
      ),
    );
  }
}
