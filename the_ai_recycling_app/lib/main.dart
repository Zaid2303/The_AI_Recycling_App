import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'bin_collection_screen/bin_collection_screen.dart';
import 'recycling_rush_screen.dart';
import 'camera_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ValueNotifier<bool> _isDarkMode = ValueNotifier<bool>(false);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isDarkMode,
      builder: (context, isDark, child) {
        return MaterialApp(
          title: 'EcoTrack',
          theme: ThemeData.light().copyWith(
            primaryColor: Colors.blue,
            textTheme: ThemeData.light().textTheme.apply(
                  fontFamily: 'Poppins',
                  bodyColor: Colors.black,
                  displayColor: Colors.black,
                ),
          ),
          darkTheme: ThemeData.dark().copyWith(
            primaryColor: Colors.blue,
            textTheme: ThemeData.dark().textTheme.apply(
                  fontFamily: 'Poppins',
                  bodyColor: Colors.white,
                  displayColor: Colors.white,
                ),
          ),
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          home: MainScreen(
            isDarkMode: _isDarkMode,
          ),
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  final ValueNotifier<bool> isDarkMode;
  const MainScreen({
    Key? key,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String _nextCollectionDate = "Loading...";
  String _binColor = "";
  String _apiStatus = "Loading stats...";
  Color _binColorCode = Colors.grey;
  Color _apiStatusColor = const Color(0xFF2196F3);
  final PageController _pageController =
      PageController(viewportFraction: 0.9, initialPage: 1);

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
            _nextCollectionDate = firstBin['nextDate'];
            _binColor = firstBin['color'];
            _binColorCode = Color(
              int.parse(
                firstBin['colorCode'].substring(2),
                radix: 16,
              ),
            );
          });
        }
      } catch (e) {
        debugPrint('Error parsing bin data: $e');
      }
    }
  }

  Future<void> _fetchApiData() async {
    try {
      await Future.delayed(const Duration(seconds: 2));
      final apiData = {
        "message": "You've recycled 10kg!",
        "colorCode": "#4CAF50"
      };

      setState(() {
        _apiStatus = "${apiData['message']}";
        _apiStatusColor = Color(
          int.parse(
                apiData['colorCode']!.substring(1),
                radix: 16,
              ) +
              0xFF000000,
        );
      });
    } catch (e) {
      setState(() {
        _apiStatus = "Update failed. Tap to retry";
        _apiStatusColor = Colors.red;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'EcoTrack',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: PageView(
        controller: _pageController,
        scrollDirection: Axis.horizontal,
        children: [
          // Settings Card (first card)
          _buildSettingsCard(screenHeight),
          // Scanner Card
          _buildLargeCard(
            color: Colors.orange,
            icon: Icons.camera_alt,
            title: "Recycling Scanner",
            subtitle: "Scan items to recycle",
            actionText: "Open Camera",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CameraScreen()),
            ),
            height: screenHeight * 0.6,
          ),
          // Bin Collection Card
          _buildLargeCard(
            color: _binColorCode,
            icon: Icons.delete_outline,
            title: "Next Collection",
            subtitle: _nextCollectionDate,
            actionText: _binColor.isNotEmpty ? "$_binColor bin" : "Set up",
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const BinCollectionScreen()),
              );
              _loadBinData();
            },
            height: screenHeight * 0.6,
          ),
          // Game Card
          _buildLargeCard(
            color: const Color(0xFF2196F3),
            icon: Icons.sports_esports,
            title: "Recycling Rush",
            subtitle: "Play our recycling game",
            actionText: "Start Game",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const RecyclingRushScreen()),
            ),
            height: screenHeight * 0.6,
          ),
          // Status Card
          _buildLargeStatusCard(
            color: _apiStatusColor,
            status: _apiStatus,
            onTap: _fetchApiData,
            height: screenHeight * 0.6,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(double height) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Container(
        height: height * 0.6,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Theme.of(context).colorScheme.surfaceVariant,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSettingsButton(
                icon: Icons.info,
                label: "About",
                onTap: () => _showAboutDialog(context),
              ),
              _buildSettingsButton(
                icon: Icons.login,
                label: "Log In",
                onTap: () => _showLogin(context),
              ),
              _buildSettingsButton(
                icon: Icons.dark_mode,
                label: "Dark Mode",
                onTap: () => widget.isDarkMode.value = !widget.isDarkMode.value,
              ),
              _buildSettingsButton(
                icon: Icons.settings,
                label: "Advanced Settings",
                onTap: () => _showAdvancedSettings(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, size: 30, color: Theme.of(context).iconTheme.color),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 20,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      onTap: onTap,
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About EcoTrack'),
        content: const Text('A sustainable recycling companion app'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLogin(BuildContext context) {
    // Implement login logic
  }

  void _showAdvancedSettings(BuildContext context) {
    // Implement advanced settings
  }

  Widget _buildLargeCard({
    required Color color,
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionText,
    required VoidCallback onTap,
    required double height,
  }) {
    // Calculate text color based on background color's luminance
    Color textColor =
        color.computeLuminance() < 0.5 ? Colors.white : Colors.black;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(100),
                blurRadius: 20,
                spreadRadius: 2,
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceVariant
                        .withAlpha(50),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 50, color: textColor),
                ),
                Column(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 28,
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 20,
                        color: textColor.withAlpha(200),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceVariant
                        .withAlpha(30),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    actionText,
                    style: TextStyle(
                      fontSize: 18,
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLargeStatusCard({
    required Color color,
    required String status,
    required VoidCallback onTap,
    required double height,
  }) {
    // Calculate text color based on background color's luminance
    Color textColor =
        color.computeLuminance() < 0.5 ? Colors.white : Colors.black;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withAlpha(200), color],
            ),
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(100),
                blurRadius: 20,
                spreadRadius: 2,
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.insights,
                  size: 60,
                  color: textColor,
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    status,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Icon(
                  Icons.touch_app,
                  size: 40,
                  color: textColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
