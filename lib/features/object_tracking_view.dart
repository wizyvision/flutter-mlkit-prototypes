import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

class BarcodeScannerView extends StatefulWidget {
  final List<CameraDescription> cameras;

  BarcodeScannerView({Key? key, required this.cameras}) : super(key: key);

  @override
  _BarcodeScannerViewState createState() => _BarcodeScannerViewState();
}

class _BarcodeScannerViewState extends State<BarcodeScannerView> {
  CameraController? _cameraController;
  Future<void>? _initializeControllerFuture;
  BarcodeScanner _barcodeScanner = BarcodeScanner();
  String _scannedBarcode = "";
  bool _isScanning = false;
  Color _frameColor = Colors.white; // Default frame color

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    var status = await Permission.camera.request();
    if (status.isGranted) {
      _cameraController = CameraController(
        widget.cameras[0],
        ResolutionPreset.high,
      );

      _initializeControllerFuture = _cameraController?.initialize();

      // Wait until the camera is initialized before starting the image stream
      await _initializeControllerFuture;

      setState(() {});

      // Start image stream for barcode scanning
      _cameraController?.startImageStream((CameraImage image) {
        if (_isScanning) return; // Prevent multiple scans
        _isScanning = true; // Set scanning to true
        _scanBarcode(image); // Process the image for barcode
      });
    } else {
      _showPermissionDeniedDialog();
    }
  }

  Future<void> _scanBarcode(CameraImage cameraImage) async {
    final inputImage = _inputImageFromCamera(cameraImage);

    if (inputImage == null) {
      setState(() {
        _scannedBarcode = "Image processing failed"; // Update message
        _frameColor = Colors.red; // Change frame color to red
      });
      return;
    }

    // Scan barcodes
    final List<Barcode> barcodes =
        await _barcodeScanner.processImage(inputImage);

    if (barcodes.isNotEmpty) {
      setState(() {
        _scannedBarcode = barcodes.first.displayValue ?? "No barcode detected";
        _frameColor = Colors.green; // Change frame color to green
      });
    } else {
      setState(() {
        _scannedBarcode = "No barcode detected"; // Update message
        _frameColor = Colors.red; // Change frame color to red
      });
    }
    // Delay before next scan
    await Future.delayed(Duration(seconds: 2));
    _isScanning = false; // Reset scanning flag
  }

  Uint8List _cameraImageToBytes(CameraImage image) {
    final WriteBuffer allBytes = WriteBuffer();
    for (Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }

  InputImage? _inputImageFromCamera(CameraImage image) {
    final bytes = _cameraImageToBytes(image);

    final imageRotation = InputImageRotationValue.fromRawValue(
            widget.cameras[0].sensorOrientation) ??
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
        bytesPerRow:
            image.planes[0].bytesPerRow, // Use the first plane's bytesPerRow
      ),
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Camera Permission Denied'),
          content: Text('Please grant camera permission to use this feature.'),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _barcodeScanner.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            CameraPreviewWidget(
                cameraController: _cameraController,
                initializeControllerFuture: _initializeControllerFuture),
            BarcodeFrame(frameColor: _frameColor), // Pass the frame color
            BottomTooltip(scannedBarcode: _scannedBarcode),
          ],
        ),
      ),
    );
  }
}

// Camera Preview Widget
class CameraPreviewWidget extends StatelessWidget {
  final CameraController? cameraController;
  final Future<void>? initializeControllerFuture;

  const CameraPreviewWidget({
    Key? key,
    required this.cameraController,
    required this.initializeControllerFuture,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return ClipRect(
            child: OverflowBox(
              child: CameraPreview(cameraController!),
            ),
          );
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}

// Barcode Frame Widget
class BarcodeFrame extends StatelessWidget {
  final Color frameColor;

  const BarcodeFrame({Key? key, required this.frameColor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final double frameWidth = screenSize.width * 0.75; // 75% of screen width
    final double frameHeight =
        frameWidth * 0.4; // Aspect ratio of 1.875:1 for barcode frame

    return Center(
      child: Container(
        width: frameWidth,
        height: frameHeight,
        decoration: BoxDecoration(
          border: Border.all(
              color: frameColor, width: 2), // Use dynamic frame color
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

// Bottom Tooltip Widget
class BottomTooltip extends StatelessWidget {
  final String scannedBarcode;

  const BottomTooltip({Key? key, required this.scannedBarcode})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 50,
      left: 16,
      right: 16,
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            scannedBarcode,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
