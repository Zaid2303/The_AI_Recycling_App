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

/*
  void _restartTimer() {
    timer?.cancel();
    _startTimer();
  }
*/
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
        timerDuration = max(timerDuration - 2, 1); // Penalty: -2 seconds
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
              Text("Your score: $score"),
              TextField(
                onChanged: (value) => playerName = value,
                decoration: const InputDecoration(hintText: "Enter your name"),
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
              child: const Text("Save"),
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
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isGameStarted
            ? Column(
                children: [
                  if (!isGameOver) ...[
                    Text(
                      "Sort this item: $currentItem",
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: correctBins.values.toSet().map((bin) {
                        return ElevatedButton(
                          onPressed: () => _checkAnswer(bin),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: feedbackColor,
                          ),
                          child: Text(bin),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      feedback,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: feedbackColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Score: $score",
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Time Left: $timerDuration",
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    if (currentPowerUp != null)
                      Text(
                        "Power-Up: $currentPowerUp",
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                  ],
                  const SizedBox(height: 40),
                  const Text(
                    "Top Scores",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ...highScores.map((entry) {
                    return Text("${entry['name']}: ${entry['score']}");
                  }).toList(),
                ],
              )
            : Column(
                children: [
                  const Text(
                    "Welcome to Recycling Rush!",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        selectedDifficulty = "Easy";
                      });
                      _startGame();
                    },
                    child: const Text("Start (Easy)"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        selectedDifficulty = "Medium";
                      });
                      _startGame();
                    },
                    child: const Text("Start (Medium)"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        selectedDifficulty = "Hard";
                      });
                      _startGame();
                    },
                    child: const Text("Start (Hard)"),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Easy: 30 seconds, slower timer decrement\n"
                    "Medium: 20 seconds, normal timer decrement\n"
                    "Hard: 15 seconds, faster timer decrement",
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }
}
