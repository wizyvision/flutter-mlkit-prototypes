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
  // List<CameraDescription> cameras = [];
  late CameraController _cameraController;
  bool _isPaused = false;

  //_CameraViewState();

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
  void didUpdateWidget(covariant CameraView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!oldWidget.isPaused && widget.isPaused) {
      _cameraController.pausePreview();
      _isPaused = true;
    } else if (oldWidget.isPaused && !widget.isPaused) {
      _isPaused = false;
      _cameraController.resumePreview();
    }
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
    if (_cameraController.value.isInitialized == false) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    return SafeArea(
      child: Stack(
        children: [
          // Top section with black background and top icons
          Positioned(
            top: 0.0,
            left: 0.0,
            child: Container(
              color: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              height: screenHeight * 0.1,
              width: screenWidth,
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
          ),

          // Middle section for Camera Preview
          AnimatedPositioned(
            top: _isPaused ? 0.0 : (screenHeight * 0.1),
            left: 0.0,
            width: screenWidth,
            height: screenHeight * 0.6,
            duration: const Duration(milliseconds: 500),
            child: CameraPreview(
              _cameraController,
              child: widget.customPaint,
            ),
          ),

          // Bottom section with black background and bottom icons
          Positioned(
            left: 0.0,
            bottom: 0.0,
            height: _isPaused ? (screenHeight * 0.40) : (screenHeight * 0.30),
            //duration: const Duration(milliseconds: 500),
            child: Container(
              color: Colors.black,
              padding: const EdgeInsets.all(16.0),
              height: screenHeight * 0.25,
              width: screenWidth,
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
          ),
        ],
      ),
    );
  }

  Future<void> _setupCameraController(
      CameraDescription cameraDescription) async {
    // with if statement, widget camera is only initiatlized once and imageStream / inputimagefromcamera only happens once

    // List<CameraDescription> _cameras = await availableCameras();
    // if (widget.cameras.isNotEmpty) {
    //   setState(() {
    //     final _cameras = widget.cameras;
    //     _cameraController = CameraController(
    //       _cameras.first,
    //       ResolutionPreset.max,
    //     );
    //   });
    //   _cameraController?.initialize().then((_) {
    //     if (!mounted) {
    //       return;
    //     }
    //     _cameraController!.startImageStream(_inputImageFromCamera);
    //     setState(() {});
    //   }).catchError(
    //     (Object e) {
    //       print(e);
    //     },
    //   );
    // }

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
    if (_isPaused) return;

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

    //if (_cameraController == null) return null;

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
