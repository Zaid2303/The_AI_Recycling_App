import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'bin_collection_screen/bin_collection_screen.dart';
import 'recycling_rush_screen.dart';
import 'camera_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recycling App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String binCollectionInfo = "Bin Collection";
  String apiDataInfo = "Loading API Data...";
  Color binBoxColor = Colors.grey[300]!;
  Color apiBoxColor = Colors.grey[300]!;

  @override
  void initState() {
    super.initState();
    _loadBinData();
    _fetchApiData();
  }

  Future<void> _loadBinData() async {
    final prefs = await SharedPreferences.getInstance();
    final binData = prefs.getString('binData');

    if (binData != null) {
      try {
        final List<dynamic> data = jsonDecode(binData);
        if (data.isNotEmpty) {
          final firstBin = data.first;
          setState(() {
            binCollectionInfo =
                "Next collection on ${firstBin['nextDate']} - ${firstBin['color']} bin";
            binBoxColor =
                Color(int.parse(firstBin['colorCode'].substring(2), radix: 16));
          });
        }
      } catch (e) {
        print('Error parsing bin data: $e');
      }
    }
  }

  Future<void> _fetchApiData() async {
    try {
      // Mock API call
      await Future.delayed(
          const Duration(seconds: 2)); // Simulating network delay
      final apiData = {
        "title": "Recycling Stats",
        "message": "You've recycled 10kg this week!",
        "colorCode": "#FF69B4" // Pink color
      };

      setState(() {
        apiDataInfo = "${apiData['title']}: ${apiData['message']}";
        apiBoxColor = Color(
            int.parse(apiData['colorCode']!.substring(1), radix: 16) +
                0xFF000000);
      });
    } catch (e) {
      print('Error fetching API data: $e');
      setState(() {
        apiDataInfo = "Failed to load API data.";
        apiBoxColor = Colors.red;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 80,
        titleSpacing: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () {
                Scaffold.of(context).openDrawer();
              },
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: const Icon(Icons.menu, color: Colors.white, size: 40),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CameraScreen(),
                  ),
                );
              },
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child:
                    const Icon(Icons.camera_alt, color: Colors.white, size: 40),
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Material(
            borderRadius: BorderRadius.circular(16.0),
            color: binBoxColor,
            child: InkWell(
              borderRadius: BorderRadius.circular(16.0),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BinCollectionScreen(),
                  ),
                );
                _loadBinData();
              },
              child: Container(
                height: 150,
                child: Center(
                  child: Text(
                    binCollectionInfo,
                    style: const TextStyle(fontSize: 20, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Material(
            borderRadius: BorderRadius.circular(16.0),
            color: Colors.green[300],
            child: InkWell(
              borderRadius: BorderRadius.circular(16.0),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RecyclingRushScreen(),
                  ),
                );
              },
              child: Container(
                height: 150,
                child: const Center(
                  child: Text(
                    "Play Recycling Rush",
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Material(
            borderRadius: BorderRadius.circular(16.0),
            color: apiBoxColor,
            child: InkWell(
              borderRadius: BorderRadius.circular(16.0),
              onTap: _fetchApiData,
              child: Container(
                height: 150,
                child: Center(
                  child: Text(
                    apiDataInfo,
                    style: const TextStyle(fontSize: 20, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.orange,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('About'),
              onTap: () {
                // Navigate to About Screen
              },
            ),
          ],
        ),
      ),
    );
  }
}
