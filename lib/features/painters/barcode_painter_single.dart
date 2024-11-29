import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

class BarcodeDetectorPainter extends CustomPainter {
  final List<Barcode> barcodes;
  final Size imageSize;
  final InputImageRotation rotation;
  final CameraLensDirection lensDirection;
  final Barcode? selectedBarcode; // Add selectedBarcode

  BarcodeDetectorPainter(
    this.barcodes,
    this.imageSize,
    this.rotation,
    this.lensDirection, {
    this.selectedBarcode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint rectPaint = Paint()
      ..color = Colors.yellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    final Paint selectedRectPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    for (final barcode in barcodes) {
      final boundingBox = barcode.boundingBox;

      final rect = _normalizeRect(boundingBox, size);

      // Use green for the selected barcode
      final paint =
          (barcode == selectedBarcode) ? selectedRectPaint : rectPaint;

      canvas.drawRect(rect, paint);
    }
  }

  Rect _normalizeRect(Rect boundingBox, Size canvasSize) {
    final scaleX = canvasSize.width / imageSize.width;
    final scaleY = canvasSize.height / imageSize.height;
    return Rect.fromLTRB(
      boundingBox.left * scaleX,
      boundingBox.top * scaleY,
      boundingBox.right * scaleX,
      boundingBox.bottom * scaleY,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
