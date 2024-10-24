import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:ml_kit_implementation/features/barcode_scanner_multiple.dart';
import 'package:ml_kit_implementation/features/barcode_scanner_view.dart';
import 'package:ml_kit_implementation/features/ml_kit_feature.dart';

class BarcodeScannerFeature extends MLKitFeature {
  BarcodeScannerFeature()
      : super(
          name: "Barcode Mutiple",
          description: "Scan multiple barcodes",
          icon: Icons.qr_code_scanner_outlined,
          color: Colors.lightGreen[100]!,
        );

  @override
  void launch(BuildContext context) async {
    // Navigate to the BarcodeScannerView and pass the list of cameras.
    final cameras = await availableCameras().then((value) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => BarcodeMultipleView(cameras: value)));
    });

    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => BarcodeScannerView(
    //       cameras: cameras,
    //     ),
    //   ),
    // );
  }
}
