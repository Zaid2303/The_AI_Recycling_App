import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class AIExplainScreen extends StatefulWidget {
  final String imagePath;

  const AIExplainScreen({Key? key, required this.imagePath}) : super(key: key);

  @override
  State<AIExplainScreen> createState() => _AIExplainScreenState();
}

class _AIExplainScreenState extends State<AIExplainScreen> {
  String _prediction = 'Loading...';
  double _confidence = 0.0;
  String _message = '';
  Interpreter? _interpreter;
  List<String> _labels = [];

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
      _updateState(
        prediction: null,
        confidence: null,
        error: 'Initialization Error: $e',
      );
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
      _updateState(
        prediction: null,
        confidence: null,
        error: 'Model Error: $e',
      );
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
      _updateState(
        prediction: null,
        confidence: null,
        error: 'Label Error: $e',
      );
      rethrow;
    }
  }

  Future<void> _predictImage(File imageFile) async {
    if (_interpreter == null || _labels.isEmpty) {
      return;
    }

    try {
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      final inputBuffer = _createInputTensor(image);
      final outputBuffer = List<double>.filled(6, 0.0).reshape([1, 6]);

      _interpreter!.run(inputBuffer, outputBuffer);

      final results = (outputBuffer[0] as List<dynamic>).cast<double>();
      final maxConfidence = results.reduce(max);
      final maxIndex = results.indexOf(maxConfidence);

      final predictedLabel = _labels[maxIndex];
      _updateState(
        prediction: predictedLabel,
        confidence: maxConfidence,
        error: null,
      );
    } catch (e) {
      _updateState(
        prediction: null,
        confidence: null,
        error: 'Prediction Error: $e',
      );
    }
  }

  List<List<List<List<double>>>> _createInputTensor(img.Image image) {
    final resized = img.copyResize(image, width: 224, height: 224);
    return List.generate(
      1,
      (batch) => List.generate(
        224,
        (y) => List.generate(
          224,
          (x) {
            final pixel = resized.getPixel(x, y);
            return [
              (pixel.r / 127.5) - 1.0,
              (pixel.g / 127.5) - 1.0,
              (pixel.b / 127.5) - 1.0,
            ];
          },
        ),
      ),
    );
  }

  void _updateState({
    String? prediction,
    double? confidence,
    String? error,
  }) {
    if (!mounted) {
      return;
    }

    setState(() {
      _prediction = error ?? prediction ?? _prediction;
      _confidence = confidence ?? _confidence;
      if (error == null) {
        _message = generateMessage(prediction!);
      } else {
        _message = 'An error occurred. Please try again.';
      }
    });
  }

  String generateMessage(String prediction) {
    String recyclableStatus;
    switch (prediction.toLowerCase()) {
      case 'trash':
        recyclableStatus = 'It is not recyclable.';
        break;
      default:
        recyclableStatus = 'It is recyclable.';
        break;
    }
    return 'This item is $prediction. $recyclableStatus';
  }

  @override
  void dispose() {
    _interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recycling Classification'),
        backgroundColor: Colors.green,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImagePreview(),
                const Spacer(),
                _buildResultDisplay(),
                const SizedBox(height: 16),
                _buildMessageDisplay(),
                const Spacer(),
              ],
            ),
          ),
          Positioned(
            bottom: 16.0,
            right: 16.0,
            left: 16.0,
            child: Center(
              child: _buildDisclaimer(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 1,
          child: Image.file(
            File(widget.imagePath),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const Center(
              child: Icon(
                Icons.error,
                color: Colors.red,
                size: 48,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultDisplay() {
    return Container(
      padding: const EdgeInsets.all(32),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.category,
                color: Colors.green,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Item Type: $_prediction',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                'Confidence: ${(_confidence * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: 200,
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Colors.grey[200],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final confidenceWidth = (_confidence * constraints.maxWidth);
                return Stack(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      width: confidenceWidth,
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: const LinearGradient(
                          colors: [
                            Colors.green,
                            Colors.lightGreen,
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageDisplay() {
    IconData icon;
    Color iconColor;

    if (_message.contains('It is recyclable')) {
      icon = Icons.check_circle;
      iconColor = Colors.green;
    } else if (_message.contains('It is not recyclable')) {
      icon = Icons.warning;
      iconColor = Colors.orange;
    } else {
      icon = Icons.info;
      iconColor = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: iconColor.withAlpha(50),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: iconColor.withAlpha(30),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _message,
              style: TextStyle(
                color: iconColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: const Text(
        'Note: Predictions are based on a machine learning model and may not always be 100% accurate.',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12.0,
        ),
      ),
    );
  }
}
