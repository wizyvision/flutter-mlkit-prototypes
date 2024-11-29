import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

class CameraView extends StatefulWidget {
  final List<CameraDescription> cameras;
  final Function(InputImage inputImage) onImage;
  final CustomPaint? customPaint;
  final CameraLensDirection initialCameraLensDirection;
  final bool isPaused;
  final void Function(Size)? onCameraPreviewSize;

  const CameraView({
    Key? key,
    required this.onImage,
    this.customPaint,
    required this.cameras,
    this.initialCameraLensDirection = CameraLensDirection.back,
    required this.isPaused,
    this.onCameraPreviewSize,
  }) : super(key: key);

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> with WidgetsBindingObserver {
  late CameraController _cameraController;
  bool _isFlashOn = false;
  late CameraDescription _currentCamera;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (_cameraController.value.isInitialized == false) return;
    if (state == AppLifecycleState.inactive) {
      _cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _setupCameraController(_currentCamera);
    }
  }

  @override
  void initState() {
    super.initState();
    _currentCamera = widget.cameras.firstWhere(
      (camera) => camera.lensDirection == widget.initialCameraLensDirection,
      orElse: () => widget.cameras.first,
    );
    _setupCameraController(_currentCamera);
  }

  @override
  void didUpdateWidget(covariant CameraView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!oldWidget.isPaused && widget.isPaused) {
      _cameraController.pausePreview();
    } else if (oldWidget.isPaused && !widget.isPaused) {
      _cameraController.resumePreview();
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            if (_cameraController.value.isInitialized)
              CameraPreview(
                _cameraController,
                child: widget.customPaint,
              )
            else
              const Center(child: CircularProgressIndicator()),

            // Top Bar with back and flash buttons
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildTopBar(screenWidth),
            ),

            // Bottom Bar with capture, gallery, and switch camera buttons
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomBar(screenWidth),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(double screenWidth) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            iconSize: screenWidth * 0.08,
            onPressed: () => Navigator.of(context).pop(),
          ),
          IconButton(
            icon: Icon(
              _isFlashOn ? Icons.flash_on : Icons.flash_off,
              color: Colors.white,
            ),
            iconSize: screenWidth * 0.08,
            onPressed: _toggleFlash,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(double screenWidth) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _openGallery,
            icon: const Icon(Icons.photo_library, color: Colors.white),
            iconSize: screenWidth * 0.10,
          ),
          IconButton(
            onPressed: _capturePhoto,
            icon: const Icon(CupertinoIcons.circle_filled, color: Colors.white),
            iconSize: screenWidth * 0.22,
          ),
          IconButton(
            onPressed: _switchCamera,
            icon: const Icon(CupertinoIcons.arrow_2_circlepath_circle_fill,
                color: Colors.white),
            iconSize: screenWidth * 0.10,
          ),
        ],
      ),
    );
  }

  Future<void> _setupCameraController(
      CameraDescription cameraDescription) async {
    _cameraController =
        CameraController(cameraDescription, ResolutionPreset.high);
    try {
      await _cameraController.initialize();
      widget.onCameraPreviewSize?.call(_cameraController.value.previewSize!);
      _cameraController.startImageStream(_processCameraImage);
      setState(() {});
    } catch (e) {
      debugPrint("Error initializing camera: $e");
    }
  }

  void _processCameraImage(CameraImage image) {
    if (widget.isPaused) return;
    final inputImage = _inputImageFromCamera(image);
    if (inputImage != null) {
      widget.onImage(inputImage);
    }
  }

  InputImage? _inputImageFromCamera(CameraImage image) {
    final bytes = _cameraImageToBytes(image);
    final imageRotation = InputImageRotationValue.fromRawValue(
            _currentCamera.sensorOrientation) ??
        InputImageRotation.rotation0deg;
    final inputImageFormat =
        InputImageFormatValue.fromRawValue(image.format.raw) ??
            InputImageFormat.nv21;

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  Uint8List _cameraImageToBytes(CameraImage image) {
    final WriteBuffer buffer = WriteBuffer();
    for (Plane plane in image.planes) {
      buffer.putUint8List(plane.bytes);
    }
    return buffer.done().buffer.asUint8List();
  }

  Future<void> _toggleFlash() async {
    setState(() {
      _isFlashOn = !_isFlashOn;
    });
    await _cameraController
        .setFlashMode(_isFlashOn ? FlashMode.torch : FlashMode.off);
  }

  Future<void> _capturePhoto() async {
    final XFile picture = await _cameraController.takePicture();
    // Save or process the captured photo
  }

  Future<void> _switchCamera() async {
    final lensDirection = _currentCamera.lensDirection;
    final newCamera = widget.cameras.firstWhere(
      (camera) => camera.lensDirection != lensDirection,
      orElse: () => widget.cameras[0],
    );
    await _cameraController.dispose();
    setState(() {
      _currentCamera = newCamera;
    });
    _setupCameraController(newCamera);
  }

  Future<void> _openGallery() async {
    // Implement gallery opening logic
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }
}
