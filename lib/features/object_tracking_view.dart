import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart'; // Ensure ML Kit dependencies are included

class ObjectTrackingView extends StatefulWidget {
  @override
  _ObjectTrackingViewState createState() => _ObjectTrackingViewState();
}

class _ObjectTrackingViewState extends State<ObjectTrackingView>
    with SingleTickerProviderStateMixin {
  late CameraController _cameraController;
  late BarcodeScanner _barcodeScanner;
  bool _isSensing = false;
  bool _isCameraInitialized = false; // Track camera initialization
  String _tooltipMessage = "Point your camera at a barcode";

  // Animation controller for pulsing animation
  AnimationController? _animationController;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _barcodeScanner = GoogleMlKit.vision.barcodeScanner();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _barcodeScanner.close();
    _animationController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final camera = cameras.first;
    _cameraController = CameraController(camera, ResolutionPreset.high);
    await _cameraController.initialize();

    if (mounted) {
      setState(() {
        _isCameraInitialized =
            true; // Set to true once the camera is initialized
      });
    }

    _cameraController.startImageStream((CameraImage image) {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage != null) {
        _processImage(inputImage);
      }
    });
  }

  Future<void> _processImage(InputImage inputImage) async {
    final barcodes = await _barcodeScanner.processImage(inputImage);
    if (barcodes.isNotEmpty) {
      _showBarcodeResults(barcodes.first.rawValue ?? '');
    } else {
      setState(() {
        _tooltipMessage = 'Move closer to the barcode';
        _isSensing = false;
      });
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final sensorOrientation = _cameraController.description.sensorOrientation;
    InputImageRotation? rotation;

    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation =
          _cameraController.value.deviceOrientation.index * 90;
      if (_cameraController.description.lensDirection ==
          CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }

    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) return null;

    if (image.planes.length != 1) return null;
    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  void _showBarcodeResults(String data) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          height: 200,
          child: Column(
            children: [
              Text('Barcode Data:'),
              Text(data),
              // You can add more fields to display barcode data here.
            ],
          ),
        );
      },
    );
  }

  void _toggleFlash() {
    if (_cameraController.value.flashMode == FlashMode.off) {
      _cameraController.setFlashMode(FlashMode.torch);
    } else {
      _cameraController.setFlashMode(FlashMode.off);
    }
  }

  void _openHelp() {
    // Handle opening help section
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Barcode Scanner'),
        actions: [
          IconButton(
            icon: Icon(Icons.flash_on), // Flash toggle
            onPressed: _toggleFlash,
          ),
          IconButton(
            icon: Icon(Icons.help_outline), // Help
            onPressed: _openHelp,
          ),
        ],
        leading: IconButton(
          icon: Icon(Icons.close), // Exit
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          _isCameraInitialized // Ensure camera is initialized before rendering
              ? Stack(
                  children: [
                    CameraPreview(_cameraController),
                    // Central barcode scanning area
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        width: 250,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.3),
                          border: Border.all(color: Colors.white, width: 2.0),
                        ),
                        child: _isSensing
                            ? PulsingAnimation(_animationController!)
                            : Container(),
                      ),
                    ),
                    // Top and Bottom opacity overlay
                    Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        height: 100, // Adjust the height for top opacity
                        color: Colors.black.withOpacity(0.5),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: 100, // Adjust the height for bottom opacity
                        color: Colors.black.withOpacity(0.5),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Tooltip(
                            message: _tooltipMessage,
                            child: Text(
                              _tooltipMessage,
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Center(
                  child:
                      CircularProgressIndicator()), // Show loading until camera is initialized
    );
  }
}

class PulsingAnimation extends StatelessWidget {
  final AnimationController controller;

  PulsingAnimation(this.controller);

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(begin: 0.8, end: 1.2).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      )),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.greenAccent, width: 2.0),
        ),
      ),
    );
  }
}
