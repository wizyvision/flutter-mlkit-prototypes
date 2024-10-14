import 'dart:async';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

class CameraControllerNotifier extends ChangeNotifier {
  CameraController? _controller;
  double _zoomLevel = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  bool _isAutoFocusLocked = false;
  bool _isBarcodeDetected = false;

  bool _isPaused = false;

  Offset? _focusPoint;
  int? _selectedBarcodeIndex; // Add selected barcode index
  Timer? _tapFocusTimer;

  // New getters for min and max zoom
  double get minZoom => _minZoom;
  double get maxZoom => _maxZoom;
  bool get isPaused => _isPaused;

  Offset? get focusPoint => _focusPoint;
  int? get selectedBarcodeIndex =>
      _selectedBarcodeIndex; // Getter for selected barcode index
  CameraController? get controller => _controller;
  double get zoomLevel => _zoomLevel;
  bool get isAutoFocusLocked => _isAutoFocusLocked;
  bool get isBarcodeDetected => _isBarcodeDetected;

  Future<void> initialize(CameraDescription cameraDescription) async {
    if (_controller != null) return;

    _controller = CameraController(
      cameraDescription,
      ResolutionPreset.high,
    );

    await _controller!.initialize();
    _minZoom = await _controller!.getMinZoomLevel();
    _maxZoom = await _controller!.getMaxZoomLevel();
    notifyListeners();
  }

  void setZoomLevel(double zoom) {
    _zoomLevel = zoom.clamp(_minZoom, _maxZoom);
    _controller?.setZoomLevel(_zoomLevel);
    notifyListeners();
  }

  Future<void> focusOnPoint(Offset position, Size previewSize) async {
    if (_controller == null || _isAutoFocusLocked || _isBarcodeDetected) return;

    _focusPoint = position;
    final offset = Offset(
      position.dx / previewSize.width,
      position.dy / previewSize.height,
    );
    await _controller?.setFocusPoint(offset);
    notifyListeners();

    _tapFocusTimer?.cancel();
    _tapFocusTimer = Timer(Duration(seconds: 2), () {
      _focusPoint = null;
      notifyListeners();
    });
  }

  Future<void> lockFocusOnPoint(Offset position, Size previewSize) async {
    if (_controller == null || _isBarcodeDetected) return;

    _isAutoFocusLocked = true;
    _focusPoint = position;
    final offset = Offset(
      position.dx / previewSize.width,
      position.dy / previewSize.height,
    );
    await _controller?.setFocusPoint(offset);
    notifyListeners();

    _tapFocusTimer?.cancel();
  }

  void togglePause() {
    _isPaused = !_isPaused;
    notifyListeners();
  }

  void onBarcodeTap(int index) {
    _selectedBarcodeIndex = index;
    notifyListeners();
    // Optionally, you might want to also set isBarcodeDetected = true
    _isBarcodeDetected = true; // Indicate that a barcode has been selected
    notifyListeners();
  }

  void toggleAutoFocusLock() {
    _isAutoFocusLocked = !_isAutoFocusLocked;
    if (!_isAutoFocusLocked) {
      _focusPoint = null;
    }
    notifyListeners();
  }

  Future<void> disposeController() async {
    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
      notifyListeners();
    }
  }
}
