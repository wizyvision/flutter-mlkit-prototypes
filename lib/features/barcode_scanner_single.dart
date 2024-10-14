import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'cameranew.dart'; // Your CameraNewView implementation
import 'painters/barcode_painter_single.dart'; // Your BarcodeSinglePainter implementation

class BarcodeSingleView extends StatefulWidget {
  final List<CameraDescription> cameras;

  const BarcodeSingleView({
    Key? key,
    required this.cameras,
  }) : super(key: key);

  @override
  _BarcodeSingleViewState createState() => _BarcodeSingleViewState();
}

class _BarcodeSingleViewState extends State<BarcodeSingleView> {
  List<Barcode> _barcodes = [];
  int? _selectedBarcodeIndex;
  bool _isPaused = false;
  Size _cameraPreviewSize = Size.zero;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CameraNewView(
            cameras: widget.cameras,
            onImage: _processCameraImage,
            isPaused: _isPaused,
            onSizeChanged: (size) {
              setState(() {
                _cameraPreviewSize = size; // Update the preview size
              });
            },
          ),
          if (_barcodes.isNotEmpty && _cameraPreviewSize != Size.zero)
            GestureDetector(
              onTapDown: (details) {
                final tapPosition = details.localPosition;
                // Create an instance of the painter to check the tap
                final painter = BarcodeSinglePainter(
                  _barcodes,
                  _cameraPreviewSize, // Use the actual camera preview size
                  InputImageRotationValue.fromRawValue(0) ??
                      InputImageRotation.rotation0deg,
                  CameraLensDirection.back,
                  _selectedBarcodeIndex,
                  _onBarcodeTap,
                );

                // Check for a tap within the barcode bounding boxes
                painter.checkTap(tapPosition);
              },
              child: CustomPaint(
                painter: BarcodeSinglePainter(
                  _barcodes,
                  _cameraPreviewSize, // Use the actual camera preview size
                  InputImageRotationValue.fromRawValue(0) ??
                      InputImageRotation.rotation0deg,
                  CameraLensDirection.back,
                  _selectedBarcodeIndex,
                  _onBarcodeTap,
                ),
                child: Container(),
              ),
            ),
        ],
      ),
    );
  }

  void _processCameraImage(
      InputImage inputImage, CameraController controller) async {
    final barcodeScanner = BarcodeScanner(); // Initialize your barcode scanner
    final List<Barcode> barcodes =
        await barcodeScanner.processImage(inputImage);

    setState(() {
      _barcodes = barcodes; // Update the barcodes list
      _selectedBarcodeIndex = null; // Reset selection on new image
    });
  }

  void _onBarcodeTap(int index) {
    setState(() {
      _selectedBarcodeIndex = index; // Update selected barcode index on tap
    });
    final Barcode barcode = _barcodes[index];
    // Show dialog with scanned barcode details
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Scanned Barcode'),
        content: Text('Value: ${barcode.displayValue}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
