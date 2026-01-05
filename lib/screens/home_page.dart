import 'package:camera/camera.dart';

import 'package:face_emotion_detector/provider/emotion_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Trigger the initialization when the page loads
    // "listen: false" is important here because we are inside initState
    Provider.of<EmotionProvider>(context, listen: false).init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Emotion Detection"),
        centerTitle: true,
        actions: [
          // Using Consumer to access the switchCamera function
          Consumer<EmotionProvider>(
            builder: (context, provider, child) {
              return IconButton(
                onPressed: provider.switchCamera,
                icon: const Icon(Icons.cameraswitch),
              );
            },
          ),
        ],
      ),
      // Consumer rebuilds ONLY this part when notifyListeners() is called
      body: Consumer<EmotionProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  width: MediaQuery.of(context).size.width * 0.9,
                  child: !provider.isInitialized
                      ? const Center(child: CircularProgressIndicator())
                      : AspectRatio(
                          aspectRatio: provider.controller!.value.aspectRatio,
                          child: CameraPreview(provider.controller!),
                        ),
                ),
              ),
              Text(
                provider.output,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 30,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
