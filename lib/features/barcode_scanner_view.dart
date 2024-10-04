import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:ml_kit_implementation/enums.dart';
import 'package:ml_kit_implementation/features/camera.dart';
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
  bool _isPainted = false;
  bool _isPaused = false;
  late List<Barcode>? _barcodeList;

  CustomPaint? _customPaint;
  var _cameraLensDirection = CameraLensDirection.back;
  late CameraController _cameraController;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CameraView(
          onImage: _processBarcodeImage,
          cameras: widget.cameras,
          customPaint: _customPaint,
          isPaused: _isPaused,
        ),
        _isPaused
            ? _retakeButton(_cameraController)
            : const Placeholder(
                color: Colors.transparent,
              ),
      ],
    );
  }

  Widget _retakeButton(CameraController controller) {
    return Positioned(
      top: 120.0,
      right: 20.0,
      child: SizedBox(
        height: 60.0,
        width: 40.0,
        child: FloatingActionButton(
          heroTag: Object(),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          shape: const CircleBorder(),
          onPressed: () {
            _resumePreview();
          },
          child: const Icon(Icons.refresh_outlined),
        ),
      ),
    );
  }

  void _resumePreview() {
    setState(() {
      _barcodeList = null;
      _isPaused = false;
    });
    _cameraController.resumePreview();
  }

  Future<void> _processBarcodeImage(
      InputImage inputImage, CameraController controller) async {
    _cameraController = controller;

    if (_isBusy) return;
    _isBusy = true;

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

      //isPainted = true;
      _isProcessed = true;
    }
    if (_barcodeList!.isNotEmpty && !_customPaint!.willChange && _isProcessed) {
      if (mounted) {
        setState(() {
          _isPaused = true;
        });
        _cameraController.pausePreview();
        showModalBottomSheet(
          isDismissible: true,
          context: context,
          builder: (context) => ModalPopup(text: _barcodeList!),
        );
      }
    }

    _isBusy = false;
    // if (mounted && _isProcessed) {
    //   // showModalBottomSheet(
    //   //   isDismissible: false,
    //   //   context: context,
    //   //   builder: (context) => ModalPopup(text: barcodes),
    //   // );
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
  int _counter = -1;
  TextAlign _bgIconAlignment = TextAlign.start;
  // TextDirection _bgIconAlignment = TextDirection.ltr;

  final textController = TextEditingController();

  @override
  void initState() {
    _counter = widget.text.length;

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
                      title: Text('${index + 1}: $barcode'),
                      trailing: const Icon(Icons.keyboard_arrow_right_rounded),
                    ),
                  ),
                  onDismissed: (direction) {
                    // counts length of List<Barcode>, deducts 1 every onDismissed until 0
                    _counter--;
                    if (_counter == 0) {
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
