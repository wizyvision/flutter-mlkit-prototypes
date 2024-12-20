import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:ml_kit_implementation/cards/barcode_multiple.dart';
import 'package:ml_kit_implementation/cards/barcode_single.dart';
import 'package:ml_kit_implementation/cards/document_scanner.dart';
import 'package:ml_kit_implementation/cards/object_tracking.dart';
import 'package:ml_kit_implementation/cards/single_obj_card.dart';
import 'package:ml_kit_implementation/cards/stream_obj_card.dart';
import 'package:ml_kit_implementation/features/barcode_provider.dart';
import 'package:ml_kit_implementation/features/camera_controller_notifier.dart';
import 'package:ml_kit_implementation/features/cameranew.dart';
import 'package:ml_kit_implementation/features/ml_kit_feature.dart';
import 'package:ml_kit_implementation/widgets/feature_list_item.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fetch available cameras
  final List<CameraDescription> cameras = await availableCameras();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              CameraControllerNotifier(), // Provide your CameraControllerNotifier
        ),
      ],
      child: MyApp(cameras: cameras),
    ),
  );
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const MyApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => BarcodeProvider())
      ],
      child: MaterialApp(
        title: 'ML Kit Feature Launcher',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: MyHomePage(cameras: cameras),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const MyHomePage({super.key, required this.cameras});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<MLKitFeature> filteredFeatures = [];
  String searchQuery = '';
  String sortBy = 'Name';

  final List<MLKitFeature> features = [
    DocumentScannerFeature(),
    BarcodeScannerFeature(),
    BarcodeSingleFeature(),
    ObjectTrackingFeature(),
    SingleObjFeature(),
    StreamObjFeature(),
    // Add more features here...
  ];

  @override
  void initState() {
    super.initState();
    filteredFeatures = features; // Initialize with all features
  }

  void _searchFeatures(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      filteredFeatures = features.where((feature) {
        return feature.name.toLowerCase().contains(searchQuery);
      }).toList();
      _sortFeatures(sortBy); // Re-apply sorting after search
    });
  }

  void _sortFeatures(String sortBy) {
    setState(() {
      this.sortBy = sortBy;
      if (sortBy == 'Name') {
        filteredFeatures.sort((a, b) => a.name.compareTo(b.name));
      } else if (sortBy == 'Description') {
        filteredFeatures.sort((a, b) => a.description.compareTo(b.description));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SizedBox(height: screenHeight * 0.05), // Adaptive top padding

          // Title Section with Camera Icon
          Container(
            width: screenWidth * 0.9, // Adaptive width
            child: AppBar(
              backgroundColor: Colors.white,
              title: const Text(
                'ML Kit Features',
                style: TextStyle(
                  fontFamily: 'Montserrat-ExtraBold',
                  fontSize: 24, // Adaptive font size
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.camera_alt, color: Colors.black),
                  onPressed: () {
                    // Navigate to CameraNewView when the icon is pressed
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CameraNewView(
                          cameras: widget.cameras,
                          onImage: (inputImage, controller) {
                            // Handle what happens with the image here
                          },
                          isPaused: false,
                          onCapturePressed: () async {}, // Adjust as needed
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          SizedBox(height: screenHeight * 0.02), // Adaptive spacing

          // Search Box
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: screenWidth * 0.9, // Adaptive width
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Search Features',
                    labelStyle: const TextStyle(
                      fontFamily: 'Montserrat-Medium',
                      fontSize: 16, // Adaptive font size
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onChanged: _searchFeatures,
                ),
              ),
            ),
          ),

          SizedBox(height: screenHeight * 0.03), // Adaptive spacing

          // Sort Dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              width: screenWidth * 0.85, // Adaptive width
              child: DropdownButtonFormField<String>(
                value: sortBy,
                items: <String>['Name', 'Description'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: const TextStyle(
                        color: Colors.black,
                        fontFamily: 'Montserrat-SemiBold',
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (newValue) {
                  _sortFeatures(newValue!);
                },
                icon: const Icon(Icons.sort, color: Colors.black),
                dropdownColor: Colors.white,
                decoration: const InputDecoration.collapsed(hintText: ''),
              ),
            ),
          ),

          // List of Features

          Expanded(
            child: Container(
              width: screenWidth * 0.9, // Adaptive width
              child: ListView.builder(
                itemCount: filteredFeatures.length,
                itemBuilder: (context, index) {
                  final feature = filteredFeatures[index];
                  return FeatureListItem(feature: feature);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
