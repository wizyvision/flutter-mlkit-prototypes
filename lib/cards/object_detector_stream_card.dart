import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:ml_kit_implementation/features/barcode_scanner_view.dart';
import 'package:ml_kit_implementation/features/camera.dart';
import 'package:ml_kit_implementation/features/ml_kit_feature.dart';
import 'package:ml_kit_implementation/features/object_detector_stream.dart';

class ObjectDetectorStreamCard extends MLKitFeature {
  ObjectDetectorStreamCard()
      : super(
          name: "Object Detector",
          description: "Detect objects via live stream",
          icon: Icons.qr_code_scanner_outlined,
          color: Colors.pink[100]!,
        );

  @override
  void launch(BuildContext context) async {
    // Navigate to the BarcodeScannerView and pass the list of cameras.
    final cameras = await availableCameras().then((value) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ObjectDetectorStream(cameras: value)));
    });
  }
}
