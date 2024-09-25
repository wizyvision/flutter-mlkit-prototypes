import 'package:flutter/material.dart';
import 'package:ml_kit_implementation/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ML Kit Feature Launcher',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomePage(), // Change this to HomePage to make it the default screen
      debugShowCheckedModeBanner: false,
    );
  }
}
