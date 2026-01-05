import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tflite_v2/tflite_v2.dart';

class EmotionProvider extends ChangeNotifier {
  CameraController? _controller;
  String _output = "";
  bool _isWorking = false;
  int _selectedCameraIndex = 0;
  bool _isInitialized = false;
  List<CameraDescription> _cameras = [];

  // Getters for the UI to access data
  CameraController? get controller => _controller;
  String get output => _output;
  bool get isInitialized => _isInitialized;

  // 1. Initialize Everything
  Future<void> init() async {
    _cameras = await availableCameras();
    if (_cameras.isNotEmpty) {
      await _loadModel();
      await _initCamera(_selectedCameraIndex);
    }
  }

  // 2. Load TFLite Model
  Future<void> _loadModel() async {
    await Tflite.loadModel(
      model: "assets/models/model.tflite",
      labels: "assets/models/labels.txt",
    );
  }

  // 3. Setup Camera
  Future<void> _initCamera(int index) async {
    if (_controller != null) {
      await _controller!.dispose();
    }

    _controller = CameraController(_cameras[index], ResolutionPreset.medium);

    try {
      await _controller!.initialize();
      _isInitialized = true;
      notifyListeners(); // Tell UI to show the camera preview

      // Start Stream
      _controller!.startImageStream((image) {
        if (!_isWorking) {
          _isWorking = true;
          _runModel(image);
        }
      });
    } catch (e) {
      print("Camera Error: $e");
    }
  }

  // 4. Run AI Inference
  Future<void> _runModel(CameraImage image) async {
    if (_controller == null) return;

    var predictions = await Tflite.runModelOnFrame(
      bytesList: image.planes.map((plane) {
        return plane.bytes;
      }).toList(),
      imageHeight: image.height,
      imageWidth: image.width,
      imageMean: 127.5,
      imageStd: 127.5,
      rotation: 90,
      numResults: 2,
      threshold: 0.1,
      asynch: true,
    );

    if (predictions != null && predictions.isNotEmpty) {
      _output = predictions[0]["label"];
      notifyListeners(); // Tell UI to update the text
    }

    _isWorking = false;
  }

  // 5. Switch Camera Logic
  void switchCamera() {
    if (_cameras.length < 2) return;

    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    _isInitialized = false;
    _output = ""; // Reset text
    notifyListeners(); // Show loading spinner

    _initCamera(_selectedCameraIndex);
  }

  @override
  void dispose() {
    _controller?.dispose();
    Tflite.close();
    super.dispose();
  }
}
