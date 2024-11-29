import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:flutter/foundation.dart';

class SingleBarcodeProvider with ChangeNotifier {
  // Store the current selected barcode
  Barcode? _selectedBarcode;
  Barcode? get selectedBarcode => _selectedBarcode;

  // Whether the barcode is tapped (for color change)
  bool _isBarcodeTapped = false;
  bool get isBarcodeTapped => _isBarcodeTapped;

  // Update the selected barcode
  void selectBarcode(Barcode barcode) {
    _selectedBarcode = barcode;
    _isBarcodeTapped =
        false; // Reset tapped state when a new barcode is selected
    notifyListeners();
  }

  // Toggle the state of the tapped barcode (change the box color)
  void toggleBarcodeTap() {
    _isBarcodeTapped = !_isBarcodeTapped;
    notifyListeners();
  }

  // Reset the provider state (can be useful if you want to reset the scan)
  void resetProvider() {
    _selectedBarcode = null;
    _isBarcodeTapped = false;
    notifyListeners();
  }
}
