import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'coordinates_translator.dart';

class BarcodeDetectorPainter extends CustomPainter {
  BarcodeDetectorPainter(
    this.barcodes,
    this.imageSize,
    this.rotation,
    this.cameraLensDirection,
    this.selectedBarcodeIndex,
    this.onTap, // Change the type to accept an int
  );

  final List<Barcode> barcodes;
  final Size imageSize;
  final InputImageRotation rotation;
  final CameraLensDirection cameraLensDirection;
  final int? selectedBarcodeIndex;
  final Function(int) onTap; // Change to accept int index

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..style = PaintingStyle.stroke;

    for (int x = 0; x < barcodes.length; x++) {
      // Set the color of the box (green if selected, otherwise yellow)
      paint.color = x == selectedBarcodeIndex ? Colors.green : Colors.yellow;
      paint.strokeWidth = x == selectedBarcodeIndex ? 6.0 : 3.0;

      Barcode barcode = barcodes[x];

      final left = translateX(
        barcode.boundingBox.left,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      final top = translateY(
        barcode.boundingBox.top,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      final right = translateX(
        barcode.boundingBox.right,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      final bottom = translateY(
        barcode.boundingBox.bottom,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );

      // Draw the bounding box of the barcode
      canvas.drawRect(
        Rect.fromLTRB(left, top, right, bottom),
        paint,
      );

      // Draw the barcode text above the bounding box if available
      final textPainter = TextPainter(
        text: TextSpan(
          text: barcode.displayValue ?? 'Unknown',
          style: const TextStyle(color: Colors.lightGreenAccent, fontSize: 16),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(left, top - 20), // Position the text above the bounding box
      );
    }
  }

  @override
  bool shouldRepaint(BarcodeDetectorPainter oldDelegate) {
    return oldDelegate.imageSize != imageSize ||
        oldDelegate.barcodes != barcodes ||
        oldDelegate.selectedBarcodeIndex != selectedBarcodeIndex;
  }

  // Method to detect taps and return the barcode index
  void checkTap(Offset tapPosition) {
    for (int i = 0; i < barcodes.length; i++) {
      Barcode barcode = barcodes[i];
      final left = translateX(
        barcode.boundingBox.left,
        imageSize,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      final top = translateY(
        barcode.boundingBox.top,
        imageSize,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      final right = translateX(
        barcode.boundingBox.right,
        imageSize,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      final bottom = translateY(
        barcode.boundingBox.bottom,
        imageSize,
        imageSize,
        rotation,
        cameraLensDirection,
      );

      // Check if the tap position is inside the bounding box
      if (Rect.fromLTRB(left, top, right, bottom).contains(tapPosition)) {
        onTap(i); // Notify parent about the selected barcode index
        break;
      }
    }
  }
}
