import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:ml_kit_implementation/features/camera_controller_notifier.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class CameraNewView extends StatefulWidget {
  final List<CameraDescription> cameras;
  final Function(InputImage inputImage, CameraController controller) onImage;
  final bool isPaused;
  final Function(Size size)? onSizeChanged;
  final Future<void> Function() onCapturePressed;

  const CameraNewView({
    super.key,
    required this.cameras,
    required this.onImage,
    required this.isPaused,
    this.onSizeChanged,
    required this.onCapturePressed,
  });

  @override
  State<CameraNewView> createState() => _CameraNewViewState();
}

class _CameraNewViewState extends State<CameraNewView> {
  late CameraControllerNotifier _cameraNotifier;
  double _lastZoomLevel = 1.0;
  bool isFlashOn = false;
  int currentCameraIndex = 0;
  int _lastProcessedTime = 0;
  final int debounceDurationMs = 500; // Debounce to reduce load

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cameraNotifier = context.read<CameraControllerNotifier>();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupCameraController(widget.cameras[0]);
    });
  }

  Future<void> _setupCameraController(
      CameraDescription cameraDescription) async {
    // Request camera permissions
    var status = await Permission.camera.request();
    if (status.isGranted) {
      try {
        await _cameraNotifier.initialize(cameraDescription);
        // Ensure the controller is initialized before starting the image stream
        if (_cameraNotifier.controller != null) {
          // Stop the stream if it's already active
          if (_cameraNotifier.controller!.value.isStreamingImages) {
            await _cameraNotifier.controller!.stopImageStream();
          }
          await _cameraNotifier.controller!
              .startImageStream(_processCameraImage);
        }
      } catch (e) {
        debugPrint('Camera initialization failed: $e');
      }
    } else {
      debugPrint("Camera permission denied");
    }
  }

  void _processCameraImage(CameraImage image) {
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    // Debounce and check if the camera is paused
    if (currentTime - _lastProcessedTime < debounceDurationMs ||
        widget.isPaused ||
        _cameraNotifier.controller == null ||
        !_cameraNotifier.controller!.value.isInitialized) {
      return;
    }

    _lastProcessedTime = currentTime; // Update last processed time

    final inputImage = _inputImageFromCamera(image);
    if (inputImage != null) {
      widget.onImage(inputImage, _cameraNotifier.controller!);
    }
  }

  Uint8List _cameraImageToBytes(CameraImage image) {
    final WriteBuffer allBytes = WriteBuffer();
    for (Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }

  InputImageMetadata? _cachedMetadata;

  InputImageMetadata _createImageMetadata(CameraImage image) {
    if (_cachedMetadata == null || image.width != _cachedMetadata!.size.width) {
      final imageRotation = InputImageRotationValue.fromRawValue(
              widget.cameras[0].sensorOrientation) ??
          InputImageRotation.rotation0deg;
      final inputImageFormat =
          InputImageFormatValue.fromRawValue(image.format.raw) ??
              InputImageFormat.nv21;
      _cachedMetadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: image.planes[0].bytesPerRow,
      );
    }
    return _cachedMetadata!;
  }

  InputImage? _inputImageFromCamera(CameraImage image) {
    final bytes = _cameraImageToBytes(image);
    return InputImage.fromBytes(
      bytes: bytes,
      metadata: _createImageMetadata(image),
    );
  }

  @override
  void didUpdateWidget(covariant CameraNewView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Pause or resume camera stream based on isPaused flag
    if (widget.isPaused && !oldWidget.isPaused) {
      _pauseCameraStream();
    } else if (!widget.isPaused && oldWidget.isPaused) {
      _resumeCameraStream();
    }
  }

  void _pauseCameraStream() {
    _cameraNotifier.controller?.stopImageStream();
  }

  void _resumeCameraStream() {
    _cameraNotifier.controller?.startImageStream(_processCameraImage);
  }

  @override
  void dispose() {
    // Stop the image stream if it's running
    if (_cameraNotifier.controller != null &&
        _cameraNotifier.controller!.value.isStreamingImages) {
      _cameraNotifier.controller!.stopImageStream();
    }
    _cameraNotifier.disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            _buildCameraPreview(context),
            _buildZoomSlider(context),
            _buildTopController(context),
            _buildBottomController(context),
            _buildFocusIndicator(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview(BuildContext context) {
    return GestureDetector(
      onTapUp: (details) {
        // Handle tap to focus (if autofocus isn't locked)
        if (!_cameraNotifier.isAutoFocusLocked) {
          _cameraNotifier.focusOnPoint(
            details.localPosition,
            MediaQuery.of(context).size,
          );
        }
      },
      onLongPressStart: (details) {
        // Lock focus on long press
        _cameraNotifier.lockFocusOnPoint(
          details.localPosition,
          MediaQuery.of(context).size,
        );
      },
      onTap: () {
        // Unlock autofocus on tap anywhere (if locked)
        if (_cameraNotifier.isAutoFocusLocked) {
          _cameraNotifier.toggleAutoFocusLock();
        }
      },
      onScaleUpdate: (details) {
        // Handle pinch to zoom
        if (details.scale != 1.0) {
          double newZoomLevel = _lastZoomLevel * details.scale;
          _cameraNotifier.setZoomLevel(newZoomLevel.clamp(
            _cameraNotifier.minZoom,
            _cameraNotifier.maxZoom,
          ));
        }
      },
      child: Consumer<CameraControllerNotifier>(
        builder: (context, notifier, child) {
          if (notifier.controller == null ||
              !notifier.controller!.value.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }
          final size =
              MediaQuery.of(context).size; // Get the size of the widget
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (widget.onSizeChanged != null) {
              widget.onSizeChanged!(size); // Call the callback with the size
            }
          });
          return SizedBox.expand(
            // Ensure the preview takes up all available space
            child: CameraPreview(notifier.controller!),
          );
        },
      ),
    );
  }

  Widget _buildZoomSlider(BuildContext context) {
    return Positioned(
      bottom: 100,
      left: 20,
      right: 20,
      child: Column(
        children: [
          Selector<CameraControllerNotifier, double>(
            selector: (context, notifier) => notifier.zoomLevel,
            builder: (context, zoomLevel, child) {
              return Text(
                'x${zoomLevel.toStringAsFixed(1)}', // Display zoom level as 'x1.0'
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
          Selector<CameraControllerNotifier, double>(
            selector: (context, notifier) => notifier.zoomLevel,
            builder: (context, zoomLevel, child) {
              return Slider(
                value: zoomLevel,
                min: _cameraNotifier.minZoom,
                max: _cameraNotifier.maxZoom,
                onChanged: (zoom) {
                  _cameraNotifier.setZoomLevel(zoom);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTopController(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
        height: 60,
        color: Colors.black.withOpacity(0.6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Back button
            IconButton(
              onPressed: () {
                Navigator.of(context).pop(); // Go back to the previous screen
              },
              icon: Icon(
                Icons.arrow_back, // Back icon
                color: Colors.white,
                size: screenWidth * 0.08,
              ),
            ),
            // Flash button
            IconButton(
              onPressed: () async {
                setState(() {
                  isFlashOn = !isFlashOn; // Toggle flash status
                });
                if (_cameraNotifier.controller != null) {
                  await _cameraNotifier.controller!.setFlashMode(
                    isFlashOn ? FlashMode.torch : FlashMode.off,
                  );
                }
              },
              icon: Icon(
                isFlashOn
                    ? Icons.flash_off
                    : Icons.flash_on, // Change icon based on flash status
                color: Colors.white,
                size: screenWidth * 0.08,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomController(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
        height: 100,
        color: Colors.black.withOpacity(0.6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () {
                // Open Gallery
              },
              icon: Icon(
                Icons.photo_library,
                color: Colors.white,
                size: screenWidth * 0.08,
              ),
            ),
            IconButton(
              onPressed: () {
                widget.onCapturePressed();
              },
              icon: Icon(
                CupertinoIcons.circle_filled,
                color: Colors.white,
                size: screenWidth * 0.15,
              ),
            ),
            // Switch Camera
            IconButton(
              onPressed: () {
                // Stop current camera stream
                _pauseCameraStream();
                currentCameraIndex =
                    (currentCameraIndex + 1) % widget.cameras.length;
                _setupCameraController(widget.cameras[currentCameraIndex]);
              },
              icon: Icon(
                CupertinoIcons.arrow_2_circlepath_circle_fill,
                color: Colors.white,
                size: screenWidth * 0.08,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFocusIndicator(BuildContext context) {
    return Consumer<CameraControllerNotifier>(
        builder: (context, notifier, child) {
      if (notifier.focusPoint == null) {
        return Container(); // Return empty if there's no focus point
      }

      return Positioned(
        left: notifier.focusPoint!.dx -
            25, // Offset by half of the indicator size
        top: notifier.focusPoint!.dy - 25,
        child: Column(
          children: [
            if (notifier.isAutoFocusLocked)
              Icon(
                Icons.lock, // Lock icon when autofocus is locked
                color: Colors.yellow,
                size: 24,
              ),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                border: Border.all(
                    color: Colors.yellow,
                    width: 2), // Yellow border for focus point
              ),
            ),
          ],
        ),
      );
    });
  }
}
