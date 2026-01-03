import 'package:camera/camera.dart';
import 'package:face_emotion_detector/main.dart'; // To access the global 'cameras' list
import 'package:flutter/material.dart';
import 'package:tflite/tflite.dart';
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
    Tflite.close();
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

  runModel() async {
    if (cameraImage != null) {
      var predictions = await Tflite.runModelOnFrame(
        bytesList: cameraImage!.planes.map((element) {
          return element.bytes;
        }).toList(),
        imageHeight: cameraImage!.height,
        imageWidth: cameraImage!.width,
        imageMean: 127.5,
        imageStd: 127.5,
        rotation: 90,
        numResults: 2,
        threshold: 0.1,
        asynch: true,
      );

      // 3. RESET FLAG
      predictions!.forEach((element) {
        setState(() {
          output = element["label"];
        });
      });

      // Delay slightly to avoid blocking UI, then free the lock
      setState(() {
        isWorking = false;
      });
    }
  }

  loadModel() async {
    await Tflite.loadModel(
      model: "assets/models/model.tflite",
      labels: "assets/models/labels.txt",
    );
  }

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
