import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'ai_explain_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    // Request camera permission
    if (await Permission.camera.request().isGranted) {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.high,
        );

        await _cameraController?.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Camera')),
      body: _isCameraInitialized
          ? Stack(
              children: [
                Center(
                  child: _buildFullScreenCameraPreview(context),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(25.0),
                    child: FloatingActionButton(
                      onPressed: _capturePhoto,
                      child: const Icon(Icons.camera),
                    ),
                  ),
                ),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }

  Widget _buildFullScreenCameraPreview(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(child: Text('Camera not initialized'));
    }

    // Get the aspect ratio of the camera preview
    final cameraAspectRatio = _cameraController!.value.aspectRatio;

    // Get the size of the device screen
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Use OverflowBox to fill the screen without distorting the preview
    return OverflowBox(
      maxWidth: (screenWidth / 1.02) * cameraAspectRatio,
      maxHeight: (screenHeight / 1.02) * cameraAspectRatio,
      //child: Transform.rotate(
      //angle: -90 * 3.14159 / 180, // Rotate the preview by 90 degrees
      //child: AspectRatio(
      //aspectRatio: cameraAspectRatio, // Preserve camera aspect ratio
      child: CameraPreview(_cameraController!),
      //),
      //),
    );
  }

  Future<void> _capturePhoto() async {
    try {
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        final image = await _cameraController!.takePicture();

        // Navigate to the AIExplainScreen and pass the image path
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AIExplainScreen(imagePath: image.path),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error capturing photo: $e');
    }
  }
}
