import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:ml_kit_implementation/helpers.dart';

class BarcodePainter extends CustomPainter {
  BarcodePainter({
    required this.barcodes,
    required this.imageSize,
    required this.rotation,
    required this.cameraLensDirection,
    this.selectedBarcode,
  });

  final List<Barcode> barcodes;
  final Size imageSize;
  final InputImageRotation rotation;
  final CameraLensDirection cameraLensDirection;
  final Barcode? selectedBarcode;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint normalPaint = Paint()
      ..color = Colors.yellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final Paint selectedPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    for (final Barcode barcode in barcodes) {
      final Rect barcodeRect = scaleRectToScreen(
        barcode.boundingBox,
        imageSize,
        size,
      );

      final Paint paintToUse =
          barcode == selectedBarcode ? selectedPaint : normalPaint;

      // Draw barcode rectangle
      canvas.drawRect(
        barcodeRect,
        paintToUse,
      );

      // Draw barcode text
      final ParagraphBuilder builder = ParagraphBuilder(
        ParagraphStyle(
          textAlign: TextAlign.left,
          fontSize: 16,
          textDirection: TextDirection.ltr,
        ),
      );
      builder.pushStyle(ui.TextStyle(color: Colors.lightGreenAccent));
      builder.addText('${barcode.displayValue}');
      builder.pop();

      final double left = barcodeRect.left;
      final double top = barcodeRect.top;

      // Draw text above the barcode
      canvas.drawParagraph(
        builder.build()..layout(ParagraphConstraints(width: barcodeRect.width)),
        Offset(left, top - 20),
      );

      // // Draw corner points as small circles
      // final List<Offset> cornerPoints =
      //     barcode.cornerPoints.map((Point<int> point) {
      //   return Offset(
      //     translateX(point.x.toDouble(), size, imageSize, rotation,
      //         cameraLensDirection),
      //     translateY(point.y.toDouble(), size, imageSize, rotation,
      //         cameraLensDirection),
      //   );
      // }).toList();

      // // Draw corner points as small circles
      // final Paint cornerPointPaint = Paint()
      //   ..color = Colors.red
      //   ..style = PaintingStyle.fill;

      // for (final Offset point in cornerPoints) {
      //   canvas.drawCircle(point, 4.0, cornerPointPaint);
      // }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }

  double translateX(double x, Size canvasSize, Size imageSize,
      InputImageRotation rotation, CameraLensDirection cameraLensDirection) {
    if (rotation == InputImageRotation.rotation90deg) {
      return x * canvasSize.height / imageSize.width;
    } else if (rotation == InputImageRotation.rotation270deg) {
      return canvasSize.width - (x * canvasSize.height / imageSize.width);
    }
    return x * canvasSize.width / imageSize.width;
  }

  double translateY(double y, Size canvasSize, Size imageSize,
      InputImageRotation rotation, CameraLensDirection cameraLensDirection) {
    if (rotation == InputImageRotation.rotation90deg ||
        rotation == InputImageRotation.rotation270deg) {
      return y * canvasSize.width / imageSize.height;
    }
    return y * canvasSize.height / imageSize.height;
  }
}
