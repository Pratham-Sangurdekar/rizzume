import 'dart:io';
import 'package:flutter/foundation.dart';
import 'constants.dart';

class AppConfig {
  static late String apiBase;

  // Call at startup
  static Future<void> init() async {
    // Simple environment selection:
    if (kDebugMode) {
      apiBase = Platform.isAndroid ? "http://10.0.2.2:8000" : AppConstants.defaultApiBase;
    } else {
      apiBase = AppConstants.defaultApiBase; // replace with prod URL
    }
  }
}