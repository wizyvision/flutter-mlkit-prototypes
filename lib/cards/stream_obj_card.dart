import 'package:flutter/material.dart';
import 'package:ml_kit_implementation/features/ml_kit_feature.dart';
import 'package:ml_kit_implementation/features/stream_obj.dart';

class StreamObjFeature extends MLKitFeature {
  StreamObjFeature()
      : super(
          name: "Stream Mode",
          description: "MLKit Object Detection",
          icon: Icons.select_all_outlined,
          color: Colors.yellow[100]!,
        );

  @override
  void launch(BuildContext context) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StreamObjScreen(),
      ),
    );
  }
}
