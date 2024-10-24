import 'package:flutter/foundation.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

class BarcodeProvider extends ChangeNotifier {
  List<Barcode> _confirmedBarcodes = [];

  void addBarcode(Barcode barcode) {
    if (!_confirmedBarcodes.contains(barcode.displayValue)) {
      _confirmedBarcodes.add(barcode);
    }
    notifyListeners();
    // for (Barcode k in _confirmedBarcodes) {
    //   if (k.displayValue != barcode.displayValue) {
    //     _confirmedBarcodes.add(barcode);
    //   }
    //   notifyListeners();
    // }
  }

  void removeBarcode(int index) {
    _confirmedBarcodes.removeAt(index);
    notifyListeners();
  }

  List<Barcode> getBarcodes() {
    return _confirmedBarcodes;
  }
}
