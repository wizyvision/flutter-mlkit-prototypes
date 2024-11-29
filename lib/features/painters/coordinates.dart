import 'dart:ui';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

double translateX(
  double x,
  Size canvasSize,
  Size imageSize,
  InputImageRotation rotation,
) {
  double translatedX = x * canvasSize.width / imageSize.width;
  print('translateX - Input: $x, Translated: $translatedX');

  switch (rotation) {
    case InputImageRotation.rotation90deg:
      translatedX = canvasSize.height - translatedX; // Flip X axis
      break;
    case InputImageRotation.rotation270deg:
      translatedX = canvasSize.height - translatedX; // Flip X axis
      break;
    case InputImageRotation.rotation180deg:
      translatedX = canvasSize.width - translatedX; // Flip X axis
      break;
    case InputImageRotation.rotation0deg:
    default:
      break;
  }

  print('translateX - Final Translated: $translatedX');
  return translatedX;
}

double translateY(
  double y,
  Size canvasSize,
  Size imageSize,
  InputImageRotation rotation,
) {
  double translatedY = y * canvasSize.height / imageSize.height;
  print('translateY - Input: $y, Translated: $translatedY');

  switch (rotation) {
    case InputImageRotation.rotation90deg:
      translatedY = canvasSize.width - translatedY; // Flip Y axis
      break;
    case InputImageRotation.rotation270deg:
      translatedY = canvasSize.width - translatedY; // Flip Y axis
      break;
    case InputImageRotation.rotation180deg:
      translatedY = canvasSize.height - translatedY; // Flip Y axis
      break;
    case InputImageRotation.rotation0deg:
    default:
      break;
  }

  print('translateY - Final Translated: $translatedY');
  return translatedY;
}
