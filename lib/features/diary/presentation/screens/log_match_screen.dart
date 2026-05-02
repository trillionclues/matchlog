library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LogMatchScreen extends ConsumerWidget {
  const LogMatchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log Match')),
      body: const Center(child: Text('Log match form')),
    );
  }
}
