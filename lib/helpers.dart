import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

Rect scaleRectToScreen(Rect boundingBox, Size imageSize, Size widgetSize) {
  // Ensure boundingBox is valid
  if (boundingBox == Rect.zero) {
    return Rect.zero;
  }

  // Calculate the scale based on the image and widget sizes
  double xScale = widgetSize.width / imageSize.width;
  double yScale = widgetSize.height / imageSize.height;

  // Scale the bounding box using both scales
  return Rect.fromLTWH(
    boundingBox.left * xScale,
    boundingBox.top * yScale,
    boundingBox.width * xScale,
    boundingBox.height * yScale,
  );
}

InputImage convertCameraImageToInputImage(
    CameraImage image, InputImageRotation rotation, Size? imageSize) {
  final WriteBuffer allBytes = WriteBuffer();
  for (final Plane plane in image.planes) {
    allBytes.putUint8List(plane.bytes);
  }
  final bytes = allBytes.done().buffer.asUint8List();
  final size = Size(image.width.toDouble(), image.height.toDouble());

  final metadata = InputImageMetadata(
    size: size,
    rotation: rotation,
    format: InputImageFormat.yuv_420_888,
    bytesPerRow: image.planes[0].bytesPerRow,
  );

  return InputImage.fromBytes(bytes: bytes, metadata: metadata);
}
