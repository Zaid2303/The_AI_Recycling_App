import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this import
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class AIExplainScreen extends StatefulWidget {
  final String imagePath;

  const AIExplainScreen({super.key, required this.imagePath});

  @override
  State<AIExplainScreen> createState() => _AIExplainScreenState();
}

class _AIExplainScreenState extends State<AIExplainScreen> {
  String _prediction = 'Loading...';
  double _confidence = 0.0;
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeModel();
  }

  Future<void> _initializeModel() async {
    try {
      await Future.wait([
        _loadModel(),
        _loadLabels(),
      ]);
      _predictImage(File(widget.imagePath));
    } catch (e) {
      _updateState(error: 'Initialization Error: ${e.toString()}');
    }
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/model_unquant.tflite');
      final inputTensor = _interpreter!.getInputTensor(0);
      if (inputTensor.shape[1] != 224 || inputTensor.shape[2] != 224) {
        throw Exception('Model expects input shape ${inputTensor.shape}');
      }
    } catch (e) {
      _updateState(error: 'Model Error: ${e.toString()}');
      rethrow;
    }
  }

  Future<void> _loadLabels() async {
    try {
      final labelData = await rootBundle.loadString('assets/labels.txt');
      _labels = labelData
          .split('\n')
          .where((label) => label.trim().isNotEmpty)
          .map((label) => label.trim())
          .toList();
    } catch (e) {
      _updateState(error: 'Label Error: ${e.toString()}');
      rethrow;
    }
  }

  Future<void> _predictImage(File imageFile) async {
    if (_interpreter == null || _labels.isEmpty) return;

    try {
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);

      if (image == null) throw Exception('Failed to decode image');

      final inputBuffer = _createInputTensor(image);
      final outputBuffer = List<double>.filled(6, 0.0).reshape([1, 6]);

      _interpreter!.run(inputBuffer, outputBuffer);

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
    final resized = img.copyResize(image, width: 224, height: 224);
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
    _interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recycling Classification')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImagePreview(),
            const SizedBox(height: 20),
            _buildResultDisplay(),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Image.file(
          File(widget.imagePath),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.error,
            color: Colors.red,
            size: 40,
          ),
        ),
      ),
    );
  }

  Widget _buildResultDisplay() {
    return _isLoading
        ? const CircularProgressIndicator()
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Classification Result:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                _prediction,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 4),
              Text(
                'Confidence: ${(_confidence * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          );
  }
}
