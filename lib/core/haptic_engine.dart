import 'package:flutter/services.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class HapticEngine {
  HapticEngine._();

  static Future<void> triggerSelection() async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      await HapticFeedback.selectionClick();
    }
  }

  static Future<void> triggerSuccess() async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      await HapticFeedback.lightImpact();
    }
  }

  static Future<void> triggerWarning() async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      await HapticFeedback.mediumImpact();
    }
  }

  static Future<void> triggerError() async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      await HapticFeedback.heavyImpact();
    }
  }
}
