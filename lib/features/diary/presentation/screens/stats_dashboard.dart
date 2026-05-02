library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StatsDashboard extends ConsumerWidget {
  const StatsDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: const Center(child: Text('Stats dashboard')),
    );
  }
}
