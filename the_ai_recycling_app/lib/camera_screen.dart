import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

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
      // Fetch the available cameras
      _cameras = await availableCameras();

      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0], // Use the first available camera
          ResolutionPreset.high, // Set resolution
        );

        // Initialize the camera controller
        await _cameraController?.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      } else {
        debugPrint("No cameras available.");
      }
    } else {
      debugPrint("Camera permission denied.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Camera')),
      body: _isCameraInitialized
          ? Stack(
              children: [
                // Display the camera preview

                // Rotate the camera preview to correct orientation
                Transform.rotate(
                  angle: -90 * 3.14159 / 180, // Rotate 90 degrees
                  child: CameraPreview(_cameraController!),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
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

  Future<void> _capturePhoto() async {
    try {
      // Ensure the camera is ready to take a picture
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        // Capture the photo
        final image = await _cameraController!.takePicture();
        debugPrint('Photo captured: ${image.path}');

        // Display a snackbar or navigate to a preview screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Photo saved to ${image.path}')),
        );
      }
    } catch (e) {
      debugPrint('Error capturing photo: $e');
    }
  }
}
