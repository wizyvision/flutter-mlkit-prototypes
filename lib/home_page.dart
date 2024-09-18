import 'package:flutter/material.dart';
import 'package:ml_kit_implementation/features/ml_kit_feature.dart';
import 'features/document_scanner.dart';
import 'features/barcode_scanner.dart';
import 'widgets/feature_list_item.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
          SizedBox(height: 40),
          Container(
            width: 380,
            child: AppBar(
              backgroundColor: Colors.white,
              title: Text(
                'ML Kit Features',
                style: TextStyle(
                  fontFamily: 'Montserrat-ExtraBold',
                ),
              ),
            ),
          ),

          SizedBox(height: 10),

          // Search Box
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: 350,
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Search Features',
                    labelStyle: TextStyle(fontFamily: 'Montserrat-Medium'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: _searchFeatures,
                ),
              ),
            ),
          ),

          SizedBox(height: 20),

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
                      style: TextStyle(
                        color: Colors.black, // Text color of dropdown items
                        fontFamily: 'Montserrat-SemiBold',
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (newValue) {
                  _sortFeatures(newValue!);
                },
                icon: Icon(Icons.sort, color: Colors.black),
                dropdownColor: Colors.white,
                decoration: InputDecoration.collapsed(hintText: ''),
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
