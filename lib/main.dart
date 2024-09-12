import 'package:flutter/material.dart';
import 'camera_screen.dart';

void main() {
  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Document Scanner',
      home: CameraScreen(),
    );
  }
}
