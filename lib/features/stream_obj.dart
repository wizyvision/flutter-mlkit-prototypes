import 'dart:io';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

import 'painters/coordinates_translator.dart';

class StreamObjScreen extends StatefulWidget {
  @override
  _StreamObjScreenState createState() => _StreamObjScreenState();
}

class _StreamObjScreenState extends State<StreamObjScreen> {
  CameraController? _cameraController;
  bool _isDetecting = false;
  List<DetectedObject>? _detectedObjects;
  Size? _imageSize;

  final ObjectDetector objectDetector = ObjectDetector(
    options: ObjectDetectorOptions(
      mode: DetectionMode.stream,
      classifyObjects: true,
      multipleObjects: true,
    ),
  );

  int _cameraIndex = 0;
  List<CameraDescription> _cameras = [];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    final camera = _cameras[_cameraIndex];

    _cameraController = CameraController(
      camera,
      ResolutionPreset.high,
    );

    try {
      await _cameraController!.initialize();

      _cameraController!.startImageStream((CameraImage image) {
        if (!_isDetecting) {
          _isDetecting = true;
          final inputImage = _inputImageFromCamera(image);
          if (inputImage != null) {
            _processImage(inputImage);
          } else {
            _isDetecting = false;
          }
        }
      });

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print("Camera initialization error: $e");
    }
  }

  Uint8List _cameraImageToBytes(CameraImage image) {
    final WriteBuffer allBytes = WriteBuffer();
    for (Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }

  InputImageMetadata? _cachedMetadata;

  InputImageMetadata _createImageMetadata(CameraImage image) {
    if (_cachedMetadata == null || image.width != _cachedMetadata!.size.width) {
      final imageRotation = InputImageRotationValue.fromRawValue(
              _cameras[_cameraIndex].sensorOrientation) ??
          InputImageRotation.rotation0deg;
      final inputImageFormat =
          InputImageFormatValue.fromRawValue(image.format.raw) ??
              InputImageFormat.nv21;
      _cachedMetadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: image.planes[0].bytesPerRow,
      );
    }
    return _cachedMetadata!;
  }

  InputImage? _inputImageFromCamera(CameraImage image) {
    final bytes = _cameraImageToBytes(image);
    return InputImage.fromBytes(
      bytes: bytes,
      metadata: _createImageMetadata(image),
    );
  }

  Future<void> _processImage(InputImage inputImage) async {
    try {
      final List<DetectedObject> objects =
          await objectDetector.processImage(inputImage);

      if (objects.isEmpty) {
        print("No objects detected");
      }

      if (mounted) {
        setState(() {
          _detectedObjects = objects;
          _imageSize = inputImage.metadata?.size;
        });
      }
    } catch (e) {
      print("Error processing image: $e");
    } finally {
      _isDetecting = false;
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    objectDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Object Detection (Stream)')),
      body: _cameraController == null
          ? Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                CameraPreview(_cameraController!),
                if (_detectedObjects != null && _imageSize != null)
                  CustomPaint(
                    size: Size(
                      _cameraController!.value.previewSize!.width,
                      _cameraController!.value.previewSize!.height,
                    ),
                    painter: ObjectDetectorPainter(
                      _detectedObjects!,
                      _imageSize!,
                      InputImageRotationValue.fromRawValue(
                              _cameras[_cameraIndex].sensorOrientation) ??
                          InputImageRotation.rotation0deg,
                      _cameras[_cameraIndex].lensDirection,
                    ),
                  ),
              ],
            ),
    );
  }
}

class ObjectDetectorPainter extends CustomPainter {
  ObjectDetectorPainter(
    this._objects,
    this.imageSize,
    this.rotation,
    this.cameraLensDirection,
  );

  final List<DetectedObject> _objects;
  final Size imageSize;
  final InputImageRotation rotation;
  final CameraLensDirection cameraLensDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.lightGreenAccent;

    final Paint background = Paint()..color = Color(0x99000000);

    for (final DetectedObject detectedObject in _objects) {
      final ParagraphBuilder builder = ParagraphBuilder(
        ParagraphStyle(
            textAlign: TextAlign.left,
            fontSize: 16,
            textDirection: TextDirection.ltr),
      );
      builder.pushStyle(
          ui.TextStyle(color: Colors.lightGreenAccent, background: background));

      if (detectedObject.labels.isNotEmpty) {
        final label = detectedObject.labels
            .reduce((a, b) => a.confidence > b.confidence ? a : b);
        builder.addText('${label.text} ${label.confidence}\n');
      } else {
        // Display "null" for objects not identified
        builder.addText('null\n');
      }
      builder.pop();

      final left = translateX(
        detectedObject.boundingBox.left,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      final top = translateY(
        detectedObject.boundingBox.top,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      final right = translateX(
        detectedObject.boundingBox.right,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      final bottom = translateY(
        detectedObject.boundingBox.bottom,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );

      // Draw the bounding box
      canvas.drawRect(
        Rect.fromLTRB(left, top, right, bottom),
        paint,
      );

      // Draw the label
      canvas.drawParagraph(
        builder.build()
          ..layout(ParagraphConstraints(
            width: (right - left).abs(),
          )),
        Offset(
            Platform.isAndroid &&
                    cameraLensDirection == CameraLensDirection.front
                ? right
                : left,
            top),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
