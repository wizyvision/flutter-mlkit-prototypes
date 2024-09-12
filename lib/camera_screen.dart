import 'package:flutter/material.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class ScannerScreen extends StatefulWidget {
  @override
  _ScannerScreenState createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  late DocumentScanner _documentScanner;

  @override
  void initState() {
    super.initState();
    final DocumentScannerOptions documentOptions = DocumentScannerOptions(
      documentFormat: DocumentFormat.jpeg,
      mode: ScannerMode.filter,
      pageLimit: 1,
      isGalleryImport: true,
    );
    _documentScanner = DocumentScanner(options: documentOptions);
  }

  Future<void> _requestPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final storageStatus = await Permission.storage.request();

    print('Camera permission status: ${cameraStatus.isGranted}');
    print('Storage permission status: ${storageStatus.isGranted}');

    if (!cameraStatus.isGranted || !storageStatus.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please grant camera and storage permissions')),
      );
      return;
    }

    _scanDocument();
  }

  Future<void> _scanDocument() async {
    try {
      print('Starting document scan...');
      final result = await _documentScanner.scanDocument();
      print('Document scan result: $result');

      final pdf = result.pdf;
      final images = result.images;

      if (pdf != null) {
        print('PDF generated');
        // Handle the generated PDF
      } else {
        print('No PDF generated');
      }

      if (images.isNotEmpty) {
        print('Images captured: ${images.length}');
        // Handle the images
      } else {
        print('No images captured');
      }
    } catch (e, stackTrace) {
      print('Error scanning document: $e');
      print('Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to scan document: $e')),
      );
    }
  }

  @override
  void dispose() {
    _documentScanner.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Document Scanner'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _requestPermissions,
          child: Text('Scan Document'),
        ),
      ),
    );
  }
}
