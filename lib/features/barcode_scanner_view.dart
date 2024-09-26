import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:ml_kit_implementation/features/painters/barcode_detector_painter.dart';
import 'camera_view.dart';

class BarcodeScannerView extends StatefulWidget {
  const BarcodeScannerView({Key? key}) : super(key: key);

  @override
  State<BarcodeScannerView> createState() => _BarcodeScannerViewState();
}

class _BarcodeScannerViewState extends State<BarcodeScannerView> {
  final BarcodeScanner _barcodeScanner = BarcodeScanner();
  String? _barcodeText;
  CustomPaint? _customPaint;
  bool _canProcess = true;
  bool _isBusy = false;

  @override
  void dispose() {
    _barcodeScanner.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Barcode Scanner')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraView(onImage: _processImage),
          if (_customPaint != null)
            _customPaint!, // Display the barcode painter
        ],
      ),
    );
  }

  Future<void> _processImage(InputImage inputImage) async {
    if (!_canProcess || _isBusy) return;
    _isBusy = true;

    // Check if inputImage is valid
    if (inputImage == null) {
      print('InputImage is null, skipping processing');
      _isBusy = false;
      return;
    }

    try {
      // Process the image with the barcode scanner
      final barcodes = await _barcodeScanner.processImage(inputImage);
      if (barcodes.isNotEmpty) {
        setState(() {
          _barcodeText = barcodes.first.rawValue; // Capture the first barcode
          _showBarcodeResultDialog(
              _barcodeText!); // Show the result in a dialog
        });
      }

      // Check if metadata is not null and its properties are accessible
      final metadata = inputImage.metadata;
      if (metadata != null) {
        final size = metadata.size;
        final rotation = metadata.rotation;

        // Ensure size and rotation are valid before using them
        if (size != null && rotation != null) {
          // Create a painter to show barcode bounding boxes
          final painter = BarcodeDetectorPainter(
            barcodes,
            size,
            rotation,
            CameraLensDirection.back, // Adjust based on your camera direction
          );

          setState(() {
            _customPaint = CustomPaint(painter: painter);
          });
        }
      }
    } catch (e) {
      print(
          'Error processing image: $e'); // Catch and log any errors during processing
    } finally {
      _isBusy = false;
    }
  }

  Future<void> _showBarcodeResultDialog(String barcode) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Barcode Result'),
          content: Text('Scanned Barcode: $barcode'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _barcodeText = null; // Reset after showing the dialog
                  _customPaint =
                      null; // Clear the painter after showing the dialog
                });
              },
            ),
          ],
        );
      },
    );
  }
}
