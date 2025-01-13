import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/*
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Model Test')),
        body: const ModelTestWidget(),
      ),
    );
  }
}

class ModelTestWidget extends StatefulWidget {
  const ModelTestWidget({super.key});

  @override
  ModelTestWidgetState createState() => ModelTestWidgetState();
}

class ModelTestWidgetState extends State<ModelTestWidget> {
  Interpreter? _interpreter;
  List<int>? _outputShape;
  String _output = "Initializing...";

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      // Load model data
      final ByteData modelData =
          await rootBundle.load('assets/recycling_model.tflite');
      final Uint8List modelBytes = modelData.buffer.asUint8List();
      debugPrint("Model size: ${modelBytes.length} bytes");

      // Initialize interpreter
      final options = InterpreterOptions()
        ..threads = 2
        ..useNnApiForAndroid = true;

      final interpreter = Interpreter.fromBuffer(modelBytes, options: options);
      final outputShape = interpreter.getOutputTensor(0).shape;

      setState(() {
        _interpreter = interpreter;
        _outputShape = outputShape;
        _output = "Model loaded successfully!";
      });
    } catch (e) {
      debugPrint("Error loading model: $e");
      setState(() {
        _output = "Error loading model: $e";
      });
    }
  }

  Future<void> _runInference() async {
    try {
      if (_interpreter == null) {
        setState(() {
          _output = "Model is not loaded yet.";
        });
        return;
      }

      final inputImage = await _loadAndPreprocessImage('assets/test_image.jpg');
      if (inputImage == null) {
        setState(() {
          _output = "Image preprocessing failed.";
        });
        return;
      }

      final input = inputImage.reshape([1, 150, 150, 3]);
      final output =
          List.filled(_outputShape![1], 0.0).reshape([1, _outputShape![1]]);

      _interpreter!.run(input, output);

      setState(() {
        _output = "Inference Output: ${output[0]}";
      });
    } catch (e) {
      debugPrint("Error during inference: $e");
      setState(() {
        _output = "Error during inference: $e";
      });
    }
  }

  Future<List<List<List<List<double>>>>?> _loadAndPreprocessImage(
      String path) async {
    try {
      final ByteData imageData = await rootBundle.load(path);
      final Uint8List imageBytes = imageData.buffer.asUint8List();

      final img.Image? image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception("Failed to decode image.");
      }

      final img.Image resizedImage =
          img.copyResize(image, width: 150, height: 150);

      final List<List<List<List<double>>>> normalized = [
        List.generate(
          150,
          (y) => List.generate(
            150,
            (x) {
              final pixel = resizedImage.getPixel(x, y);
              final r = pixel.r / 255.0; // Extract red
              final g = pixel.g / 255.0; // Extract green
              final b = pixel.b / 255.0; // Extract blue
              return [r, g, b];
            },
          ),
        ),
      ];

      return normalized;
    } catch (e) {
      debugPrint("Error preprocessing image: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_output),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _runInference,
            child: const Text('Run Inference'),
          ),
        ],
      ),
    );
  }
}


*/

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final ByteData modelData =
        await rootBundle.load('assets/recycling_model.tflite');
    debugPrint("Model size: ${modelData.lengthInBytes} bytes");

    final options = InterpreterOptions();
    final interpreter = Interpreter.fromBuffer(modelData.buffer.asUint8List(),
        options: options);
    debugPrint("Interpreter initialized successfully!");
  } catch (e) {
    debugPrint("Failed to load interpreter: $e");
  }
}
