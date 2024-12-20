import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:ml_kit_implementation/features/ml_kit_feature.dart';
import 'package:ml_kit_implementation/handlers/permissions_helper.dart';
import 'package:path_provider/path_provider.dart';

class DocumentScannerFeature extends MLKitFeature {
  DocumentScannerFeature()
      : super(
          name: "Document Scanner",
          description: "Scan documents",
          icon: Icons.document_scanner_outlined,
          color: Colors.lightBlue[100]!,
        );

  @override
  void launch(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ScannerScreen()),
    );
  }
}

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  _ScannerScreenState createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  late DocumentScanner _documentScanner;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermissions();
    });

    final DocumentScannerOptions documentOptions = DocumentScannerOptions(
      documentFormat: DocumentFormat.jpeg,
      mode: ScannerMode.filter,
      pageLimit: 5,
      isGalleryImport: true,
    );
    _documentScanner = DocumentScanner(options: documentOptions);
  }

  Future<void> _requestPermissions() async {
    bool permissionsGranted =
        await PermissionsHelper.requestPermissions(context);
    if (permissionsGranted) {
      _scanDocument();
    }
  }

  Future<void> _scanDocument() async {
    try {
      print('Starting document scan...');
      final result = await _documentScanner.scanDocument();

      // Save JPEG images
      if (result.images.isNotEmpty) {
        for (String imagePath in result.images) {
          await _saveImageToGallery(imagePath);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image saved to gallery')),
        );
      }

      // Save PDF file
      if (result.pdf != null) {
        await _savePdfToFile(result.pdf! as Uint8List);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF saved to Documents folder')),
        );
      }
    } catch (e, stackTrace) {
      print('Error scanning document: $e');
      print('Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to scan document: $e')),
      );
    }
  }

  // Funtion to save image as JPEG to gallery
  Future<void> _saveImageToGallery(String imagePath) async {
    await Gal.putImage(imagePath);
  }

  // Function to save PDF to files
  Future<void> _savePdfToFile(Uint8List pdfData) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath =
        '${directory.path}/scanned_document_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final pdfFile = File(filePath);
    await pdfFile.writeAsBytes(pdfData);
    print('PDF saved to: $filePath');
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
        child: CircularProgressIndicator(),
      ),
    );
  }
}
