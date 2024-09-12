import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  late DocumentScanner _documentScanner;
  late DocumentScannerOptions _documentOptions;

  @override
  void initState() {
    super.initState();
    initializeCamera();
    setupDocumentScanner();
  }

  void initializeCamera() async {
    final cameras = await availableCameras();
    _controller = CameraController(
      cameras[0],
      ResolutionPreset.high,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  void setupDocumentScanner() {
    _documentOptions = DocumentScannerOptions(
      documentFormat: DocumentFormat.jpeg,
      mode: ScannerMode.filter,
      pageLimit: 1,
      isGalleryImport: true,
    );
    _documentScanner = DocumentScanner(options: _documentOptions);
  }

  Future<void> _scanDocument() async {
    try {
      // Capture image
      XFile imageFile = await _controller.takePicture();

      DocumentScanningResult result = await _documentScanner.scanDocument();

      final pdf = result.pdf; // PDF object
      final images = result.images; // List of image paths

      // Process the scanned document
      setState(() {
        // Handle scanned results
        print('PDF path: $pdf');
        print('Image paths: $images');
      });
    } catch (e) {
      print("Error scanning document: $e");
    }
  }

  @override
  void dispose() {
    _documentScanner.close();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Document Scanner')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Column(
              children: [
                Expanded(child: CameraPreview(_controller)),
                ElevatedButton(
                  onPressed: _scanDocument,
                  child: Text('Scan Document'),
                ),
              ],
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
