import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

class ObjectTrackingView extends StatefulWidget {
  @override
  _ObjectTrackingViewState createState() => _ObjectTrackingViewState();
}

class _ObjectTrackingViewState extends State<ObjectTrackingView> {
  CameraController? cameraController; // Change to nullable type
  late ObjectDetector objectDetector;
  bool isDetecting = false; // Track if detection is in progress
  bool isCameraInitialized = false; // Track if the camera is initialized

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeObjectDetector();
  }

  Future<void> _initializeCamera() async {
    try {
      // Initialize the camera and the camera controller
      final cameras = await availableCameras();
      cameraController = CameraController(
        cameras.first,
        ResolutionPreset.high,
      );

      await cameraController!.initialize();
      cameraController!.startImageStream(_processCameraImage);
      setState(() {
        isCameraInitialized = true; // Set camera initialization flag
      });
    } catch (e) {
      // Handle camera initialization errors
      print('Error initializing camera: $e');
    }
  }

  void _initializeObjectDetector() {
    // Specify the path to your model
    const modelPath =
        'assets/models/object_detection_model.tflite'; // Change this to your model's path

    // Create options for the object detector
    final options = LocalObjectDetectorOptions(
      mode: DetectionMode.stream,
      modelPath: modelPath,
      classifyObjects: true,
      multipleObjects: true,
      confidenceThreshold: 0.5,
    );

    // Initialize the object detector
    objectDetector = ObjectDetector(options: options);
  }

  void _processCameraImage(CameraImage image) async {
    if (isDetecting) return; // Prevent multiple detections at once
    isDetecting = true; // Set detecting flag

    try {
      // Convert CameraImage to InputImage
      InputImage inputImage = _convertCameraImage(image);

      // Process the image for object detection
      final List<DetectedObject> objects =
          await objectDetector.processImage(inputImage);

      // Handle the detected objects (e.g., update the UI)
      setState(() {
        // Update your state with detected objects
      });
    } catch (e) {
      // Handle processing errors
      print('Error processing image: $e');
    } finally {
      isDetecting = false; // Reset detecting flag
    }
  }

  InputImage _convertCameraImage(CameraImage image) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();
    final size = Size(image.width.toDouble(), image.height.toDouble());

    // Create the InputImageMetadata
    final metadata = InputImageMetadata(
      size: size,
      rotation: InputImageRotation.rotation0deg, // Adjust as needed
      format: InputImageFormat.yuv_420_888, // Ensure the correct format
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    // Create the InputImage from bytes and metadata
    return InputImage.fromBytes(
      bytes: bytes,
      metadata: metadata,
    );
  }

  @override
  void dispose() {
    cameraController
        ?.dispose(); // Ensure to dispose of the controller if initialized
    objectDetector.close(); // Ensure to close the detector
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child:
            isCameraInitialized // Use the initialization flag to check the camera state
                ? CameraPreview(
                    cameraController!) // Use the nullable cameraController safely
                : CircularProgressIndicator(),
      ),
    );
  }
}
