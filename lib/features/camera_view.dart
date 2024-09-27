import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
// import 'package:text_scanner/enums.dart';

class CameraStreamView extends StatefulWidget {
  final List<CameraDescription> cameras;

  final Function(InputImage inputImage) onImage;
  final VoidCallback? onCameraFeedReady;
  final CameraLensDirection? initialCameraLensDirection;
  final CustomPaint? customPaint;

  const CameraStreamView({
    super.key,
    required this.cameras,
    required this.onImage,
    this.onCameraFeedReady,
    this.initialCameraLensDirection = CameraLensDirection.back,
    this.customPaint,
  });

  @override
  State<CameraStreamView> createState() => _CameraStreamViewState();
}

class _CameraStreamViewState extends State<CameraStreamView> {
  late CameraController _cameraController;

  int _cameraIndex = -1;

  void initCamera() {
    for (var i = 0; i < widget.cameras.length; i++) {
      if (widget.cameras[i].lensDirection ==
          widget.initialCameraLensDirection) {
        _cameraIndex = i;
        break;
      }
    }
    if (_cameraIndex != -1) {
      _startLiveFeed(widget.cameras[0]);
    }
  }

  @override
  Widget build(BuildContext context) {
    // return Scaffold(
    //   appBar: AppBar(
    //     backgroundColor: Theme.of(context).colorScheme.inversePrimary,
    //     title: const Text('Camera'),
    //   ),
    //   body: _liveFeedBody(),
    // );

    if (_cameraController.value.isInitialized == false) return Container();

    return Stack(
      children: <Widget>[
        ColoredBox(
          color: Colors.grey.shade800,
          child: Stack(
            children: <Widget>[
              Center(
                child: CameraPreview(
                  _cameraController,
                  child: widget.customPaint,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future _startLiveFeed(CameraDescription cameraDescription) async {
    _cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.yuv420
          : ImageFormatGroup.bgra8888,
    );

    try {
      await _cameraController.initialize().then((_) {
        if (!mounted) return;

        _cameraController.startImageStream(_processCameraImage);
        setState(() {});
      });
    } on CameraException catch (e) {
      debugPrint("Camera error $e");
    }
  }

  Future<void> _stopLiveFeed() async {
    await _cameraController.stopImageStream();
    await _cameraController.dispose();
  }

  @override
  void dispose() {
    _stopLiveFeed();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    initCamera();
  }

  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  _processCameraImage(CameraImage image) {
    final inputImage = _inputImageFromCamera(image);
    if (inputImage == null) return;
    widget.onImage(inputImage);
  }

  InputImage? _inputImageFromCamera(CameraImage image) {
    // Uint8List _cameraImageToBytes(CameraImage image)
    // final WriteBuffer allBytes = WriteBuffer();
    // for (Plane plane in image.planes) {
    //     allBytes.putUint8List(plane.bytes);
    //   }
    //   final bytes = allBytes.done().buffer.asUint8List();
    //   //return bytes;
    // }

    // InputImage? _inputImageFromCamera(CameraImage image) {
    //   final bytes = _cameraImageToBytes(image);

    //   final imageRotation = InputImageRotationValue.fromRawValue(
    //           widget.cameras[0].sensorOrientation) ??
    //       InputImageRotation.rotation0deg;

    //   final inputImageFormat =
    //       InputImageFormatValue.fromRawValue(image.format.raw) ??
    //           InputImageFormat.nv21;

    //   int newWidth = image.planes[0].bytesPerRow;

    //   final inputImageData = InputImageMetadata(
    //     size: Size(newWidth.toDouble(), image.height.toDouble()),
    //     rotation: imageRotation,
    //     format: inputImageFormat,
    //     bytesPerRow: image.planes.length,
    //   );
    //   final inputImage =
    //       InputImage.fromBytes(bytes: bytes, metadata: inputImageData);
    //   return inputImage;

    final WriteBuffer allBytes = WriteBuffer();
    for (Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final sensorOrientation = widget.cameras[0].sensorOrientation;
    final format = InputImageFormatValue.fromRawValue(image.format.raw);

    InputImageRotation? rotation;
    if (Platform.isAndroid) {
      var rotationCompensation =
          _orientations[_cameraController.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (widget.cameras[0].lensDirection == CameraLensDirection.front) {
        // front-facing
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        // back-facing
        rotationCompensation = (sensorOrientation - rotationCompensation) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    // rotation = InputImageRotationValue.fromRawValue(
    //         widget.cameras[0].sensorOrientation) ??
    //     InputImageRotation.rotation0deg;
    if (rotation == null) return null;

    if (format == null ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      return null;
    }

    // if (image.planes.length != 1) return null;
    // final plane = image.planes.first;

    final inputImageData = InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.length,
      ),
    );

    return inputImageData;
  }
}
