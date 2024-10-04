import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

class CameraView extends StatefulWidget {
  final List<CameraDescription> cameras;
  final Function(InputImage inputImage, CameraController controller) onImage;
  final CustomPaint? customPaint;
  final CameraLensDirection? initialCameraLensDirection;
  final bool isPaused;

  const CameraView({
    super.key,
    required this.onImage,
    this.customPaint,
    required this.cameras,
    this.initialCameraLensDirection = CameraLensDirection.back,
    required this.isPaused,
  });

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> with WidgetsBindingObserver {
  late CameraController _cameraController;
  bool _isPaused = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (_cameraController.value.isInitialized == false) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _setupCameraController(widget.cameras[0]);
    }
  }

  @override
  void initState() {
    super.initState();
    _setupCameraController(widget.cameras[0]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildUI(context),
    );
  }

  Widget _buildUI(BuildContext context) {
    if (!_cameraController.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return SafeArea(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double screenHeight = constraints.maxHeight;
          final double screenWidth = constraints.maxWidth;

          return Column(
            children: [
              // Top section with black background and top icons
              _buildTopControls(screenWidth),

              // Middle section for Camera Preview (with maintained aspect ratio)
              _buildCameraPreview(screenWidth, screenHeight),

              // Bottom section with black background and bottom icons
              _buildBottomControls(screenWidth),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopControls(double screenWidth) {
    return Container(
      color: Colors.black,
      padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04), // Responsive padding
      height: screenWidth * 0.2, // Adjust height based on screen width
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: screenWidth * 0.08, // Responsive icon size
            ),
            onPressed: () {
              Navigator.of(context).pop(); // Go back to the previous screen
            },
          ),
          IconButton(
            icon: Icon(
              Icons.flash_on, // Add flash toggle logic here
              color: Colors.white,
              size: screenWidth * 0.08,
            ),
            onPressed: () {
              // Handle flash toggle
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview(double screenWidth, double screenHeight) {
    return Expanded(
      child: Container(
        color: Colors.black,
        child: FittedBox(
          fit: BoxFit
              .cover, // Ensures that the preview covers the space without distorting the aspect ratio
          child: SizedBox(
            width: screenWidth,
            height: screenHeight * 0.65, // Adjust the height to fill more space
            child: AspectRatio(
              aspectRatio: _cameraController
                  .value.aspectRatio, // Maintain camera aspect ratio
              child: CameraPreview(
                _cameraController,
                child: widget.customPaint, // Overlay for custom painting
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls(double screenWidth) {
    return Container(
      color: Colors.black,
      padding: EdgeInsets.all(screenWidth * 0.04), // Responsive padding
      height: screenWidth * 0.45, // Adjust height based on screen width
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () async {
              // Open gallery or perform another action
            },
            iconSize: screenWidth * 0.1, // Adjust icon size dynamically
            icon: const Icon(
              Icons.photo_library,
              color: Colors.white,
            ),
          ),
          IconButton(
            onPressed: () async {
              XFile picture = await _cameraController.takePicture();
              Gal.putImage(picture.path);
            },
            iconSize: screenWidth * 0.22, // Larger size for capture button
            icon: const Icon(
              CupertinoIcons.circle_filled,
              color: Colors.white,
            ),
          ),
          IconButton(
            onPressed: () {
              // Handle switching cameras
            },
            iconSize: screenWidth * 0.1, // Adjust icon size dynamically
            icon: const Icon(
              CupertinoIcons.arrow_2_circlepath_circle_fill,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _setupCameraController(
      CameraDescription cameraDescription) async {
    _cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.high,
    );

    try {
      await _cameraController.initialize().then((_) {
        if (!mounted) return;
        _cameraController.startImageStream(_processCameraImage);
        setState(() {});
      });
    } on CameraException catch (e) {
      debugPrint("Camera error $e");
    }
  }

  _processCameraImage(CameraImage image) {
    if (widget.isPaused) {
      return;
    }

    final inputImage = _inputImageFromCamera(image);
    if (inputImage == null) return;
    widget.onImage(inputImage, _cameraController);
  }

  Uint8List _cameraImageToBytes(CameraImage image) {
    final WriteBuffer allBytes = WriteBuffer();
    for (Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();
    return bytes;
  }

  InputImage? _inputImageFromCamera(CameraImage image) {
    final bytes = _cameraImageToBytes(image);

    final imageRotation = InputImageRotationValue.fromRawValue(
            widget.cameras[0].sensorOrientation) ??
        InputImageRotation.rotation0deg;

    final inputImageFormat =
        InputImageFormatValue.fromRawValue(image.format.raw) ??
            InputImageFormat.nv21;

    int newWidth = image.planes[0].bytesPerRow;

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(newWidth.toDouble(), image.height.toDouble()),
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: image.planes.length,
      ),
    );
  }

  @override
  void dispose() {
    _stopLiveFeed();
    super.dispose();
  }

  Future<void> _stopLiveFeed() async {
    await _cameraController.stopImageStream();
    await _cameraController.dispose();
  }
}
