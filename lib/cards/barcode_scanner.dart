import 'package:flutter/material.dart';
import 'package:ml_kit_implementation/cards/document_scanner.dart';
import 'package:ml_kit_implementation/features/barcode_scanner_view.dart';
import 'package:ml_kit_implementation/features/ml_kit_feature.dart';

class BarcodeScannerFeature extends MLKitFeature {
  BarcodeScannerFeature()
      : super(
          name: "Barcode Scanner",
          description: "Scan barcodes and QR codes",
          icon: Icons.qr_code_scanner_outlined,
          color: Colors.lightGreen[100]!,
        );

  @override
  void launch(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeScannerView(),
      ),
    );
  }
}
