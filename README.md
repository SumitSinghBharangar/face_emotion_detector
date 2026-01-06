# face_emotion_detector

A new Flutter project.

## Getting Started

A Flutter-based mobile application designed to detect face emotions in real-time using on-device Machine Learning. Users can seamlessly switch between live camera streaming and selecting static images from their gallery.

## Features

### 📸 Dual Detection Modes

- **Live Stream:** Real-time emotion detection overlay on the camera feed with high performance.

- **Gallery Mode:** Pick existing photos from the gallery to detect and analyze faces.

### 🧠 Smart Visuals

- **Real-time Inference:** Instant feedback on emotions (e.g., Happy, Sad, Angry) using a TFLite model.

- **Front/Back Camera Support:** Easily switch between selfie mode and rear camera.

- **Memory Efficient:** Prevents app freezes by managing camera streams intelligently.

### ⚡ Efficient Performance

- **Powered by TensorFlow Lite:** Fast, offline inference using `tflite_v2`.

- **Optimized State Management:** Uses **Provider** to separate business logic from UI, ensuring smooth frame rates.

- **Cross-Platform:** Runs on both Android and iOS.

## Technical Stack

- **Framework:** Flutter (Dart)

- **ML Engine:** TensorFlow Lite (`tflite_v2`)

- **State Management:** Provider

- **Camera:** Camera Plugin (Stream processing)

- **Image Handling:** Image Picker

## Getting Started

Follow these steps to set up the project locally.

### 1. Dependencies

Add the following to your `pubspec.yaml` file:

````yaml
dependencies:
  flutter:
    sdk: flutter
  camera: ^0.11.0
  tflite_v2: ^1.0.0
  provider: ^6.0.0
  image_picker: ^1.0.4

### Installation

1. **Clone the Repository**:

```bash
   git clone https://github.com/SumitSinghBharangar/face_emotion_detector
   cd face_emotion_detector
````

2. **Install Dependencies**:

```bash
    flutter pub get
```

3. **Run App**:

```bash
    flutter run
```

### Built With 🛠️

- Flutter – The UI framework for cross-platform development.

### Contributing 🤝

Contributions are welcome! To contribute:

1. Fork the repository.
2. Create a new branch (git checkout -b feature/YourFeature).
3. Commit your changes (git commit -m 'Add YourFeature').
4. Push to the branch (git push origin feature/YourFeature).
5. Open a Pull Request.

#### ⭐ If you like this project, star it on GitHub!

Repository: [https://github.com/SumitSinghBharangar/face_emotion_detector](https://github.com/SumitSinghBharangar/face_emotion_detector)
