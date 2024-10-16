import 'dart:io';
import 'dart:typed_data'; // Import for Uint8List
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:image/image.dart' as img; // For decoding the image

class SingleObjScreen extends StatefulWidget {
  @override
  _SingleObjScreenState createState() => _SingleObjScreenState();
}

class _SingleObjScreenState extends State<SingleObjScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _image;
  List<DetectedObject>? _detectedObjects;
  Size? _imageSize; // Store image dimensions

  Future<void> _pickImage() async {
    final XFile? pickedFile = await showDialog<XFile?>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Pick Image Source'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null), // Cancel
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final XFile? image =
                      await _picker.pickImage(source: ImageSource.gallery);
                  Navigator.pop(context, image);
                },
                child: Text('Gallery'),
              ),
              TextButton(
                onPressed: () async {
                  final XFile? image =
                      await _picker.pickImage(source: ImageSource.camera);
                  Navigator.pop(context, image);
                },
                child: Text('Camera'),
              ),
            ],
          );
        });

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      await _loadImageSize(_image!); // Load image size
      _detectObjects(_image!);
    }
  }

  // Load image size using image library
  Future<void> _loadImageSize(File image) async {
    final Uint8List imageBytes = await image.readAsBytes();
    final img.Image? decodedImage = img.decodeImage(imageBytes);

    if (decodedImage != null) {
      setState(() {
        _imageSize =
            Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());
      });
    }
  }

  Future<void> _detectObjects(File image) async {
    final inputImage = InputImage.fromFile(image);

    final objectDetectorOptions = ObjectDetectorOptions(
      mode: DetectionMode.single,
      classifyObjects: true,
      multipleObjects: true,
    );

    final objectDetector = ObjectDetector(options: objectDetectorOptions);
    final detectedObjects = await objectDetector.processImage(inputImage);

    setState(() {
      _detectedObjects = detectedObjects;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Object Detection')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _image == null
                ? Text('No image selected.')
                : Container(
                    constraints: BoxConstraints(
                      maxWidth: 500, // Set a maximum width
                      maxHeight: 500, // Set a maximum height
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.file(
                          _image!,
                          width: _imageSize?.width ?? 0, // Use original width
                          height:
                              _imageSize?.height ?? 0, // Use original height
                          fit: BoxFit.contain, // Maintain aspect ratio
                        ),
                        if (_detectedObjects != null && _imageSize != null)
                          CustomPaint(
                            size: Size(
                              _imageSize!.width,
                              _imageSize!.height,
                            ),
                            painter: ObjectDetectorPainter(
                              _detectedObjects!,
                              _imageSize!,
                            ),
                          ),
                      ],
                    ),
                  ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Pick Image'),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class ObjectDetectorPainter extends CustomPainter {
  final List<DetectedObject> detectedObjects;
  final Size imageSize;

  ObjectDetectorPainter(this.detectedObjects, this.imageSize);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Calculate scaling factor to match the image size
    final double widthScale = size.width / imageSize.width;
    final double heightScale = size.height / imageSize.height;

    for (final detectedObject in detectedObjects) {
      final Rect boundingBox = detectedObject.boundingBox;

      // Draw the bounding box
      canvas.drawRect(
        Rect.fromLTRB(
          boundingBox.left * widthScale,
          boundingBox.top * heightScale,
          boundingBox.right * widthScale,
          boundingBox.bottom * heightScale,
        ),
        paint,
      );

      // Draw the label
      String labelText = detectedObject.labels.isNotEmpty
          ? detectedObject.labels.first.text
          : "null";

      TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: labelText,
          style: TextStyle(color: Colors.red, fontSize: 16),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          boundingBox.left * widthScale,
          boundingBox.top * heightScale - textPainter.height,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
