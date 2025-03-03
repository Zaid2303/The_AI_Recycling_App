import 'package:flutter/material.dart';

class AddBinsScreen extends StatefulWidget {
  final Map<String, dynamic>? existingBin; // Pass null for a new bin
  const AddBinsScreen({Key? key, this.existingBin}) : super(key: key);

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

  final List<String> _wasteTypes = [
    'Plastic Only',
    'Glass Only',
    'Paper/Cardboard Only',
    'Mixed Recycling',
    'Refuse Waste',
    'Other',
  ];

  String? _selectedColor;
  DateTime? _selectedDate;
  String? _selectedFrequency;
  int? _timeInterval;
  String? _selectedWasteType;

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
      _selectedWasteType =
          widget.existingBin!['wasteType'] ?? _wasteTypes.first;
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
        _selectedFrequency != null &&
        _selectedWasteType != null) {
      final bin = {
        'color': _selectedColor,
        'nextDate': _selectedDate.toString().split(' ')[0],
        'interval': _timeInterval.toString(),
        'frequency': _selectedFrequency,
        'wasteType': _selectedWasteType,
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
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bin Color:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedColor,
                      items: _colors.map((color) {
                        return DropdownMenuItem<String>(
                          value: color,
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Color(int.parse(_getColorCode(color))),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 12),
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
                      isExpanded: true,
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Next Collection Date:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedDate != null
                                ? _selectedDate!
                                    .toLocal()
                                    .toString()
                                    .split(' ')[0]
                                : 'Select Date',
                            style: TextStyle(
                              fontSize: 16,
                              color: _selectedDate == null
                                  ? Colors.grey
                                  : Colors.black,
                            ),
                          ),
                        ),
                        const Icon(Icons.calendar_today, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Collection Frequency:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _timeInterval,
                            items: List.generate(10, (index) => index + 1)
                                .map((number) {
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
                            isExpanded: true,
                            isDense: true,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
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
                            isExpanded: true,
                            isDense: true,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Waste Type:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedWasteType,
                      items: _wasteTypes.map((type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedWasteType = value;
                        });
                      },
                      isExpanded: true,
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _selectedColor != null &&
                          _selectedDate != null &&
                          _timeInterval != null &&
                          _selectedFrequency != null &&
                          _selectedWasteType != null
                      ? _saveBin
                      : null,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
