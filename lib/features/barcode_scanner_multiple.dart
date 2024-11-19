import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:ml_kit_implementation/enums.dart';
import 'package:ml_kit_implementation/features/camera.dart';
import 'package:ml_kit_implementation/features/barcode_provider.dart';
import 'package:ml_kit_implementation/features/painters/barcode_detector_painter.dart';
import 'package:provider/provider.dart';

bool _modalNotBuilt = true;

class BarcodeMultipleView extends StatefulWidget {
  final List<CameraDescription> cameras;

  const BarcodeMultipleView({super.key, required this.cameras});

  @override
  State<BarcodeMultipleView> createState() => _BarcodeScannerViewState();
}

class _BarcodeScannerViewState extends State<BarcodeMultipleView> {
  final BarcodeScanner _barcodeScanner = BarcodeScanner();

  bool _isBusy = false;
  bool _isPainted = false;
  bool _isPaused = false;
  late List<Barcode>? _barcodeList;

  CustomPaint? _customPaint;
  var _cameraLensDirection = CameraLensDirection.back;

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
            ? _retakeButton()
            : const Placeholder(
                color: Colors.transparent,
              ),
      ],
    );
  }

  Widget _retakeButton() {
    return Positioned(
      top: 50.0,
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
      //_barcodeList = [];
      _isPaused = false;
      _isPainted = false;
      _modalNotBuilt = true;
    });
  }

  Future<void> _processBarcodeImage(InputImage inputImage) async {
    if (_isBusy) return;
    _isBusy = true;

    final barcodes = await _barcodeScanner.processImage(inputImage);
    if (inputImage.metadata?.size != null &&
        inputImage.metadata?.rotation != null) {
      if (mounted) {
        setState(() {
          // Map<String, bool> map = {
          //   for (var k in barcodes) k.displayValue.toString(): true
          // };

          _barcodeList = barcodes;
          //barcodeState.addAll(map);
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
    if (_barcodeList!.isNotEmpty && _isPainted && !_customPaint!.willChange) {
      if (mounted && _modalNotBuilt) {
        setState(() {
          _isPaused = true;
        });

        showModalBottomSheet(
          isDismissible: true,
          barrierColor: Colors.transparent,
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4),
          context: context,
          builder: (context) => ModalPopup(barcodes: _barcodeList!),
        );
      }
    }

    _isBusy = false;
  }
}

class ModalPopup extends StatefulWidget {
  final List<Barcode> barcodes;

  const ModalPopup({
    super.key,
    required this.barcodes,
  });

  @override
  State<ModalPopup> createState() => _ModalPopupState();
}

class _ModalPopupState extends State<ModalPopup> {
  int _counter = -1;
  TextAlign _bgIconAlignment = TextAlign.start;
  bool _isAble = true;
  List<Map<String, dynamic>> enabledList = [];
  late List<Barcode> confirmedBarcodes;
  //for (int x = 0; )
  // TextDirection _bgIconAlignment = TextDirection.ltr;

  final textController = TextEditingController();

  @override
  void initState() {
    confirmedBarcodes =
        Provider.of<BarcodeProvider>(context, listen: false).getBarcodes();

    // Map<String, dynamic> map1 = {
    //   for (var k in confirmedBarcodes) 'name': k.displayValue,
    //   'isEnabled': false,
    // };

    int counter = 0;
    for (Barcode k in confirmedBarcodes) {
      Map<String, dynamic> tempMap = {
        'count': counter,
        'name': k,
        'isEnabled': false,
      };
      enabledList.add(tempMap);
      counter++;
    }

    // enabledList.add(map1);
    int counter2 = 0;
    for (Barcode k in widget.barcodes) {
      Map<String, dynamic> tempMap2 = {
        'count': counter2,
        'name': k,
        'isEnabled': true,
      };
      if (!enabledList.contains(k.displayValue)) {
        enabledList.add(tempMap2);
        counter2++;
      }
    }

    // Map<String, dynamic> map2 = {
    //   for (var k in widget.barcodes) 'name': k.displayValue,
    //   'isEnabled': true,
    // };

    // map2.forEach((k, v) => enabledList.putIfAbsent(k, v));

    _counter = enabledList.length;
    super.initState();

    // ensures modal only pops up once
    _modalNotBuilt = false;
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
              // trailing: IconButton(
              //   icon: const Icon(
              //     Icons.expand_more_rounded,
              //     size: 35.0,
              //   ),
              //   onPressed: () {
              //     _returnToCamera();
              //   },
              // ),
            ),
          ),
          Expanded(
            flex: 1,
            child: ListView.builder(
              itemCount: enabledList.length,
              itemBuilder: (context, index) {
                Map<String, dynamic> barcodeValue = enabledList[index];

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
                      child: _buildListTile(barcodeValue, index)),
                  onDismissed: (direction) {
                    // counts length of List<Barcode>, deducts 1 every onDismissed until 0
                    _counter--;

                    if (index < confirmedBarcodes.length) {
                      _removeBarcode(index);
                      // setState(() {});
                    }
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

  Widget _buildListTile(Map<String, dynamic> barcode, int index) {
    Barcode barcode1 = barcode['name'];
    String name = barcode1.displayValue!;
    int count = barcode['count'] + 1;
    bool _isEnabled = barcode['isEnabled'];
    return ListTile(
      enabled: _isEnabled,
      title: (index < confirmedBarcodes.length)
          ? Text('0.$count: $name')
          : Text('$count) $name'),
      trailing: Wrap(
        spacing: -12.0,
        children: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: () {
              _confirmBarcode(barcode1);
              setState(() {
                barcode['isEnabled'] = false;
              });
            },
          ),
          // IconButton(
          //   icon: Icon(Icons.cancel_rounded),
          //   onPressed: () {},
          // ),
        ],
      ),
    );
  }

  void _confirmBarcode(Barcode barcode) {
    Provider.of<BarcodeProvider>(context, listen: false).addBarcode(barcode);
  }

  void _removeBarcode(int index) {
    Provider.of<BarcodeProvider>(context, listen: false).removeBarcode(index);
  }
}
