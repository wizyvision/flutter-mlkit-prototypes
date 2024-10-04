import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:ml_kit_implementation/enums.dart';
import 'package:ml_kit_implementation/features/camera.dart';
import 'package:ml_kit_implementation/features/painters/barcode_detector_painter.dart';

bool _isProcessed = false;
bool _isProcessing = false;

class BarcodeScannerView extends StatefulWidget {
  final List<CameraDescription> cameras;

  const BarcodeScannerView({super.key, required this.cameras});

  @override
  State<BarcodeScannerView> createState() => _BarcodeScannerViewState();
}

class _BarcodeScannerViewState extends State<BarcodeScannerView> {
  final BarcodeScanner _barcodeScanner = BarcodeScanner();
  bool _isPaused = false;
  late List<Barcode> _barcodeList = [];
  int? _selectedBarcodeIndex;
  CustomPaint? _customPaint;
  late CameraController _cameraController;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameraController = CameraController(
      widget.cameras[0],
      ResolutionPreset.high,
    );
    await _cameraController.initialize();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTapDown: (details) {
            // Call the painter's checkTap method on tap
            if (_customPaint?.painter is BarcodeDetectorPainter) {
              (_customPaint!.painter as BarcodeDetectorPainter)
                  .checkTap(details.localPosition);
            }
          },
          child: CameraView(
            onImage: _processBarcodeImage,
            cameras: widget.cameras,
            customPaint: _customPaint,
            isPaused: _isPaused,
          ),
        ),
        _isPaused
            ? _retakeButton(_cameraController)
            : const Placeholder(color: Colors.transparent),
      ],
    );
  }

  Future<void> _processBarcodeImage(
      InputImage inputImage, CameraController controller) async {
    // Avoid processing frames too frequently
    if (_isProcessing) return;
    _isProcessing = true;

    // Ensure the InputImage is valid
    if (inputImage.metadata?.size == null ||
        inputImage.metadata?.rotation == null) {
      print('Invalid InputImage metadata');
      _isProcessing = false;
      return;
    }

    // Process barcodes
    final barcodes = await _barcodeScanner.processImage(inputImage);
    print('Detected ${barcodes.length} barcodes.');

    if (mounted) {
      setState(() {
        _barcodeList = barcodes;

        if (barcodes.isEmpty) {
          _customPaint = null;
        } else {
          final painter = BarcodeDetectorPainter(
            barcodes,
            inputImage.metadata!.size,
            inputImage.metadata!.rotation,
            CameraLensDirection.back,
            _selectedBarcodeIndex,
            _onBarcodeSelected,
          );
          _customPaint = CustomPaint(painter: painter);
        }
      });
    }

    // Reset the flag after a short delay
    await Future.delayed(const Duration(milliseconds: 200));
    _isProcessing = false;
  }

  void _onBarcodeSelected(int index) {
    setState(() {
      _selectedBarcodeIndex = index; // Set selected index
      _isPaused = true; // Pause the camera preview
    });

    // Show modal with barcode info
    showModalBottomSheet(
      isDismissible: true,
      context: context,
      builder: (context) => ModalPopup(text: [_barcodeList[index]]),
    );

    // Reset selected index after displaying the modal
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return; // Ensure widget is still mounted
      setState(() {
        // Do not reset the selected index here
      });
    });
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
          onPressed: _resumePreview,
          child: const Icon(Icons.refresh_outlined),
        ),
      ),
    );
  }

  void _resumePreview() {
    setState(() {
      _barcodeList = [];
      _selectedBarcodeIndex = null;
      _isPaused = false;
    });
    _cameraController.resumePreview();
  }
}

class ModalPopup extends StatelessWidget {
  final List<Barcode> text;

  const ModalPopup({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          ListTile(
            title: const Text('Barcode(s):'),
            trailing: IconButton(
              icon: const Icon(Icons.cancel_rounded),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: text.length,
              itemBuilder: (context, index) {
                final barcode = text[index].displayValue ?? 'Unknown';
                return Dismissible(
                  key: UniqueKey(),
                  background: _background(DismissibleBGFormat.start),
                  secondaryBackground: _background(DismissibleBGFormat.end),
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: ListTile(
                      title: Text('${index + 1}: $barcode'),
                      trailing: const Icon(Icons.keyboard_arrow_right_rounded),
                    ),
                  ),
                  onDismissed: (direction) {
                    if (text.length == 1) {
                      Navigator.pop(
                          context); // Close modal if all are dismissed
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

  Widget _background(DismissibleBGFormat format) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.red,
      child: const Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Delete',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
