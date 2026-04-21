// Core app-wide Riverpod providers and all providers use keepAlive: true
// global Infra singletons available to every feature.
// Feature-specific providers live in their own files.

library;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/backend_config.dart';
import '../database/app_database.dart';

// Singleton AppDatabase instance.
// All feature repositories access Drift through this provider.
final appDatabaseProvider = Provider<AppDatabase>(
  (ref) {
    final db = AppDatabase();
    ref.onDispose(db.close);
    return db;
  },
  name: 'appDatabaseProvider',
);

// Emits [ConnectivityResult] whenever the network state changes.
// Used by repositories to decide whether to sync immediately or queue.
final connectivityProvider = StreamProvider<List<ConnectivityResult>>(
  (ref) => Connectivity().onConnectivityChanged,
  name: 'connectivityProvider',
);

// Convenience provider — true when any network connection is available.
final isOnlineProvider = Provider<bool>(
  (ref) {
    final connectivity = ref.watch(connectivityProvider);
    return connectivity.when(
      data: (results) => results.any((r) => r != ConnectivityResult.none),
      loading: () => false,
      error: (_, __) => false,
    );
  },
  name: 'isOnlineProvider',
);

// Active backend configuration.
// BackendType.firebase or BackendType.spring — presentation layer unchanged.
final backendConfigProvider = Provider<BackendConfig>(
  (ref) => const BackendConfig(type: BackendType.firebase),
  name: 'backendConfigProvider',
);
