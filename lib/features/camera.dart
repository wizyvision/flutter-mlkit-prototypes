import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';

class CameraView extends StatefulWidget {
  const CameraView({super.key});

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> with WidgetsBindingObserver {
  List<CameraDescription> cameras = [];
  CameraController? cameraController;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (cameraController == null ||
        cameraController?.value.isInitialized == false) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _setupCameraController();
    }
  }

  @override
  void initState() {
    super.initState();
    _setupCameraController();
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: _buildUI(screenHeight, screenWidth),
    );
  }

  Widget _buildUI(double screenHeight, double screenWidth) {
    if (cameraController == null ||
        cameraController?.value.isInitialized == false) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    return SafeArea(
      child: Column(
        children: [
          // Top section with black background and top icons
          Container(
            color: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            height: screenHeight * 0.1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: screenWidth * 0.08,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(); // Go back to previous screen
                  },
                ),
                IconButton(
                  icon: Icon(
                    // _isFlashOn ? Icons.flash_on : Icons.flash_off,
                    Icons.flash_on,
                    color: Colors.white,
                    size: screenWidth * 0.08,
                  ),
                  onPressed: () async {
                    // setState(() {
                    //   _isFlashOn = !_isFlashOn;
                    // });
                    // await cameraController?.setFlashMode(
                    //   _isFlashOn ? FlashMode.torch : FlashMode.off,
                    // );
                  },
                ),
              ],
            ),
          ),

          // Middle section for Camera Preview
          Expanded(
            child: AspectRatio(
              aspectRatio: screenWidth / (screenHeight * 0.6),
              child: CameraPreview(cameraController!),
            ),
          ),

          // Bottom section with black background and bottom icons
          Container(
            color: Colors.black,
            padding: const EdgeInsets.all(16.0),
            height: screenHeight * 0.25,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () async {
                    // Open gallery or perform another action
                  },
                  iconSize: screenWidth * 0.10,
                  icon: const Icon(
                    Icons.photo_library,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    XFile picture = await cameraController!.takePicture();
                    Gal.putImage(
                      picture.path,
                    );
                  },
                  iconSize: screenWidth * 0.22,
                  icon: const Icon(
                    CupertinoIcons.circle_filled,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    // Handle switching cameras
                  },
                  iconSize: screenWidth * 0.10,
                  icon: const Icon(
                    CupertinoIcons.arrow_2_circlepath_circle_fill,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _setupCameraController() async {
    List<CameraDescription> _cameras = await availableCameras();
    if (_cameras.isNotEmpty) {
      setState(() {
        cameras = _cameras;
        cameraController = CameraController(
          _cameras.first,
          ResolutionPreset.max,
        );
      });
      cameraController?.initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {});
      }).catchError(
        (Object e) {
          print(e);
        },
      );
    }
  }
}
