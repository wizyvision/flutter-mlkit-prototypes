import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gal/gal.dart';
import 'dart:async';

class CameraView extends StatefulWidget {
  final Function(XFile picture) onImageCaptured;
  final Function(CameraImage image) onCameraImage;
  final Widget? overlay;

  const CameraView({
    super.key,
    required this.onImageCaptured,
    required this.onCameraImage,
    this.overlay,
  });

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> with WidgetsBindingObserver {
  List<CameraDescription> cameras = [];
  CameraController? cameraController;
  final CameraState cameraState = CameraState();
  double _baseZoom = 1.0;
  Timer? _zoomTimer;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      cameraController?.dispose();
      cameraController = null; // Prevent reusing the disposed controller
    } else if (state == AppLifecycleState.resumed) {
      _setupCameraController(); // Reinitialize the camera controller
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupCameraController();
  }

  @override
  void dispose() {
    cameraController?.dispose();
    _zoomTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: ChangeNotifierProvider(
        create: (_) => cameraState,
        child: Consumer<CameraState>(
          builder: (context, state, _) {
            return Stack(
              children: [
                _buildUI(screenHeight, screenWidth, state),
                if (widget.overlay != null) widget.overlay!,
                _buildFocusSquare(),
                _buildZoomIndicator(screenHeight),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildUI(double screenHeight, double screenWidth, CameraState state) {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: GestureDetector(
        onScaleStart: (details) {
          _baseZoom = cameraState.zoomLevel;
        },
        onScaleUpdate: (details) {
          double zoomFactor = (_baseZoom * details.scale).clamp(
            cameraState.minZoomLevel,
            cameraState.maxZoomLevel,
          );
          cameraState.updateZoom(zoomFactor);

          if (_zoomTimer == null || !_zoomTimer!.isActive) {
            _zoomTimer = Timer(const Duration(milliseconds: 50), () async {
              await cameraController?.setZoomLevel(zoomFactor);
            });
          }
        },
        onTapDown: (TapDownDetails details) {
          final RenderBox renderBox = context.findRenderObject() as RenderBox;
          Offset localPosition =
              renderBox.globalToLocal(details.globalPosition);

          // Define bounds for CameraPreview area
          double previewHeight = screenHeight * 0.6;
          double topLimit = (screenHeight - previewHeight) / 2;
          double bottomLimit = topLimit + previewHeight;

          // Only proceed if tap is within CameraPreview area
          if (localPosition.dy >= topLimit && localPosition.dy <= bottomLimit) {
            double normalizedX = localPosition.dx / renderBox.size.width;
            double normalizedY = (localPosition.dy - topLimit) / previewHeight;

            state.setFocus(Offset(normalizedX, normalizedY));
            _setCameraFocus(normalizedX, normalizedY);

            // Show focus indicator and set timer to hide it after tapping elsewhere
            state.showFocusIndicator();
            Future.delayed(const Duration(seconds: 1), () {
              if (!state.isFocusLocked) {
                state.hideFocusIndicator();
              }
            });
          } else {
            // If tapping outside, hide the focus indicator
            if (state.showFocusSquare) {
              state.hideFocusIndicator();
            }
          }
        },
        onLongPressStart: (details) {
          final RenderBox renderBox = context.findRenderObject() as RenderBox;
          Offset localPosition =
              renderBox.globalToLocal(details.globalPosition);

          double previewHeight = screenHeight * 0.6;
          double topLimit = (screenHeight - previewHeight) / 2;
          double bottomLimit = topLimit + previewHeight;

          // Only lock focus if long press is within CameraPreview area
          if (localPosition.dy >= topLimit && localPosition.dy <= bottomLimit) {
            double normalizedX = localPosition.dx / renderBox.size.width;
            double normalizedY = (localPosition.dy - topLimit) / previewHeight;

            state.lockFocus(Offset(normalizedX, normalizedY));
            _setCameraFocus(normalizedX, normalizedY);

            // Show focus indicator and set timer to hide it after a delay
            state.showFocusIndicator();
          }
        },
        child: Column(
          children: [
            _buildTopControls(screenWidth),
            Expanded(
              child: AspectRatio(
                aspectRatio: cameraController!.value.aspectRatio,
                child: CameraPreview(cameraController!),
              ),
            ),
            _buildBottomControls(screenHeight, screenWidth),
          ],
        ),
      ),
    );
  }

  void _setCameraFocus(double normalizedX, double normalizedY) {
    cameraController?.setFocusMode(FocusMode.auto);
    cameraController?.setFocusPoint(Offset(normalizedX, normalizedY));
  }

  Widget _buildTopControls(double screenWidth) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      height: 80,
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
              Icons.flash_on,
              color: Colors.white,
              size: screenWidth * 0.08,
            ),
            onPressed: () {
              // Toggle flash functionality here
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(double screenHeight, double screenWidth) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(16.0),
      height: screenHeight * 0.25,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
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
              XFile picture = await cameraController!.takePicture();
              widget.onImageCaptured(
                  picture); // Call the callback with the captured image
              Gal.putImage(picture.path); // Save the image to gallery
            },
            iconSize: screenWidth * 0.22,
            icon: const Icon(
              CupertinoIcons.circle_filled,
              color: Colors.white,
            ),
          ),
          IconButton(
            onPressed: () {
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
    );
  }

  Widget _buildZoomIndicator(double screenHeight) {
    return Positioned(
      bottom: screenHeight * 0.30, // Above camera controls
      right: 10,
      child: Column(
        children: [
          Text(
            '${cameraState.zoomLevel.toStringAsFixed(1)}x',
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
          Slider(
            value: cameraState.zoomLevel,
            min: cameraState.minZoomLevel,
            max: cameraState.maxZoomLevel,
            activeColor: Colors.white,
            inactiveColor: Colors.grey,
            onChanged: (value) async {
              cameraState.updateZoom(value);
              await cameraController?.setZoomLevel(value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFocusSquare() {
    if (!cameraState.showFocusSquare) return const SizedBox.shrink();

    return Positioned(
      left: cameraState.focusPoint.dx - 35,
      top: cameraState.focusPoint.dy - 35,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.yellow, width: 2),
          shape: BoxShape.rectangle,
        ),
      ),
    );
  }

  void _setupCameraController() async {
    if (cameras.isEmpty) {
      cameras = await availableCameras();
    }
    if (cameraController != null) return;

    cameraController = CameraController(cameras[0], ResolutionPreset.high);
    await cameraController?.initialize();
    setState(() {});

    cameraController?.startImageStream((CameraImage image) {
      widget.onCameraImage(image); // Call the callback with the camera image
    });
  }
}

class CameraState with ChangeNotifier {
  double zoomLevel = 1.0;
  double minZoomLevel = 1.0;
  double maxZoomLevel = 8.0;
  Offset focusPoint = Offset(0.5, 0.5);
  bool showFocusSquare = false;
  bool isFocusLocked = false;

  void updateZoom(double value) {
    zoomLevel = value;
    notifyListeners();
  }

  void setFocus(Offset point) {
    focusPoint = point;
    showFocusSquare = true;
    notifyListeners();
  }

  void showFocusIndicator() {
    showFocusSquare = true;
    notifyListeners();
  }

  void hideFocusIndicator() {
    showFocusSquare = false;
    notifyListeners();
  }

  void lockFocus(Offset point) {
    isFocusLocked = true;
    focusPoint = point;
    notifyListeners();
  }
}
