library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/providers/auth_providers.dart';

class MatchLogApp extends ConsumerWidget {
  const MatchLogApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return _AuthLifecycleScope(
      child: MaterialApp.router(
        title: 'MatchLog',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class _AuthLifecycleScope extends ConsumerStatefulWidget {
  final Widget child;

  const _AuthLifecycleScope({required this.child});

  @override
  ConsumerState<_AuthLifecycleScope> createState() =>
      _AuthLifecycleScopeState();
}

class _AuthLifecycleScopeState extends ConsumerState<_AuthLifecycleScope>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(checkEmailVerifiedProvider).call();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
