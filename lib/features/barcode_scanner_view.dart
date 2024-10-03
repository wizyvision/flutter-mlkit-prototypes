import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:ml_kit_implementation/features/painters/barcode_detector_painter.dart';
import 'package:ml_kit_implementation/helpers.dart';
import 'camera.dart'; // Import your CameraView from camera.dart

class BarcodeScannerView extends StatefulWidget {
  @override
  _BarcodeScannerViewState createState() => _BarcodeScannerViewState();
}

class _BarcodeScannerViewState extends State<BarcodeScannerView> {
  late BarcodeScanner barcodeScanner;
  bool _isProcessing = false;
  bool _isModalVisible = false;
  List<Barcode> _detectedBarcodes = [];
  Barcode? _selectedBarcode;
  Size? _imageSize;
  InputImageRotation _imageRotation = InputImageRotation.rotation0deg;
  CameraLensDirection _cameraLensDirection = CameraLensDirection.back;

  @override
  void initState() {
    super.initState();
    _initializeBarcodeScanner();
  }

  void _initializeBarcodeScanner() {
    barcodeScanner = BarcodeScanner();
  }

  @override
  void dispose() {
    barcodeScanner.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final cameraPreviewHeight =
        screenHeight * 0.6; // Fixed height for CameraPreview

    return Stack(
      children: [
        // CameraView as the background
        CameraView(
          onImageCaptured: (XFile picture) {
            // Optional: Handle image capture
          },
          onCameraImage: (CameraImage image) {
            if (!_isProcessing && !_isModalVisible) {
              _isProcessing = true;
              _processCameraImage(image);
            }
          },
        ),
        // Use Positioned to control the placement of the barcode painter
        if (_detectedBarcodes.isNotEmpty && _imageSize != null)
          Positioned(
            top: (screenHeight - cameraPreviewHeight) / 2, // Center vertically
            left: 0,
            child: GestureDetector(
              onTapUp: (details) {
                _onTapBarcode(details.localPosition, context);
              },
              child: CustomPaint(
                size: Size(screenWidth,
                    cameraPreviewHeight), // Match the camera preview dimensions
                painter: BarcodePainter(
                  barcodes: _detectedBarcodes,
                  imageSize: _imageSize!,
                  selectedBarcode: _selectedBarcode,
                  rotation: _imageRotation,
                  cameraLensDirection: _cameraLensDirection,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _onTapBarcode(Offset localPosition, BuildContext context) {
    for (var barcode in _detectedBarcodes) {
      final rect = scaleRectToScreen(
        barcode.boundingBox,
        _imageSize!,
        Size(MediaQuery.of(context).size.width,
            MediaQuery.of(context).size.height),
      );

      // Check if the tap position is within the barcode rectangle
      if (rect.contains(localPosition)) {
        setState(() {
          _selectedBarcode = barcode; // Set selected barcode
        });

        _showScanAnimation(barcode);
        break; // Exit loop after selecting a barcode
      }
    }
  }

  void _showScanAnimation(Barcode barcode) {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _selectedBarcode != null) {
        _showResultModal(_selectedBarcode!.displayValue ?? 'No result');
      }
    });
  }

  void _processCameraImage(CameraImage image) async {
    try {
      InputImage inputImage = convertCameraImageToInputImage(
        image,
        _imageRotation,
        _imageSize,
      );

      final List<Barcode> barcodes =
          await barcodeScanner.processImage(inputImage);

      if (mounted) {
        setState(() {
          _detectedBarcodes = barcodes;
          _imageSize = Size(image.width.toDouble(), image.height.toDouble());
        });
      }
    } catch (e) {
      print('Error processing camera image: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showResultModal(String result) {
    _isModalVisible = true;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Barcode Result'),
          content: Text(result),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _isModalVisible = false;
                  _selectedBarcode = null; // Clear selected barcode
                });
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
