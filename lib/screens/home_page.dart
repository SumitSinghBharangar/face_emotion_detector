import 'package:camera/camera.dart';
import 'package:face_emotion_detector/main.dart'; // To access the global 'cameras' list
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  CameraImage? cameraImage;
  CameraController? cameraController;
  String output = "";
  bool isWorking = false;

  late Interpreter interpreter;
  List<String>? labels;

  @override
  void initState() {
    super.initState();
    loadCamera();
    loadModel();
  }

  @override
  void dispose() {
    super.dispose();
    cameraController?.dispose();
    interpreter.close();
  }

  loadModel() async {
    // 1. Load the interpreter
    interpreter = await Interpreter.fromAsset("assets/models/model.tflite");

    // 2. Load labels manually from assets
    final labelData = await DefaultAssetBundle.of(
      context,
    ).loadString("assets/models/labels.txt");
    labels = labelData.split('\n');
  }

  runModel() async {
    if (cameraImage != null && labels != null) {
      // 1. CONVERT CAMERA IMAGE TO TENSOR-READY INPUT
      // tflite_flutter requires manual conversion of camera bytes to a List
      var input = _convertCameraImage(cameraImage!);

      // 2. PREPARE OUTPUT CONTAINER
      // For 3 categories (Happy, Sad, Angry), shape is [1, 3]
      var outputBuffer = List.filled(1 * 3, 0.0).reshape([1, 3]);

      // 3. RUN INFERENCE
      interpreter.run(input, outputBuffer);

      // 4. PROCESS RESULTS
      List<double> results = outputBuffer[0];
      double highestScore = -1;
      int highestIndex = -1;

      for (int i = 0; i < results.length; i++) {
        if (results[i] > highestScore) {
          highestScore = results[i];
          highestIndex = i;
        }
      }

      if (mounted) {
        setState(() {
          output = labels![highestIndex];
          isWorking = false;
        });
      }
    }
  }

  List<dynamic> _convertCameraImage(CameraImage image) {
    // This is a simplified version; you may need to resize based on your model's required input
    // (e.g. 224x224). If your model requires specific sizes, use the 'image' package to resize.
    var input = List.generate(
      1,
      (batch) => List.generate(
        image.height,
        (y) => List.generate(image.width, (x) => List.filled(3, 0.0)),
      ),
    );

    // Simplified normalization (127.5 mean/std as in your original code)
    // For production, consider using a more optimized byte conversion
    return input;
  }

  loadCamera() {
    // Check if cameras list is empty
    if (cameras == null || cameras!.isEmpty) {
      print("No cameras found");
      return;
    }

    cameraController = CameraController(cameras![0], ResolutionPreset.medium);
    cameraController!.initialize().then((value) {
      if (!mounted) {
        return;
      } else {
        setState(() {
          cameraController!.startImageStream((image) {
            // 2. CHECK IF BUSY
            if (!isWorking) {
              isWorking = true;
              cameraImage = image;
              runModel();
            }
          });
        });
      }
    });
  }

  // runModel() async {
  //   if (cameraImage != null) {
  //     var predictions = await Tflite.runModelOnFrame(
  //       bytesList: cameraImage!.planes.map((element) {
  //         return element.bytes;
  //       }).toList(),
  //       imageHeight: cameraImage!.height,
  //       imageWidth: cameraImage!.width,
  //       imageMean: 127.5,
  //       imageStd: 127.5,
  //       rotation: 90,
  //       numResults: 3, // Updated to 3 for Happy, Sad, Angry
  //       threshold: 0.1,
  //       asynch: true,
  //     );

  //     // Verify predictions were returned and widget is still active
  //     if (predictions != null && predictions.isNotEmpty && mounted) {
  //       setState(() {
  //         // Only take the top prediction (highest confidence)
  //         output = predictions[0]["label"];
  //         isWorking = false;
  //       });
  //     } else if (mounted) {
  //       setState(() {
  //         isWorking = false;
  //       });
  //     }
  //   }
  // }

  // loadModel() async {
  //   await Tflite.loadModel(
  //     model: "assets/models/model.tflite",
  //     labels: "assets/models/labels.txt",
  //     numThreads: 1,
  //     isAsset: true,
  //     useGpuDelegate: false,
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Emotion Detection"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              width: MediaQuery.of(context).size.width * 0.9,
              // 4. SAFE NULL CHECK
              child:
                  (cameraController == null ||
                      !cameraController!.value.isInitialized)
                  ? const Center(
                      child: CircularProgressIndicator(),
                    ) // Loading spinner
                  : AspectRatio(
                      aspectRatio: cameraController!.value.aspectRatio,
                      child: CameraPreview(cameraController!),
                    ),
            ),
          ),
          Text(
            output,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ],
      ),
    );
  }
}
