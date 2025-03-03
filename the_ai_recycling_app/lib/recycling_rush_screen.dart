import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'dart:async';
import 'dart:convert';

class RecyclingRushScreen extends StatefulWidget {
  const RecyclingRushScreen({Key? key}) : super(key: key);

  @override
  _RecyclingRushScreenState createState() => _RecyclingRushScreenState();
}

class _RecyclingRushScreenState extends State<RecyclingRushScreen> {
  final List<String> items = [
    "Paper",
    "Can",
    "Bottle",
    "Cardboard",
    "Plastic",
    "Pizza",
    "Burger",
    "Apple Core",
    "Banana Peel",
    "Trash",
  ];
  final Map<String, String> correctBins = {
    "Paper": "Paper Bin",
    "Can": "Recycle Bin",
    "Bottle": "Recycle Bin",
    "Cardboard": "Paper Bin",
    "Plastic": "Recycle Bin",
    "Pizza": "Compost Bin",
    "Burger": "Compost Bin",
    "Apple Core": "Compost Bin",
    "Banana Peel": "Compost Bin",
    "Trash": "Trash Bin",
  };

  String currentItem = "";
  String lastItem = "";
  int score = 0;
  String feedback = "";
  int timerDuration = 20;
  Timer? timer;
  bool isGameOver = false;
  bool isGameStarted = false;
  String selectedDifficulty = "Medium";
  Color feedbackColor = Colors.transparent;

  List<Map<String, dynamic>> highScores = [];
  List<String> powerUps = ["Extra Time", "Double Points", "Freeze Timer"];
  String? currentPowerUp;

  @override
  void initState() {
    super.initState();
    _loadHighScores();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      isGameStarted = true;
      score = 0;
      timerDuration = selectedDifficulty == "Easy"
          ? 30
          : selectedDifficulty == "Hard"
              ? 15
              : 20;
      _generateNewItem();
      _startTimer();
    });
  }

  void _generateNewItem() {
    String newItem;
    do {
      newItem = items[Random().nextInt(items.length)];
    } while (newItem == lastItem);

    setState(() {
      currentItem = newItem;
      lastItem = newItem;
      feedback = "";
      feedbackColor = Colors.transparent;
    });
  }

  void _startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timerDuration <= 0) {
        _endGame();
      } else {
        setState(() {
          timerDuration--;
        });
      }
    });
  }

  void _checkAnswer(String selectedBin) {
    if (isGameOver) return;

    setState(() {
      if (correctBins[currentItem] == selectedBin) {
        score += (currentPowerUp == "Double Points") ? 2 : 1;
        feedback = "Correct!";
        feedbackColor = Colors.green;

        if (score % 5 == 0) {
          currentPowerUp = powerUps[Random().nextInt(powerUps.length)];
          feedback = "Correct! Power-Up: $currentPowerUp";
        }
      } else {
        if (currentItem == "Trash") {
          score = 0;
          feedback = "Wrong! Points Reset!";
        } else {
          score -= 1;
          feedback = "Wrong!";
        }
        feedbackColor = Colors.red;
        timerDuration =
            timerDuration - 2 >= 1 ? timerDuration - 2 : 1; // Penalty
      }
    });
    _generateNewItem();
  }

  void _endGame() {
    timer?.cancel();
    setState(() {
      isGameOver = true;
    });

    _showGameOverDialog();
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        String playerName = "";
        return AlertDialog(
          title: const Text("Game Over!"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Your score: $score",
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: (value) => playerName = value,
                decoration: const InputDecoration(
                  hintText: "Enter your name",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _saveHighScore(playerName, score);
                Navigator.of(context).pop();
                setState(() {
                  isGameOver = false;
                  isGameStarted = false;
                });
              },
              child: const Text("Save & Exit"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveHighScore(String name, int score) async {
    final prefs = await SharedPreferences.getInstance();
    final newHighScore = {"name": name, "score": score};
    highScores.add(newHighScore);
    highScores.sort((a, b) => b['score'].compareTo(a['score']));
    if (highScores.length > 5) {
      highScores = highScores.sublist(0, 5);
    }
    await prefs.setString('highScores', jsonEncode(highScores));
    setState(() {});
  }

  Future<void> _loadHighScores() async {
    final prefs = await SharedPreferences.getInstance();
    final highScoresData = prefs.getString('highScores');
    if (highScoresData != null) {
      setState(() {
        highScores =
            List<Map<String, dynamic>>.from(jsonDecode(highScoresData));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Recycling Rush"),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isGameStarted
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!isGameOver) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          'Sort this item: $currentItem',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Center(
                      child: SingleChildScrollView(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: correctBins.values.toSet().map((bin) {
                            return Container(
                              margin: const EdgeInsets.all(8),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _checkAnswer(bin),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Ink(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.grey[200]!,
                                          Colors.white,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                        horizontal: 24,
                                      ),
                                      child: Text(
                                        bin,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: feedbackColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: feedbackColor.withOpacity(0.4)),
                      ),
                      child: Center(
                        child: Text(
                          feedback,
                          style: TextStyle(
                            fontSize: 16,
                            color: feedbackColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Score: $score',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Time Left: $timerDuration',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color:
                                  timerDuration < 5 ? Colors.red : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (currentPowerUp != null)
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.yellow, Colors.orange],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Power-Up: $currentPowerUp',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    const SizedBox(height: 32),
                    const Text(
                      "Leaderboard",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    (highScores.isEmpty)
                        ? const Center(
                            child: Text(
                              "No high scores yet!",
                              style: TextStyle(fontSize: 16),
                            ),
                          )
                        : Expanded(
                            child: ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount: highScores.length,
                              itemExtent: 50,
                              itemBuilder: (context, index) {
                                return Container(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        spreadRadius: 2,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "#${index + 1} ${highScores[index]['name']}",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        "${highScores[index]['score']}",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                    const SizedBox(height: 32),
                  ],
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Welcome to Recycling Rush!",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            selectedDifficulty = "Easy";
                          });
                          _startGame();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 32,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Icon(Icons.slow_motion_video),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            selectedDifficulty = "Medium";
                          });
                          _startGame();
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 32,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Icon(Icons.hourglass_bottom),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            selectedDifficulty = "Hard";
                          });
                          _startGame();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 32,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Icon(Icons.flash_on),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Difficulties:\n"
                    "\u2022 Easy: 30s - Slow timer\n"
                    "\u2022 Medium: 20s - Normal timer\n"
                    "\u2022 Hard: 15s - Fast timer",
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
      floatingActionButton: (!isGameOver && isGameStarted)
          ? FloatingActionButton(
              onPressed: _endGame,
              backgroundColor: Colors.deepOrange,
              child: const Icon(Icons.pause),
            )
          : null,
    );
  }
}
