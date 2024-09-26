import 'package:flutter/material.dart';
import 'package:ml_kit_implementation/cards/barcode_scanner.dart';
import 'package:ml_kit_implementation/cards/document_scanner.dart';
import 'package:ml_kit_implementation/features/ml_kit_feature.dart';
import 'package:ml_kit_implementation/widgets/feature_list_item.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ML Kit Feature Launcher',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home:
          const MyHomePage(), // Change this to HomePage to make it the default screen
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<MLKitFeature> features = [
    DocumentScannerFeature(),
    BarcodeScannerFeature(),
    // Add more features here...
  ];

  List<MLKitFeature> filteredFeatures = [];
  String searchQuery = '';
  String sortBy = 'Name';

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
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 380,
            child: AppBar(
              backgroundColor: Colors.white,
              title: const Text(
                'ML Kit Features',
                style: TextStyle(
                  fontFamily: 'Montserrat-ExtraBold',
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Search Box
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: 350,
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Search Features',
                    labelStyle:
                        const TextStyle(fontFamily: 'Montserrat-Medium'),
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

          const SizedBox(height: 20),

          // Sort Dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              width: 340, // Ensure dropdown width matches the TextField width
              child: DropdownButtonFormField<String>(
                value: sortBy,
                items: <String>['Name', 'Description'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: const TextStyle(
                        color: Colors.black, // Text color of dropdown items
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
              width: 350,
              child: ListView.builder(
                itemCount: filteredFeatures.length,
                itemBuilder: (context, index) {
                  final feature = filteredFeatures[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 0.0),
                    child: FeatureListItem(feature: feature),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
