import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

class CameraView extends StatefulWidget {
  const CameraView({
    Key? key,
    required this.onImage,
  }) : super(key: key);

  final Function(InputImage inputImage) onImage;

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  CameraController? _controller;
  late List<CameraDescription> _cameras;
  int _cameraIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    final CameraDescription camera = _cameras.first;

    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420, // Set to YUV_420_888
    );

    await _controller!.initialize();
    _controller!.startImageStream((CameraImage image) {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage != null) {
        widget.onImage(inputImage);
      }
    });
    setState(() {});
  }

  @override
  void dispose() {
    _controller?.stopImageStream();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return CameraPreview(_controller!);
  }

  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_controller == null) return null;

    final camera = _cameras[_cameraIndex];
    final sensorOrientation = camera.sensorOrientation;

    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation =
          _orientations[_controller!.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        // Front-facing camera adjustment
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        // Back-facing camera adjustment
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    if (rotation == null) return null;

    // Get the image format
    final format = InputImageFormatValue.fromRawValue(image.format.raw);

    // Validate the format depending on the platform
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) return null;

    // Process only if there is one plane (YUV_420_888 or similar)
    if (image.planes.length != 1) return null;

    final plane = image.planes.first;

    // Create the InputImage from the byte data
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation, // Used in Android
        format: format, // Used in iOS
        bytesPerRow: plane.bytesPerRow, // Used in iOS
      ),
    );
  }
}
