import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:ml_kit_implementation/features/camera.dart';
import 'package:ml_kit_implementation/features/utils.dart';

import 'painters/object_detector_painter.dart';

class ObjectDetectorStream extends StatefulWidget {
  final List<CameraDescription> cameras;

  const ObjectDetectorStream({
    super.key,
    required this.cameras,
  });

  @override
  State<ObjectDetectorStream> createState() => _ObjectDetectorStreamState();
}

class _ObjectDetectorStreamState extends State<ObjectDetectorStream> {
  ObjectDetector? _objectDetector;
  var _cameraLensDirection = CameraLensDirection.back;

  DetectionMode _mode = DetectionMode.stream;
  bool _canProcess = false;
  bool _isBusy = false;
  bool _isPaused = false;
  bool _isPainted = false;
  late List<DetectedObject>? _objectList;
  CustomPaint? _customPaint;
  String? _text;
  int _option = 0;
  final _options = {
    'default': '',
    'object_custom': 'object_labeler.tflite',
    'fruits': 'object_labeler_fruits.tflite',
    'flowers': 'object_labeler_flowers.tflite',
    'birds': 'lite-model_aiy_vision_classifier_birds_V1_3.tflite',
    // https://tfhub.dev/google/lite-model/aiy/vision/classifier/birds_V1/3

    'food': 'lite-model_aiy_vision_classifier_food_V1_1.tflite',
    // https://tfhub.dev/google/lite-model/aiy/vision/classifier/food_V1/1

    'plants': 'lite-model_aiy_vision_classifier_plants_V1_3.tflite',
    // https://tfhub.dev/google/lite-model/aiy/vision/classifier/plants_V1/3

    'mushrooms': 'lite-model_models_mushroom-identification_v1_1.tflite',
    // https://tfhub.dev/bohemian-visual-recognition-alliance/lite-model/models/mushroom-identification_v1/1

    'landmarks':
        'lite-model_on_device_vision_classifier_landmarks_classifier_north_america_V1_1.tflite',
    // https://tfhub.dev/google/lite-model/on_device_vision/classifier/landmarks_classifier_north_america_V1/1
  };

  @override
  void initState() {
    _initializeDetector();
    super.initState();
  }

  @override
  void dispose() {
    _canProcess = false;
    _objectDetector?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CameraView(
          onImage: _processObjectImage,
          cameras: widget.cameras,
          customPaint: _customPaint,
          isPaused: _isPaused,
        ),
        _isPaused
            ? _retakeButton()
            : const Placeholder(
                color: Colors.transparent,
              ),
      ],
    );
  }

  Widget _retakeButton() {
    return Positioned(
      top: 50.0,
      right: 20.0,
      child: SizedBox(
        height: 60.0,
        width: 40.0,
        child: FloatingActionButton(
          heroTag: Object(),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          shape: const CircleBorder(),
          onPressed: () {
            _resumePreview();
          },
          child: const Icon(Icons.refresh_outlined),
        ),
      ),
    );
  }

  void _resumePreview() {
    setState(() {
      //_barcodeList = [];
      //_isPaused = false;
      _isPainted = false;
    });
  }

  void _initializeDetector() async {
    _objectDetector?.close();
    _objectDetector = null;
    print('Set detector in mode: $_mode');

    // default model
    if (_option == 0) {
      print('use the default model');
      final options = ObjectDetectorOptions(
        mode: _mode,
        classifyObjects: true,
        multipleObjects: true,
      );
      _objectDetector = ObjectDetector(options: options);
    }
    // custom model from _options
    else if (_option > 0 && _option <= _options.length) {
      final option = _options[_options.keys.toList()[_option]] ?? '';
      final modelPath = await getAssetPath('assets/ml/$option');
      print('use custom model path: $modelPath');
      final options = LocalObjectDetectorOptions(
        mode: _mode,
        modelPath: modelPath,
        classifyObjects: true,
        multipleObjects: true,
        confidenceThreshold: 0.1,
      );
      _objectDetector = ObjectDetector(options: options);
    }

    _canProcess = true;
  }

  Future<void> _processObjectImage(InputImage inputImage) async {
    if (_objectDetector == null) return;
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;
    setState(() {
      _text = '';
    });

    final objects = await _objectDetector!.processImage(inputImage);
    if (inputImage.metadata?.size != null &&
        inputImage.metadata?.rotation != null) {
      final painter = ObjectDetectorPainter(
        objects,
        inputImage.metadata!.size,
        inputImage.metadata!.rotation,
        _cameraLensDirection,
      );
      _customPaint = CustomPaint(painter: painter);
    } else {
      String text = 'Objects found: ${objects.length}\n\n';
      for (final object in objects) {
        text +=
            'Object:  trackingId: ${object.trackingId} - ${object.labels.map((e) => e.text)}\n\n';
      }
      _text = text;
      _customPaint = null;
    }

    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }
}
