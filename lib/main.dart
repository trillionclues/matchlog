
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/di/service_locator.dart';

void main() async {
  await ServiceLocator.initialize();
  runApp(const ProviderScope(child: MatchLogApp()));
}
