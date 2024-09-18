import 'package:flutter/material.dart';

abstract class MLKitFeature {
  final String name;
  final String description;
  final IconData icon;
  final Color color; // Base color for the card

  MLKitFeature({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });

  void launch(BuildContext context);
}
