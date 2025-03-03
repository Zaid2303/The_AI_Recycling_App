import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'
    as shared_preferences;
import 'dart:convert';
import 'add_bins.dart';

class BinCollectionScreen extends StatefulWidget {
  const BinCollectionScreen({super.key});

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

  int getFrequencyDays(String frequency) {
    switch (frequency.toLowerCase()) {
      case 'daily':
        return 1;
      case 'weekly':
        return 7;
      case 'monthly':
        return 30;
      case 'annually':
        return 365;
      default:
        return 1;
    }
  }

  Future<void> _loadBinData() async {
    final prefs = await shared_preferences.SharedPreferences.getInstance();
    final binData = prefs.getString('binData');

    List<Map<String, dynamic>> updatedBins = [];

    if (binData != null) {
      try {
        final data = jsonDecode(binData);
        if (data is List) {
          updatedBins = List<Map<String, dynamic>>.from(data);
          DateTime today = DateTime.now();

          for (var bin in updatedBins) {
            String nextDateStr = bin['nextDate'] ?? '';
            DateTime? nextDate;

            try {
              nextDate = DateTime.parse(nextDateStr);
            } catch (e) {
              debugPrint('Invalid date format for bin: $bin');
              nextDate = null;
            }

            if (nextDate != null && nextDate.isBefore(today)) {
              String intervalStr = bin['interval'] ?? '1';
              String frequency = bin['frequency'] ?? 'Daily';

              int interval = int.tryParse(intervalStr) ?? 1;
              int frequencyDays = getFrequencyDays(frequency);
              int daysPerPeriod = frequencyDays * interval;

              int daysSince = today.difference(nextDate).inDays;
              if (daysSince < 0) daysSince = 0;

              int periods = (daysSince + daysPerPeriod - 1) ~/ daysPerPeriod;
              DateTime newNextDate =
                  nextDate.add(Duration(days: periods * daysPerPeriod));

              bin['nextDate'] = newNextDate.toString().split(' ').first;
            }
          }

          updatedBins.sort((a, b) {
            DateTime aDate = DateTime.parse(a['nextDate'] ?? '');
            DateTime bDate = DateTime.parse(b['nextDate'] ?? '');
            return aDate.compareTo(bDate);
          });

          setState(() {
            bins = updatedBins;
          });

          await prefs.setString('binData', jsonEncode(updatedBins));
        } else {
          debugPrint('Bin data is not a list. Ignoring.');
        }
      } catch (e) {
        debugPrint('Error parsing bin data: $e');
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

  Future<void> _navigateToAddBin({Map<String, dynamic>? bin}) async {
    final newBin = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => AddBinsScreen(existingBin: bin)),
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
                  Map<String, dynamic> bin = bins[index];
                  return ListTile(
                    title: Text('${bin['color']} Bin'),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Next Collection: ${bin['nextDate'] ?? 'Not set'}'),
                          Text(
                              'Waste Type: ${bin['wasteType'] ?? 'Not specified'}'),
                        ],
                      ),
                    ),
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
                onPressed: _navigateToAddBin,
                child: const Text('Add Bin'),
              ),
          ],
        ),
      ),
    );
  }
}
