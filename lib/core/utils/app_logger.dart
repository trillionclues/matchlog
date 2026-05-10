
library;

import 'dart:developer' as dev;
import 'package:matchlog/core/config/app_config.dart';

class AppLogger {
  AppLogger._();

  static void log(String message, {
    String tag = "Matchlog",
    Object? error,
    StackTrace? stackTrace,
  }){
    if(!AppConfig.instance.isStaging) return;
    dev.log(
      message,
      name: tag,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void diary(String message, {Object? error, StackTrace? st}) =>
      log(message, tag: 'Diary', error: error, stackTrace: st);

  static void firebase(String message, {Object? error, StackTrace? st}) =>
      log(message, tag: 'Firebase', error: error, stackTrace: st);

  static void db(String message, {Object? error, StackTrace? st}) =>
      log(message, tag: 'LocalDB', error: error, stackTrace: st);

  static void auth(String message, {Object? error, StackTrace? st}) =>
      log(message, tag: 'Auth', error: error, stackTrace: st);
}