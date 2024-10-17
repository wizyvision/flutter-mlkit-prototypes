import 'package:flutter/material.dart';
import 'package:ml_kit_implementation/features/ml_kit_feature.dart';

class ObjectDetectorSingleCard extends MLKitFeature {
  ObjectDetectorSingleCard()
      : super(
          name: "Object Detector",
          description: "Detect objects with single image",
          icon: Icons.qr_code_scanner_outlined,
          color: Colors.amber[100]!,
        );

  @override
  void launch(BuildContext context) async {
    // Navigate to the BarcodeScannerView and pass the list of cameras.
    // final cameras = await availableCameras().then((value) {
    //   Navigator.push(
    //       context,
    //       MaterialPageRoute(
    //           builder: (context) => ObjectDetectorStream(cameras: value)));
    // });
  }
}
