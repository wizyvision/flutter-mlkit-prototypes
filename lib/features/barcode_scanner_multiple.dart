import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:ml_kit_implementation/features/camera.dart';
import 'package:ml_kit_implementation/features/barcode_provider.dart';
import 'package:ml_kit_implementation/features/painters/barcode_detector_painter.dart';
import 'package:provider/provider.dart';

class BarcodeMultipleView extends StatefulWidget {
  final List<CameraDescription> cameras;

  const BarcodeMultipleView({Key? key, required this.cameras})
      : super(key: key);

  @override
  State<BarcodeMultipleView> createState() => _BarcodeMultipleViewState();
}

class _BarcodeMultipleViewState extends State<BarcodeMultipleView> {
  final BarcodeScanner _barcodeScanner = BarcodeScanner();
  bool _isBusy = false;
  CustomPaint? _customPaint;

  @override
  Widget build(BuildContext context) {
    final barcodeProvider = Provider.of<BarcodeProvider>(context);

    return Stack(
      children: [
        CameraView(
          onImage: _processBarcodeImage,
          cameras: widget.cameras,
          customPaint: _customPaint,
          isPaused: barcodeProvider.isPaused,
        ),
        if (barcodeProvider.isPaused) _retakeButton(),
        Positioned(
          top: 16.0,
          left: 16.0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Text(
              'Scanned: ${barcodeProvider.scanCount}/${barcodeProvider.maxScans}, Confirmed: ${barcodeProvider.confirmedCount}',
              style: const TextStyle(color: Colors.white, fontSize: 16.0),
            ),
          ),
        ),
      ],
    );
  }

  Widget _retakeButton() => Positioned(
        top: 50.0,
        right: 20.0,
        child: FloatingActionButton(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          onPressed: () {
            Provider.of<BarcodeProvider>(context, listen: false)
                .resetScanProgress();
          },
          child: const Icon(Icons.refresh_outlined),
        ),
      );

  Future<void> _processBarcodeImage(InputImage inputImage) async {
    if (_isBusy) return;
    _isBusy = true;

    final barcodeProvider =
        Provider.of<BarcodeProvider>(context, listen: false);
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
          ),
        );
      });

      for (var barcode in barcodes) {
        barcodeProvider.addScannedBarcode(barcode);
      }

      if (barcodeProvider.isPaused) {
        _showBarcodeModal();
      }
    }

    _isBusy = false;
  }

  void _showBarcodeModal() {
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
              child: ModalPopup(scrollController: scrollController),
            );
          },
        );
      },
    );
  }
}

class ModalPopup extends StatelessWidget {
  final ScrollController scrollController;

  const ModalPopup({
    Key? key,
    required this.scrollController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final barcodeProvider = Provider.of<BarcodeProvider>(context);
    final scannedBarcodes = barcodeProvider.scannedBarcodes;
    final confirmedBarcodes = barcodeProvider.confirmedBarcodes;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          ListTile(
            title: Text(
              'Detected Barcodes (Scanned: ${scannedBarcodes.length}, Confirmed: ${confirmedBarcodes.length})',
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: scannedBarcodes.length,
              itemBuilder: (context, index) {
                final barcode = scannedBarcodes[index];
                final isConfirmed = confirmedBarcodes.contains(barcode);

                return Dismissible(
                  key: ValueKey(barcode.displayValue),
                  background: _dismissBackground(DismissDirection.startToEnd),
                  secondaryBackground:
                      _dismissBackground(DismissDirection.endToStart),
                  onDismissed: (_) => barcodeProvider.removeBarcode(index),
                  child: _buildListTile(barcode, isConfirmed, barcodeProvider),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _dismissBackground(DismissDirection direction) => Container(
        margin: const EdgeInsets.symmetric(vertical: 12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6.0),
          color: Colors.red,
        ),
        alignment: direction == DismissDirection.startToEnd
            ? Alignment.centerLeft
            : Alignment.centerRight,
        padding: const EdgeInsets.all(8.0),
        child: const Text('Delete', style: TextStyle(color: Colors.white)),
      );

  Widget _buildListTile(
      Barcode barcode, bool isConfirmed, BarcodeProvider provider) {
    final displayValue = barcode.displayValue ?? 'Unknown';

    return ListTile(
      enabled: !isConfirmed,
      title: Text(displayValue),
      trailing: IconButton(
        icon: Icon(isConfirmed ? Icons.check : Icons.check_box_outline_blank),
        onPressed: isConfirmed ? null : () => provider.confirmBarcode(barcode),
      ),
    );
  }
}
