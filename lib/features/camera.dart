import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gal/gal.dart';
import 'dart:async';

class CameraView extends StatefulWidget {
  const CameraView({super.key});

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
  void dispose() {
    cameraController?.dispose();
    _zoomTimer?.cancel();
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
      return const Center(
        child: CircularProgressIndicator(),
      );
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
          // Convert local position to normalized focus point
          final RenderBox renderBox = context.findRenderObject() as RenderBox;
          Offset localPosition =
              renderBox.globalToLocal(details.globalPosition);
          double normalizedX = localPosition.dx / renderBox.size.width;
          double normalizedY = localPosition.dy / renderBox.size.height;

          // Set the focus at the tapped position
          state.setFocus(Offset(normalizedX, normalizedY));
          _setCameraFocus(normalizedX, normalizedY);

          // If focus is locked, unlock it
          if (state.isFocusLocked) {
            state.unlockFocus();
          }
        },
        onLongPressStart: (details) {
          // Convert local position to normalized focus point
          final RenderBox renderBox = context.findRenderObject() as RenderBox;
          Offset localPosition =
              renderBox.globalToLocal(details.globalPosition);
          double normalizedX = localPosition.dx / renderBox.size.width;
          double normalizedY = localPosition.dy / renderBox.size.height;

          // Lock focus and set the focus point
          state.lockFocus(Offset(normalizedX, normalizedY));
          _setCameraFocus(normalizedX, normalizedY); // Set focus
        },
        onTap: () {
          // Hide the focus square and unlock the focus when tapping outside
          if (cameraState.isFocusLocked) {
            state.unlockFocus(); // Unlock focus
          }
        },
        child: Column(
          children: [
            _buildTopControls(screenWidth),
            Expanded(
              child: AspectRatio(
                aspectRatio: screenWidth / (screenHeight * 0.6),
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
    if (!cameraState.showFocusSquare || cameraState.focusPoint == null)
      return Container();

    return Positioned(
      left: cameraState.focusPoint!.dx * MediaQuery.of(context).size.width - 40,
      top: cameraState.focusPoint!.dy * MediaQuery.of(context).size.height - 40,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          border: Border.all(color: Colors.yellow, width: 2),
        ),
      ),
    );
  }

  Future<void> _setupCameraController() async {
    List<CameraDescription> _cameras = await availableCameras();
    if (_cameras.isNotEmpty) {
      cameraController = CameraController(
        _cameras.first,
        ResolutionPreset.max,
      );
      await cameraController?.initialize();
      cameraState.setZoomLevels(
        await cameraController!.getMinZoomLevel(),
        await cameraController!.getMaxZoomLevel(),
      );
      setState(() {});
    }
  }
}

class CameraState extends ChangeNotifier {
  double zoomLevel = 1.0;
  double minZoomLevel = 1.0;
  double maxZoomLevel = 10.0;
  Offset? focusPoint;
  bool showFocusSquare = false;
  bool isFocusLocked = false;

  void setZoomLevels(double minZoom, double maxZoom) {
    minZoomLevel = minZoom;
    maxZoomLevel = maxZoom;
    notifyListeners();
  }

  void updateZoom(double newZoom) {
    zoomLevel = newZoom.clamp(minZoomLevel, maxZoomLevel);
    notifyListeners();
  }

  void setFocus(Offset position) {
    if (isFocusLocked) return;

    focusPoint = position;
    showFocusSquare = true;
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 800), () {
      showFocusSquare = false;
      notifyListeners();
    });
  }

  void lockFocus(Offset position) {
    isFocusLocked = true;
    focusPoint = position;
    showFocusSquare = true; // Keep the indicator visible while locked
    notifyListeners();
  }

  void unlockFocus() {
    isFocusLocked = false;
    showFocusSquare = false; // Hide the indicator when unlocking
    notifyListeners();
  }
}
