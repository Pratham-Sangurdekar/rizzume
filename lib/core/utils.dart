import 'package:flutter/material.dart';

class Utils {
  // Simple helper: show a snack bar
  static void showSnackbar(BuildContext context, String message, {bool error = false}) {
    final snack = SnackBar(
      content: Text(message),
      backgroundColor: error ? Colors.redAccent : Colors.black87,
      duration: const Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snack);
  }

  // Truncate text safely
  static String truncate(String text, [int max = 100]) {
    if (text.length <= max) return text;
    return text.substring(0, max - 3) + '...';
  }
}