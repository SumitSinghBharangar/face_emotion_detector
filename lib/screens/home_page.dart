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
    Provider.of<EmotionProvider>(context, listen: false).init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Emotion Detector"),
        centerTitle: true,
        actions: [
          // Only show camera switch if we are NOT viewing an image
          Consumer<EmotionProvider>(
            builder: (context, provider, child) {
              if (provider.isImageMode) return const SizedBox(); // Hide button
              return IconButton(
                onPressed: provider.switchCamera,
                icon: const Icon(Icons.cameraswitch),
              );
            },
          ),
        ],
      ),
      body: Consumer<EmotionProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // --- MAIN VIEW AREA ---
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.deepPurple, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: _buildMainView(provider),
                    ),
                  ),
                ),
              ),

              // --- OUTPUT TEXT ---
              Text(
                provider.output,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 30,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),

      // --- FLOATING ACTION BUTTON TO PICK IMAGE ---
      floatingActionButton: Consumer<EmotionProvider>(
        builder: (context, provider, child) {
          if (provider.isImageMode) {
            // If viewing an image, show "Close" button
            return FloatingActionButton.extended(
              onPressed: provider.clearImageMode,
              label: const Text("Back to Live"),
              icon: const Icon(Icons.close),
              backgroundColor: Colors.red,
            );
          } else {
            // If live, show "Gallery" button
            return FloatingActionButton(
              onPressed: provider.pickImageFromGallery,
              child: const Icon(Icons.image),
            );
          }
        },
      ),
    );
  }

  // Helper Widget to switch between Camera and Image
  Widget _buildMainView(EmotionProvider provider) {
    if (provider.isImageMode && provider.selectedImage != null) {
      // Show Gallery Image
      return Image.file(provider.selectedImage!, fit: BoxFit.cover);
    } else {
      // Show Live Camera
      if (!provider.isInitialized) {
        return const Center(child: CircularProgressIndicator());
      }
      return CameraPreview(provider.controller!);
    }
  }
}
