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
      appBar: AppBar(
        title: Text('ML Kit Features'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Search Bar
            TextField(
              decoration: InputDecoration(
                labelText: 'Search Features',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _searchFeatures,
            ),
            SizedBox(height: 10),
            // Sort Dropdown
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text("Sort by: "),
                DropdownButton<String>(
                  value: sortBy,
                  items: <String>['Name', 'Description'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    _sortFeatures(newValue!);
                  },
                ),
              ],
            ),
            SizedBox(height: 10),
            // List of Features
            Expanded(
              child: ListView.builder(
                itemCount: filteredFeatures.length,
                itemBuilder: (context, index) {
                  final feature = filteredFeatures[index];
                  return FeatureListItem(feature: feature); // Refactored widget
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
