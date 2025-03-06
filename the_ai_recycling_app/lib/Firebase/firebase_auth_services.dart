import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

class FirebaseAuthService {
  Future<User?> signUpWithEmailAndPassword(
      String email, String password, String username) async {
    try {
      // Simulate authentication process
      await Future.delayed(const Duration(seconds: 2));

      // Save user data to SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('email', email);
      await prefs.setString('password', password);
      await prefs.setString('username', username);

      // Return a mock user
      return User(uid: 'mockUserId');
    } catch (e) {
      if (e.toString().contains('email-already-in-use')) {
        Fluttertoast.showToast(
          msg: 'The email address is already in use.',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      } else {
        Fluttertoast.showToast(
          msg: 'An error occurred: $e',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    }
    return null;
  }

  Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      // Simulate authentication process
      await Future.delayed(const Duration(seconds: 2));

      // Retrieve user data from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? storedEmail = prefs.getString('email');
      String? storedPassword = prefs.getString('password');

      if (storedEmail == email && storedPassword == password) {
        // Return a mock user
        return User(uid: 'mockUserId');
      } else {
        throw Exception('Invalid email or password');
      }
    } catch (e) {
      if (e.toString().contains('user-not-found') ||
          e.toString().contains('wrong-password')) {
        Fluttertoast.showToast(
          msg: 'Invalid email or password.',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      } else {
        Fluttertoast.showToast(
          msg: 'An error occurred: $e',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    }
    return null;
  }
}

class User {
  final String uid;

  User({required this.uid});
}
