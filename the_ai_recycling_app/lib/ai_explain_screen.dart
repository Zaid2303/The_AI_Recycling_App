import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class AIExplainScreen extends StatefulWidget {
  final String imagePath;

  const AIExplainScreen({super.key, required this.imagePath});

  @override
  State<AIExplainScreen> createState() => _AIExplainScreenState();
}

class _AIExplainScreenState extends State<AIExplainScreen> {
  String predictionResult = "Loading...";
  Interpreter? interpreter;

  @override
  void initState() {
    super.initState();
    _loadModel().then((_) {
      _predictImage(widget.imagePath);
    });
  }

  // Load the TFLite model
  Future<void> _loadModel() async {
    try {
      interpreter = await Interpreter.fromAsset('recycling_model.tflite');
      if (interpreter != null) {
        var inputShape = interpreter!.getInputTensor(0).shape;
        var outputShape = interpreter!.getOutputTensor(0).shape;
        debugPrint("Model loaded successfully.");
        debugPrint("Input shape: $inputShape, Output shape: $outputShape");
      }
    } catch (e, stacktrace) {
      debugPrint("Failed to load model: $e");
      debugPrint("Stacktrace: $stacktrace");
      setState(() {
        predictionResult = "Error loading model.";
      });
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
      final input = await _processImage(imagePath);

      // Allocate memory for the output (adjust size as per your model)
      final output = List.filled(
              interpreter!.getOutputTensor(0).shape.reduce((a, b) => a * b),
              0.0)
          .reshape(interpreter!.getOutputTensor(0).shape);

      // Run inference
      interpreter!.run(input, output);

      // Get the predicted label and confidence
      final predictedIndex =
          output[0].indexOf(output[0].reduce((a, b) => a > b ? a : b));
      final confidence = output[0][predictedIndex];

      setState(() {
        predictionResult =
            "Prediction: Category $predictedIndex (Confidence: ${confidence.toStringAsFixed(2)})";
      });
    } catch (e) {
      debugPrint("Error during prediction: $e");
      setState(() {
        predictionResult = "Error occurred during prediction.";
      });
    }
  }

  Future<List<double>> _processImage(String imagePath) async {
    final imageFile = File(imagePath);

    // Check if the file exists
    if (!imageFile.existsSync()) {
      throw Exception("Image file not found at $imagePath");
    }

    final image = img.decodeImage(imageFile.readAsBytesSync());

    if (image == null) {
      throw Exception("Unable to decode image.");
    }

    // Resize the image to match the model's input size (e.g., 150x150)
    final resizedImage = img.copyResize(image, width: 150, height: 150);

    // Normalize pixel values (0-255) to the range [0, 1] and flatten the array
    final input = resizedImage
        .getBytes() // Get raw bytes of the image
        .map((pixel) => pixel / 255.0) // Normalize to [0, 1]
        .toList();

    return input;
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
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.error, color: Colors.red);
                  },
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
