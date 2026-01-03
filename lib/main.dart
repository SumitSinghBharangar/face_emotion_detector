import 'package:camera/camera.dart';
import 'package:face_emotion_detector/screens/home_page.dart';
import 'package:flutter/material.dart';

List<CameraDescription>? cameras;

void main() async {
  cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const HomePage(),
    );
  }
}
