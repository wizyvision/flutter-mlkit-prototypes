import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:ml_kit_implementation/cards/barcode_scanner.dart';
import 'package:ml_kit_implementation/cards/document_scanner.dart';
import 'package:ml_kit_implementation/features/barcode_provider.dart';
import 'package:ml_kit_implementation/features/ml_kit_feature.dart';
import 'package:ml_kit_implementation/widgets/feature_list_item.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
        home: const MyHomePage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<MLKitFeature> filteredFeatures = [];
  String searchQuery = '';
  String sortBy = 'Name';
  List<CameraDescription> cameras = [];
  CameraController? cameraController;

  final List<MLKitFeature> features = [
    DocumentScannerFeature(),
    BarcodeScannerFeature(),
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

          // Title Section
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
