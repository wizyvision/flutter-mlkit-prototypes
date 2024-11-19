import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:ml_kit_implementation/features/ml_kit_feature.dart';
import 'package:ml_kit_implementation/features/object_tracking_view.dart';

class ObjectTrackingFeature extends MLKitFeature {
  ObjectTrackingFeature()
      : super(
          name: "Barcode Single 2",
          description: "Scan single barcode",
          icon: Icons.select_all_outlined,
          color: Colors.yellow[100]!,
        );

  @override
  void launch(BuildContext context) async {
    final cameras = await availableCameras();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeScannerView(cameras: cameras),
      ),
    );
  }
}
