import 'package:flutter/material.dart';
import 'package:ml_kit_implementation/features/ml_kit_feature.dart';
import 'package:ml_kit_implementation/features/object_tracking_view.dart';

class ObjectTrackingFeature extends MLKitFeature {
  ObjectTrackingFeature()
      : super(
          name: "Object Tracker",
          description: "Detects Objects",
          icon: Icons.select_all_outlined,
          color: Colors.yellow[100]!,
        );

  @override
  void launch(BuildContext context) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ObjectTrackingView(),
      ),
    );
  }
}
