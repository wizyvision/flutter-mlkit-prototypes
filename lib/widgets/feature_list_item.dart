import 'package:flutter/material.dart';
import '../features/ml_kit_feature.dart';
import '../utils/color_utils.dart';

class FeatureListItem extends StatelessWidget {
  final MLKitFeature feature;

  const FeatureListItem({super.key, required this.feature});

  @override
  Widget build(BuildContext context) {
    final Color cardColor = feature.color;
    final Color textIconColor = darken(cardColor, 0.5);

    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.symmetric(
          vertical: screenHeight * 0.01), // Adaptive padding
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
            size: screenWidth * 0.1, // Adaptive icon size
          ),
          title: Text(
            feature.name,
            style: TextStyle(
              fontSize: screenWidth * 0.04, // Adaptive text size
              fontFamily: 'Montserrat-Bold',
              fontWeight: FontWeight.bold,
              color: textIconColor,
            ),
          ),
          subtitle: Text(
            feature.description,
            style: TextStyle(
              color: textIconColor,
              fontSize: screenWidth * 0.03, // Adaptive text size
              fontFamily: 'Montserrat-Medium',
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            color: textIconColor,
            size: screenWidth * 0.05, // Adaptive icon size
          ),
          onTap: () => feature.launch(context),
        ),
      ),
    );
  }
}
