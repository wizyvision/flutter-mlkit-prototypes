import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:ml_kit_implementation/enums.dart';
import 'package:ml_kit_implementation/features/camera_view.dart';
import 'package:ml_kit_implementation/features/painters/barcode_detector_painter.dart';

bool _isProcessed = false;

class BarcodeScannerView extends StatefulWidget {
  final List<CameraDescription> cameras;

  const BarcodeScannerView({super.key, required this.cameras});

  @override
  State<BarcodeScannerView> createState() => _BarcodeScannerViewState();
}

class _BarcodeScannerViewState extends State<BarcodeScannerView> {
  final BarcodeScanner _barcodeScanner = BarcodeScanner();

  bool _isBusy = false;
  bool _isPaused = false;
  late List<Barcode>? _barcodeList;

  CustomPaint? _customPaint;
  var _cameraLensDirection = CameraLensDirection.back;
  var _cameraController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Camera'),
      ),
      body: CameraStreamView(
        onImage: _processBarcodeImage,
        cameras: widget.cameras,
        customPaint: _customPaint,
      ),
    );
  }

  Future<void> _processBarcodeImage(InputImage inputImage) async {
    // only needed for modal pop-up
    // if (_isBusy || _isProcessed) return;
    if (_isBusy) return;
    _isBusy = true;

    bool _isPainted = false;

    final barcodes = await _barcodeScanner.processImage(inputImage);
    if (inputImage.metadata?.size != null &&
        inputImage.metadata?.rotation != null) {
      if (mounted) {
        setState(() {
          _barcodeList = barcodes;
        });
      }

      final painter = BarcodeDetectorPainter(
        _barcodeList!,
        inputImage.metadata!.size,
        inputImage.metadata!.rotation,
        _cameraLensDirection,
      );
      _customPaint = CustomPaint(painter: painter);

      _isPainted = true;
    }
    if (barcodes.isNotEmpty && _isPainted) {
      // _isProcessed = true;

      if (mounted) {
        setState(() {
          _isPaused = true;
        });
      }
    }

    _isBusy = false;
    // if (mounted && _isProcessed) {
    //   showModalBottomSheet(
    //     isDismissible: false,
    //     context: context,
    //     builder: (context) => ModalPopup(text: barcodes),
    //   );
    //   setState(() {});
    // } else if (mounted) {
    //   setState(() {});
    // }
  }
}

class ModalPopup extends StatefulWidget {
  final List<Barcode> text;

  const ModalPopup({
    super.key,
    required this.text,
  });

  @override
  State<ModalPopup> createState() => _ModalPopupState();
}

class _ModalPopupState extends State<ModalPopup> {
  int counter = -1;
  TextAlign _bgIconAlignment = TextAlign.start;
  // TextDirection _bgIconAlignment = TextDirection.ltr;

  final textController = TextEditingController();

  @override
  void initState() {
    counter = widget.text.length;

    super.initState();
  }

  @override
  void dispose() {
    _isProcessed = false;

    super.dispose();
  }

  void _returnToCamera() {
    Navigator.pop(context);
  }

  Widget _background(Enum bgButton) {
    switch (bgButton) {
      case DismissibleBGFormat.start:
        _bgIconAlignment = TextAlign.start;
        // _bgIconAlignment = TextDirection.ltr;

        break;
      case DismissibleBGFormat.end:
        _bgIconAlignment = TextAlign.end;
      // _bgIconAlignment = TextDirection.rtl;

      default:
        _bgIconAlignment = TextAlign.start;
      // _bgIconAlignment = TextDirection.ltr;
    }

    return Container(
        margin: const EdgeInsets.fromLTRB(0.0, 12.0, 0.0, 12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6.0),
          color: Colors.red,
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Delete',
            style: const TextStyle(color: Colors.white),
            textAlign: _bgIconAlignment,
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Expanded(
            flex: 0,
            child: ListTile(
              title: const Text('Barcode(s):'),
              trailing: IconButton(
                icon: const Icon(Icons.cancel_rounded),
                onPressed: () {
                  _returnToCamera();
                },
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: ListView.builder(
              itemCount: widget.text.length,
              itemBuilder: (context, index) {
                final barcode = widget.text[index].displayValue!;
                return Dismissible(
                  key: UniqueKey(),
                  background: _background(DismissibleBGFormat.start),
                  secondaryBackground: _background(DismissibleBGFormat.end),
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    margin: const EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 8.0),
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(8.0)),
                    child: ListTile(
                      title: Text(barcode),
                      trailing: const Icon(Icons.keyboard_arrow_right_rounded),
                    ),
                  ),
                  onDismissed: (direction) {
                    // counts length of List<Barcode>, deducts 1 every onDismissed until 0
                    counter--;
                    if (counter == 0) {
                      _returnToCamera();
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
