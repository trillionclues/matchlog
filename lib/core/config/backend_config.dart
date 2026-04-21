// Backend type configuration.

// Controls which data source implementations are active throughout the app.
// The repository layer uses this to decide whether to call Firebase or the Spring Boot API.
// The switch is made by updating the [backendConfigProvider] in providers.dart.

library;

enum BackendType {
  // Firebase (Auth, Firestore, Storage, FCM)
  firebase,

  // Spring Boot REST API + PostgreSQL + Redis
  spring,
}

class BackendConfig {
  final BackendType type;

  const BackendConfig({this.type = BackendType.firebase});

  bool get isFirebase => type == BackendType.firebase;
  bool get isSpring => type == BackendType.spring;
}
