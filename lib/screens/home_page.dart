import 'package:camera/camera.dart';
import 'package:face_emotion_detector/main.dart'; // To access global 'cameras'
import 'package:flutter/material.dart';
import 'package:tflite_v2/tflite_v2.dart'; // Use tflite_v2

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  CameraImage? cameraImage;
  CameraController? cameraController;
  String output = "";
  
  // Flag to prevent app freezing
  bool isWorking = false; 
  
  // Track which camera is selected (0 = Rear, 1 = Front usually)
  int selectedCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    loadModel();
    loadCamera(selectedCameraIndex);
  }

  @override
  void dispose() {
    cameraController?.dispose();
    Tflite.close();
    super.dispose();
  }

  // 1. LOAD MODEL
  loadModel() async {
    await Tflite.loadModel(
      model: "assets/models/model.tflite",
      labels: "assets/models/labels.txt",
    );
  }

  // 2. LOAD CAMERA (With Index)
  loadCamera(int index) {
    if (cameras == null || cameras!.isEmpty) return;

    // Dispose previous controller if switching
    if (cameraController != null) {
      cameraController!.dispose();
    }

    cameraController = CameraController(
      cameras![index], 
      ResolutionPreset.medium,
    );

    cameraController!.initialize().then((value) {
      if (!mounted) return;
      
      setState(() {
        cameraController!.startImageStream((image) {
          if (!isWorking) {
            isWorking = true;
            cameraImage = image;
            runModel();
          }
        });
      });
    });
  }

  // 3. RUN MODEL (Fixes "Always Happy")
  runModel() async {
    if (cameraImage != null) {
      var predictions = await Tflite.runModelOnFrame(
        bytesList: cameraImage!.planes.map((plane) {
          return plane.bytes;
        }).toList(),
        imageHeight: cameraImage!.height,
        imageWidth: cameraImage!.width,
        imageMean: 127.5,
        imageStd: 127.5,
        rotation: 90, // Adjust if detection is sideways
        numResults: 2,
        threshold: 0.1,
        asynch: true,
      );

      if (predictions != null && predictions.isNotEmpty) {
        setState(() {
          // Update output with the detected label
          output = predictions[0]["label"];
        });
      }
      
      // Allow next frame to process
      setState(() {
        isWorking = false;
      });
    }
  }

  // 4. SWITCH CAMERA LOGIC
  void _switchCamera() {
    if (cameras == null || cameras!.length < 2) return;

    setState(() {
      selectedCameraIndex = (selectedCameraIndex + 1) % cameras!.length;
    });
    
    // Stop working on current frame before switching
    isWorking = false;
    output = ""; 
    
    loadCamera(selectedCameraIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Emotion Detection"),
        centerTitle: true,
        actions: [
          // Camera Switch Button
          IconButton(
            onPressed: _switchCamera,
            icon: const Icon(Icons.cameraswitch),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              width: MediaQuery.of(context).size.width * 0.9,
              child: (cameraController == null || !cameraController!.value.isInitialized)
                  ? const Center(child: CircularProgressIndicator())
                  : AspectRatio(
                      aspectRatio: cameraController!.value.aspectRatio,
                      child: CameraPreview(cameraController!),
                    ),
            ),
          ),
          Text(
            output,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.deepPurple),
          ),
        ],
      ),
    );
  }
}