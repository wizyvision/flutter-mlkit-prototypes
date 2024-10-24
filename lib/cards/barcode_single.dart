import 'package:flutter/material.dart';
import 'package:camera/camera.dart'; // Import the camera package
import 'package:ml_kit_implementation/features/barcode_scanner_single.dart';
import 'package:ml_kit_implementation/features/ml_kit_feature.dart';

class BarcodeSingleFeature extends MLKitFeature {
  BarcodeSingleFeature()
      : super(
          name: "Barcode Single 1",
          description: "Scan single barcode",
          icon: Icons.qr_code_scanner_outlined,
          color: Colors.lightGreen[100]!,
        );

  @override
  void launch(BuildContext context) async {
    // Fetch the available cameras
    List<CameraDescription> cameras = await availableCameras();

    // Navigate to the BarcodeScannerView and pass the list of cameras.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeSingleView(cameras: cameras),
      ),
    );
  }
}
