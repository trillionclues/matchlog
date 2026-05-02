library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:matchlog/features/auth/presentation/providers/auth_providers.dart';
import '../../../../core/router/routes.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const Text('Home'),
          ElevatedButton(
              onPressed: () {
                ref.read(authControllerProvider.notifier).signOut();
                context.go(Routes.login);
              },
              child: const Text('Logout')),
        ],
      ),
    );
  }
}
