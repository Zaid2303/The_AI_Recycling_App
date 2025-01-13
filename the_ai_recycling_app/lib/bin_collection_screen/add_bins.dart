import 'package:flutter/material.dart';

class AddBinsScreen extends StatefulWidget {
  final Map<String, dynamic>? existingBin; // Pass null for a new bin
  const AddBinsScreen({this.existingBin, Key? key}) : super(key: key);

  @override
  State<AddBinsScreen> createState() => _AddBinsScreenState();
}

class _AddBinsScreenState extends State<AddBinsScreen> {
  final List<String> _colors = [
    'Black',
    'Blue',
    'Burgundy',
    'Red',
    'Yellow',
    'Brown',
    'Green',
    'Grey',
    'Purple',
  ];

  final List<String> _frequencies = ['Daily', 'Weekly', 'Monthly', 'Annually'];
  String? _selectedColor;
  DateTime? _selectedDate;
  String? _selectedFrequency;
  int? _timeInterval;

  @override
  void initState() {
    super.initState();
    if (widget.existingBin != null) {
      _selectedColor = widget.existingBin!['color'] ?? _colors.first;
      _selectedDate = DateTime.tryParse(
        widget.existingBin!['nextDate']?.split(' ')?.first ?? '',
      );
      _timeInterval = int.tryParse(widget.existingBin!['interval'] ?? '1');
      _selectedFrequency =
          widget.existingBin!['frequency'] ?? _frequencies.first;
    }
  }

  void _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _saveBin() {
    if (_selectedColor != null &&
        _selectedDate != null &&
        _timeInterval != null &&
        _selectedFrequency != null) {
      final bin = {
        'color': _selectedColor,
        'nextDate': _selectedDate.toString().split(' ')[0],
        'interval': _timeInterval.toString(),
        'frequency': _selectedFrequency,
        'colorCode': _getColorCode(_selectedColor!),
      };
      Navigator.pop(context, bin); // Return the bin details
    }
  }

  String _getColorCode(String color) {
    switch (color.toLowerCase()) {
      case 'black':
        return '0xFF000000';
      case 'blue':
        return '0xFF0000FF';
      case 'burgundy':
        return '0xFF800020';
      case 'red':
        return '0xFFFF0000';
      case 'yellow':
        return '0xFFFFFF00';
      case 'brown':
        return '0xFFA52A2A';
      case 'green':
        return '0xFF008000';
      case 'grey':
        return '0xFF808080';
      case 'purple':
        return '0xFF800080';
      default:
        return '0xFF000000'; // Default to black
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add/Edit Bin'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bin Color:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedColor,
              items: _colors.map((color) {
                return DropdownMenuItem<String>(
                  value: color,
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        color: Color(int.parse(_getColorCode(color))),
                      ),
                      const SizedBox(width: 8),
                      Text(color),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedColor = value;
                });
              },
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            const Text(
              'Next Collection Date:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _selectedDate != null
                      ? _selectedDate!.toLocal().toString().split(' ')[0]
                      : 'Select Date',
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Time Interval:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<int>(
                    value: _timeInterval,
                    items:
                        List.generate(10, (index) => index + 1).map((number) {
                      return DropdownMenuItem<int>(
                        value: number,
                        child: Text('$number'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _timeInterval = value;
                      });
                    },
                    decoration:
                        const InputDecoration(border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    value: _selectedFrequency,
                    items: _frequencies.map((freq) {
                      return DropdownMenuItem<String>(
                        value: freq,
                        child: Text(freq),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedFrequency = value;
                      });
                    },
                    decoration:
                        const InputDecoration(border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: _saveBin,
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
