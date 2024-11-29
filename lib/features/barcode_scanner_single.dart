import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:ml_kit_implementation/features/camera.dart';
import 'package:ml_kit_implementation/features/painters/barcode_painter_single.dart';
import 'package:provider/provider.dart';
import 'package:ml_kit_implementation/features/single_barcode_provider.dart'; // Import the new provider

class BarcodeSingleView extends StatefulWidget {
  final List<CameraDescription> cameras;

  const BarcodeSingleView({Key? key, required this.cameras}) : super(key: key);

  @override
  State<BarcodeSingleView> createState() => _BarcodeSingleViewState();
}

class _BarcodeSingleViewState extends State<BarcodeSingleView> {
  final BarcodeScanner _barcodeScanner = BarcodeScanner();
  bool _isBusy = false;
  CustomPaint? _customPaint;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
          SingleBarcodeProvider(), // Provide the SingleBarcodeProvider
      child: Consumer<SingleBarcodeProvider>(
        builder: (context, barcodeProvider, _) {
          return Stack(
            children: [
              CameraView(
                onImage: _processBarcodeImage,
                cameras: widget.cameras,
                customPaint: _customPaint,
                isPaused: false,
              ),
              if (barcodeProvider.selectedBarcode != null)
                _barcodeDetailsPopup(barcodeProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _barcodeDetailsPopup(SingleBarcodeProvider barcodeProvider) {
    return Positioned(
      bottom: 50.0,
      left: 16.0,
      right: 16.0,
      child: GestureDetector(
        onTap: () {
          barcodeProvider
              .toggleBarcodeTap(); // Toggle the tapped state when tapped
          _showBarcodeModal(barcodeProvider.selectedBarcode!);
        },
        child: Container(
          color: Colors.black54,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Barcode Detected!',
                style: TextStyle(color: Colors.white, fontSize: 18.0),
              ),
              SizedBox(height: 8.0),
              Text(
                'Value: ${barcodeProvider.selectedBarcode?.displayValue ?? "Unknown"}',
                style: TextStyle(color: Colors.white, fontSize: 16.0),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processBarcodeImage(InputImage inputImage) async {
    if (_isBusy) return;
    _isBusy = true;

    final barcodeProvider =
        Provider.of<SingleBarcodeProvider>(context, listen: false);
    final barcodes = await _barcodeScanner.processImage(inputImage);

    if (inputImage.metadata?.size != null &&
        inputImage.metadata?.rotation != null) {
      setState(() {
        _customPaint = CustomPaint(
          painter: BarcodeDetectorPainter(
            barcodes,
            inputImage.metadata!.size,
            inputImage.metadata!.rotation,
            CameraLensDirection.back,
            selectedBarcode:
                barcodeProvider.selectedBarcode, // Pass selected barcode
          ),
        );
      });

      if (barcodes.isNotEmpty) {
        // Select the first barcode detected
        barcodeProvider.selectBarcode(barcodes.first);
      }
    }

    _isBusy = false;
  }

  void _showBarcodeModal(Barcode barcode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.4,
          minChildSize: 0.2,
          maxChildSize: 0.8,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.circular(20.0),
                ),
              ),
              child: ModalPopup(
                  barcode: barcode, scrollController: scrollController),
            );
          },
        );
      },
    );
  }
}

class ModalPopup extends StatelessWidget {
  final ScrollController scrollController;
  final Barcode barcode;

  const ModalPopup({
    Key? key,
    required this.scrollController,
    required this.barcode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          ListTile(
            title: Text('Detected Barcode'),
          ),
          ListTile(
            title: Text('Value: ${barcode.displayValue ?? "Unknown"}'),
          ),
        ],
      ),
    );
  }
}
