import 'package:flutter/material.dart';
import 'bin_collection_screen/bin_collection_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

Future<void> debugSharedPreferences() async {
  final prefs = await SharedPreferences.getInstance();
  final keys = prefs.getKeys();

  for (var key in keys) {
    final value = prefs.get(key);
    print('$key: ${value is String ? jsonDecode(value) : value}');
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  debugSharedPreferences(); // Debug SharedPreferences before the app starts
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bin Collection App',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String binCollectionInfo = "Bin Collection";
  Color binBoxColor = Colors.grey[300]!; // Default color for no data

  @override
  void initState() {
    super.initState();
    _loadBinData();
  }

  Future<void> _loadBinData() async {
    final prefs = await SharedPreferences.getInstance();
    final binData = prefs.getString('binData');

    if (binData != null) {
      try {
        final List<dynamic> data = jsonDecode(binData);
        if (data.isNotEmpty) {
          final firstBin = data.first; // Use the first bin in the list
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
            // Menu Icon
            GestureDetector(
              onTap: () {
                // Open drawer
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
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          GestureDetector(
            onTap: () async {
              // Navigate to bin collection screen
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BinCollectionScreen(),
                ),
              );
              // Reload data after returning
              _loadBinData();
            },
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                color: binBoxColor,
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Center(
                child: Text(
                  binCollectionInfo,
                  style: const TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
