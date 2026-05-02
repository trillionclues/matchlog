library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LogBetScreen extends ConsumerWidget {
  const LogBetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log Bet')),
      body: const Center(child: Text('Log bet form')),
    );
  }
}
