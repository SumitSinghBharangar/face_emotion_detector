import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_v2/tflite_v2.dart';

class EmotionProvider extends ChangeNotifier {
  CameraController? _controller;
  String _output = "";
  bool _isWorking = false; // Only for camera stream
  int _selectedCameraIndex = 0;
  bool _isInitialized = false;
  List<CameraDescription> _cameras = [];

  // --- NEW VARIABLES FOR IMAGE PICKER ---
  File? _selectedImage;
  bool _isImageMode = false;
  final ImagePicker _picker = ImagePicker();

  // Getters
  CameraController? get controller => _controller;
  String get output => _output;
  bool get isInitialized => _isInitialized;
  File? get selectedImage => _selectedImage;
  bool get isImageMode => _isImageMode;

  Future<void> init() async {
    _cameras = await availableCameras();
    await _loadModel();
    if (_cameras.isNotEmpty) {
      await _initCamera(_selectedCameraIndex);
    }
  }

  Future<void> _loadModel() async {
    await Tflite.loadModel(
      model: "assets/models/model.tflite",
      labels: "assets/models/labels.txt",
    );
  }

  Future<void> _initCamera(int index) async {
    if (_controller != null) await _controller!.dispose();
    _controller = CameraController(_cameras[index], ResolutionPreset.medium);

    try {
      await _controller!.initialize();
      _isInitialized = true;
      notifyListeners();

      // Only start streaming if we are NOT looking at a gallery image
      if (!_isImageMode) {
        _startLiveFeed();
      }
    } catch (e) {
      print("Camera Error: $e");
    }
  }

  void _startLiveFeed() {
    _controller!.startImageStream((image) {
      if (!_isWorking) {
        _isWorking = true;
        _runModelOnFrame(image);
      }
    });
  }

  // Logic 1: Run on Live Camera Frame
  Future<void> _runModelOnFrame(CameraImage image) async {
    if (_isImageMode) return; // Stop if we switched modes

    var predictions = await Tflite.runModelOnFrame(
      bytesList: image.planes.map((plane) => plane.bytes).toList(),
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
      notifyListeners();
    }
    _isWorking = false;
  }

  // Logic 2: Pick Image from Gallery
  Future<void> pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      _isImageMode = true;
      _selectedImage = File(image.path);
      _output = "Analyzing...";

      // Stop Camera Stream to save battery
      await _controller?.stopImageStream();
      _isWorking = false;

      notifyListeners();
      await _runModelOnImage(image.path);
    }
  }

  // Logic 3: Run on Static Image File
  Future<void> _runModelOnImage(String path) async {
    var predictions = await Tflite.runModelOnImage(
      path: path,
      numResults: 2,
      threshold: 0.1,
      imageMean: 127.5,
      imageStd: 127.5,
    );

    if (predictions != null && predictions.isNotEmpty) {
      _output = predictions[0]["label"];
    } else {
      _output = "No face detected";
    }
    notifyListeners();
  }

  // Logic 4: Close Image and Return to Camera
  Future<void> clearImageMode() async {
    _isImageMode = false;
    _selectedImage = null;
    _output = "";
    notifyListeners();

    // Restart Camera Stream
    if (_controller != null && _controller!.value.isInitialized) {
      _startLiveFeed();
    }
  }

  void switchCamera() {
    if (_cameras.length < 2) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    _isInitialized = false;
    notifyListeners();
    _initCamera(_selectedCameraIndex);
  }

  @override
  void dispose() {
    _controller?.dispose();
    Tflite.close();
    super.dispose();
  }
}
