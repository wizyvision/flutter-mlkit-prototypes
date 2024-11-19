import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

class BarcodeDetailModal extends StatelessWidget {
  final Barcode barcode;
  final VoidCallback onClose;

  const BarcodeDetailModal({
    super.key,
    required this.barcode,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Details for Barcode',
            style: TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 10),
          Text('Value: ${barcode.displayValue ?? "Unknown"}'),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: onClose,
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
