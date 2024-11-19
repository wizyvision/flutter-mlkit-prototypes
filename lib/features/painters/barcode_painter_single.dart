import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'coordinates_translator.dart';

class BarcodeSinglePainter extends CustomPainter {
  BarcodeSinglePainter(
    this.barcodes,
    this.imageSize,
    this.rotation,
    this.cameraLensDirection,
    this.selectedBarcodeIndex,
    this.onTap,
  );

  final List<Barcode> barcodes;
  final Size imageSize;
  final InputImageRotation rotation;
  final CameraLensDirection cameraLensDirection;
  final int? selectedBarcodeIndex;
  final Function(int) onTap;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint rectPaint = Paint()..style = PaintingStyle.stroke;
    final Paint circlePaint = Paint()..style = PaintingStyle.fill;

    for (int x = 0; x < barcodes.length; x++) {
      Barcode barcode = barcodes[x];

      // Set the color of the rectangle and circle (green if selected, otherwise yellow)
      Color color = x == selectedBarcodeIndex ? Colors.green : Colors.yellow;
      rectPaint.color = color;
      circlePaint.color = color;

      // Calculate the bounding box coordinates
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

      // Draw the bounding box of the barcode with increased stroke width for visibility
      rectPaint.strokeWidth = 6.0; // Increased stroke width
      canvas.drawRect(
        Rect.fromLTRB(left, top, right, bottom),
        rectPaint,
      );

      // Calculate the center position of the barcode for the circle
      final centerX = translateX(
        barcode.boundingBox.left + (barcode.boundingBox.width / 2),
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      final centerY = translateY(
        barcode.boundingBox.top + (barcode.boundingBox.height / 2),
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );

      // Draw the circular indicator for the barcode
      canvas.drawCircle(
        Offset(centerX, centerY),
        30.0, // Radius of the circle
        circlePaint,
      );

      // Draw the barcode index (1, 2, 3, ...) inside the circle
      final textPainter = TextPainter(
        text: TextSpan(
          text: (x + 1).toString(), // Display the index as 1, 2, 3, ...
          style: const TextStyle(
              color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      final textOffset = Offset(
          centerX - textPainter.width / 2, centerY - textPainter.height / 2);
      textPainter.paint(canvas, textOffset);
    }
  }

  @override
  bool shouldRepaint(BarcodeSinglePainter oldDelegate) {
    return oldDelegate.imageSize != imageSize ||
        oldDelegate.barcodes != barcodes ||
        oldDelegate.selectedBarcodeIndex != selectedBarcodeIndex;
  }

  // Method to detect taps and return the barcode index
  void checkTap(Offset tapPosition) {
    for (int i = 0; i < barcodes.length; i++) {
      Barcode barcode = barcodes[i];
      final centerX = translateX(
        barcode.boundingBox.left + (barcode.boundingBox.width / 2),
        imageSize,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      final centerY = translateY(
        barcode.boundingBox.top + (barcode.boundingBox.height / 2),
        imageSize,
        imageSize,
        rotation,
        cameraLensDirection,
      );

      // Check if the tap position is within the circle
      if ((tapPosition - Offset(centerX, centerY)).distance <= 30.0) {
        onTap(i); // Notify parent about the selected barcode index
        break;
      }

      // Check if the tap position is inside the rectangle as well
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
