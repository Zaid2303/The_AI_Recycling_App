import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class AIExplainScreen extends StatefulWidget {
  final String imagePath;

  const AIExplainScreen({Key? key, required this.imagePath}) : super(key: key);

  @override
  State<AIExplainScreen> createState() => _AIExplainScreenState();
}

class _AIExplainScreenState extends State<AIExplainScreen> {
  String predictionResult = "Loading...";
  Interpreter? interpreter;

  @override
  void initState() {
    super.initState();
    _loadModel();
    _predictImage(widget.imagePath);
  }

  // Load the TFLite model
  Future<void> _loadModel() async {
    try {
      interpreter =
          await Interpreter.fromAsset('assets/recycling_model.tflite');
      debugPrint("Model loaded successfully.");
    } catch (e) {
      debugPrint("Failed to load model: $e");
    }
  }

  // Run prediction on the image
  Future<void> _predictImage(String imagePath) async {
    if (interpreter == null) {
      setState(() {
        predictionResult = "Model not loaded.";
      });
      return;
    }

    try {
      // Load and preprocess the image
      final imageBytes = File(imagePath).readAsBytesSync();
      final input = _processImage(imageBytes);

      // Allocate memory for the output
      final output = List.filled(1 * 1, 0.0).reshape([1, 1]);

      // Run inference
      interpreter!.run(input, output);

      // Update the UI with the prediction result
      setState(() {
        predictionResult =
            "Prediction: ${output[0][0] > 0.5 ? 'Recyclable' : 'Non-Recyclable'}";
      });
    } catch (e) {
      debugPrint("Error during prediction: $e");
      setState(() {
        predictionResult = "Error occurred during prediction.";
      });
    }
  }

  // Helper function to preprocess the image
  List<List<List<double>>> _processImage(List<int> imageBytes) {
    // Add your preprocessing logic here (e.g., resizing, normalizing)
    // For now, this is a placeholder that assumes a processed format
    return [
      [
        [127.5], // Example normalized value
      ],
    ];
  }

  @override
  void dispose() {
    interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Explain Screen'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display the image in the top-left corner
            SizedBox(
              width: 100,
              height: 100,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.file(
                  File(widget.imagePath),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              predictionResult,
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
