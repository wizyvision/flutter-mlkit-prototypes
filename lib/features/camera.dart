import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

class CameraView extends StatefulWidget {
  final List<CameraDescription> cameras;
  final Function(InputImage inputImage) onImage;
  final CustomPaint? customPaint;

  const CameraView({
    super.key,
    required this.onImage,
    this.customPaint,
    required this.cameras,
  });

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> with WidgetsBindingObserver {
  // List<CameraDescription> cameras = [];
  CameraController? _cameraController;

  _CameraViewState();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (_cameraController == null ||
        _cameraController?.value.isInitialized == false) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _setupCameraController();
    }
  }

  @override
  void initState() {
    super.initState();
    _setupCameraController();
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: _buildUI(screenHeight, screenWidth),
    );
  }

  Widget _buildUI(double screenHeight, double screenWidth) {
    if (_cameraController == null ||
        _cameraController?.value.isInitialized == false) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    return SafeArea(
      child: Column(
        children: [
          // Top section with black background and top icons
          Container(
            color: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            height: screenHeight * 0.1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: screenWidth * 0.08,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(); // Go back to previous screen
                  },
                ),
                IconButton(
                  icon: Icon(
                    // _isFlashOn ? Icons.flash_on : Icons.flash_off,
                    Icons.flash_on,
                    color: Colors.white,
                    size: screenWidth * 0.08,
                  ),
                  onPressed: () async {
                    // setState(() {
                    //   _isFlashOn = !_isFlashOn;
                    // });
                    // await cameraController?.setFlashMode(
                    //   _isFlashOn ? FlashMode.torch : FlashMode.off,
                    // );
                  },
                ),
              ],
            ),
          ),

          // Middle section for Camera Preview
          Expanded(
            child: AspectRatio(
              aspectRatio: screenWidth / (screenHeight * 0.6),
              child: CameraPreview(
                _cameraController!,
                child: widget.customPaint,
              ),
            ),
          ),

          // Bottom section with black background and bottom icons
          Container(
            color: Colors.black,
            padding: const EdgeInsets.all(16.0),
            height: screenHeight * 0.25,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () async {
                    // Open gallery or perform another action
                  },
                  iconSize: screenWidth * 0.10,
                  icon: const Icon(
                    Icons.photo_library,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    XFile picture = await _cameraController!.takePicture();
                    Gal.putImage(
                      picture.path,
                    );
                  },
                  iconSize: screenWidth * 0.22,
                  icon: const Icon(
                    CupertinoIcons.circle_filled,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    // Handle switching cameras
                  },
                  iconSize: screenWidth * 0.10,
                  icon: const Icon(
                    CupertinoIcons.arrow_2_circlepath_circle_fill,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _setupCameraController() async {
    // List<CameraDescription> _cameras = await availableCameras();
    if (widget.cameras.isNotEmpty) {
      setState(() {
        final _cameras = widget.cameras;
        _cameraController = CameraController(
          _cameras.first,
          ResolutionPreset.max,
        );
      });
      _cameraController?.initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {});
      }).catchError(
        (Object e) {
          print(e);
        },
      );
    }
  }

  _processCameraImage(CameraImage image) {
    final inputImage = _inputImageFromCamera(image);
    if (inputImage == null) return;
    widget.onImage(inputImage);
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

    if (_cameraController == null) return null;

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: image.planes.length,
      ),
    );
  }
}
