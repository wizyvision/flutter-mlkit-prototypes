import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

double translateCoordinate(
  double coordinate,
  Size canvasSize,
  Size imageSize,
  InputImageRotation rotation,
  CameraLensDirection cameraLensDirection,
  bool isXAxis, // true if translating x, false for y
) {
  // Check for zero dimensions to prevent division by zero
  if (imageSize.width == 0 || imageSize.height == 0) {
    throw ArgumentError('Image size must not be zero.');
  }
  // Translation logic based on rotation and camera lens direction
  switch (rotation) {
    case InputImageRotation.rotation90deg:
      return isXAxis
          ? coordinate *
              canvasSize.width /
              (Platform.isIOS ? imageSize.width : imageSize.height)
          : coordinate *
              canvasSize.height /
              (Platform.isIOS ? imageSize.height : imageSize.width);
    case InputImageRotation.rotation270deg:
      return isXAxis
          ? canvasSize.width -
              coordinate *
                  canvasSize.width /
                  (Platform.isIOS ? imageSize.width : imageSize.height)
          : coordinate *
              canvasSize.height /
              (Platform.isIOS ? imageSize.height : imageSize.width);
    case InputImageRotation.rotation0deg:
    case InputImageRotation.rotation180deg:
      return isXAxis
          ? (cameraLensDirection == CameraLensDirection.back
              ? coordinate * canvasSize.width / imageSize.width
              : canvasSize.width -
                  coordinate * canvasSize.width / imageSize.width)
          : coordinate * canvasSize.height / imageSize.height;
  }
}

// Now you can use the helper function like this:
double translateX(double x, Size canvasSize, Size imageSize,
    InputImageRotation rotation, CameraLensDirection cameraLensDirection) {
  return translateCoordinate(
      x, canvasSize, imageSize, rotation, cameraLensDirection, true);
}

double translateY(double y, Size canvasSize, Size imageSize,
    InputImageRotation rotation, CameraLensDirection cameraLensDirection) {
  return translateCoordinate(
      y, canvasSize, imageSize, rotation, cameraLensDirection, false);
}
