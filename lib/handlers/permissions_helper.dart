import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsHelper {
  // Request camera and storage permission
  static Future<bool> requestPermissions(BuildContext context) async {
    final cameraStatus = await Permission.camera.request();
    final storageStatus = await Permission.storage.request();

    print('Camera permission status: ${cameraStatus.isGranted}');
    print('Storage permission status: ${storageStatus.isGranted}');

    if (!cameraStatus.isGranted || !storageStatus.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please grant camera and storage permissions')),
      );
      return false;
    }
    return true;
  }
}
