import 'package:flutter/foundation.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

class BarcodeProvider extends ChangeNotifier {
  final List<Barcode> _confirmedBarcodes = [];
  final List<Barcode> _scannedBarcodes = [];
  int _scanCount = 0;
  final int _maxScans = 5;
  bool _isPaused = false;

  int get scanCount => _scanCount;
  int get maxScans => _maxScans;
  bool get isPaused => _isPaused;
  int get confirmedCount => _confirmedBarcodes.length;

  List<Barcode> get confirmedBarcodes => List.unmodifiable(_confirmedBarcodes);
  List<Barcode> get scannedBarcodes => List.unmodifiable(_scannedBarcodes);

  void addScannedBarcode(Barcode barcode) {
    if (_isPaused || _scanCount >= _maxScans) return;

    bool alreadyExists = _scannedBarcodes.any(
      (existingBarcode) => existingBarcode.displayValue == barcode.displayValue,
    );

    if (!alreadyExists) {
      _scannedBarcodes.add(barcode);
      _scanCount++;

      if (_scanCount >= _maxScans) {
        _isPaused = true;
      }
      notifyListeners();
    }
  }

  void confirmBarcode(Barcode barcode) {
    bool alreadyConfirmed = _confirmedBarcodes.any(
      (existingBarcode) => existingBarcode.displayValue == barcode.displayValue,
    );

    if (!alreadyConfirmed) {
      _confirmedBarcodes.add(barcode);
      notifyListeners();
    }
  }

  void removeBarcode(int index) {
    if (index >= 0 && index < _scannedBarcodes.length) {
      _scannedBarcodes.removeAt(index);
      notifyListeners();
    }
  }

  void resetScanProgress() {
    _scannedBarcodes.clear();
    _scanCount = 0;
    _isPaused = false;
    notifyListeners();
  }
}
