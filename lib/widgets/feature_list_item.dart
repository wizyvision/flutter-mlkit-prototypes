import 'package:flutter/material.dart';
import '../features/ml_kit_feature.dart';
import '../utils/color_utils.dart';

class FeatureListItem extends StatelessWidget {
  final MLKitFeature feature;

  FeatureListItem({required this.feature});

  @override
  Widget build(BuildContext context) {
    final Color cardColor = feature.color;
    final Color textIconColor = darken(cardColor, 0.5);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        color: cardColor,
        child: ListTile(
          leading: Icon(
            feature.icon,
            color: textIconColor,
            size: 40,
          ),
          title: Text(
            feature.name,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textIconColor,
            ),
          ),
          subtitle: Text(
            feature.description,
            style: TextStyle(color: textIconColor),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            color: textIconColor,
          ),
          onTap: () => feature.launch(context),
        ),
      ),
    );
  }
}
