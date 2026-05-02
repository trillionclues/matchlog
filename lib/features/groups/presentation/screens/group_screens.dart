library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bookie Groups')),
      body: const Center(child: Text('Groups')),
    );
  }
}

class CreateGroupScreen extends ConsumerWidget {
  const CreateGroupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Group')),
      body: const Center(child: Text('Create group form')),
    );
  }
}

class GroupDetailScreen extends ConsumerWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Group')),
      body: Center(child: Text('Group: $groupId')),
    );
  }
}

class JoinGroupScreen extends ConsumerWidget {
  final String code;

  const JoinGroupScreen({super.key, required this.code});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Group')),
      body: Center(child: Text('Invite code: $code')),
    );
  }
}
