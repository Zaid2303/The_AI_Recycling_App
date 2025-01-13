import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'
    as shared_preferences;
import 'dart:convert';
import 'add_bins.dart';

class BinCollectionScreen extends StatefulWidget {
  const BinCollectionScreen({Key? key}) : super(key: key);

  @override
  State<BinCollectionScreen> createState() => _BinCollectionScreenState();
}

class _BinCollectionScreenState extends State<BinCollectionScreen> {
  List<Map<String, dynamic>> bins = [];
  bool isEditMode = false;

  @override
  void initState() {
    super.initState();
    _loadBinData();
  }

  Future<void> _loadBinData() async {
    final prefs = await shared_preferences.SharedPreferences.getInstance();
    final binData = prefs.getString('binData');

    if (binData != null) {
      try {
        final data = jsonDecode(binData);
        if (data is List) {
          setState(() {
            bins = List<Map<String, dynamic>>.from(data);
          });
        }
      } catch (e) {
        print('Error parsing bin data: $e');
      }
    }
  }

  Future<void> _saveBinData() async {
    final prefs = await shared_preferences.SharedPreferences.getInstance();
    await prefs.setString('binData', jsonEncode(bins));
  }

  void _deleteBin(int index) {
    setState(() {
      bins.removeAt(index);
    });
    _saveBinData();
  }

  void _navigateToAddBin({Map<String, dynamic>? bin}) async {
    final newBin = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => AddBinsScreen(existingBin: bin)),
    );
    if (newBin != null) {
      setState(() {
        if (bin != null) {
          bins[bins.indexOf(bin)] = newBin; // Edit existing bin
        } else {
          bins.add(newBin); // Add new bin
        }
      });
      _saveBinData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bin Collection App'),
        actions: [
          IconButton(
            icon: Icon(isEditMode ? Icons.close : Icons.edit),
            onPressed: () {
              setState(() {
                isEditMode = !isEditMode;
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Current Bins:',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: bins.length,
                itemBuilder: (context, index) {
                  final bin = bins[index];
                  return ListTile(
                    title: Text('${bin['color']} Bin'),
                    subtitle: Text('Next Collection: ${bin['nextDate']}'),
                    trailing: isEditMode
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _navigateToAddBin(bin: bin),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _deleteBin(index),
                              ),
                            ],
                          )
                        : null,
                  );
                },
              ),
            ),
            if (isEditMode)
              ElevatedButton(
                onPressed: () => _navigateToAddBin(),
                child: const Text('Add Bin'),
              ),
          ],
        ),
      ),
    );
  }
}
