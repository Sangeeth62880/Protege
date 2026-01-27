import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Simple logger utility for debugging
class AppLogger {
  AppLogger._();

  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      developer.log(
        message,
        name: tag ?? 'Protégé',
        level: 500,
      );
    }
  }

  static void info(String message, {String? tag}) {
    if (kDebugMode) {
      developer.log(
        '💡 $message',
        name: tag ?? 'Protégé',
        level: 800,
      );
    }
  }

  static void warning(String message, {String? tag}) {
    if (kDebugMode) {
      developer.log(
        '⚠️ $message',
        name: tag ?? 'Protégé',
        level: 900,
      );
    }
  }

  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      developer.log(
        '❌ $message',
        name: tag ?? 'Protégé',
        level: 1000,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static void success(String message, {String? tag}) {
    if (kDebugMode) {
      developer.log(
        '✅ $message',
        name: tag ?? 'Protégé',
        level: 800,
      );
    }
  }
}
