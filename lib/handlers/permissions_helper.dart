import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsHelper {
  // Request camera and storage permission
  static Future<bool> requestPermissions(BuildContext context) async {
    // Request camera permission
    if (await Permission.camera.isDenied) {
      final cameraStatus = await Permission.camera.request();
      if (!cameraStatus.isGranted) {
        _showPermissionDeniedMessage(context);
        return false;
      }
    }
    // Request storage permission
    if (await Permission.storage.isDenied) {
      final storageStatus = await Permission.storage.request();
      if (!storageStatus.isGranted) {
        _showPermissionDeniedMessage(context);
        return false;
      }
    }
    // Permissions granted
    return true;
  }

  static void _showPermissionDeniedMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('Please grant camera and storage permissions to proceed.'),
      ),
    );
  }
}
