// Reads build-time flags injected via `--dart-define`.

//   flutter run --dart-define=ENV=staging --dart-define=FOOTBALL_API_KEY=xxx
//   flutter build appbundle --dart-define=ENV=prod --dart-define=FOOTBALL_API_KEY=xxx
// Access anywhere after initialization:
//   AppConfig.instance.footballApiKey
//   AppConfig.instance.isStaging

library;

enum Environment {
  staging,prod,
}

class AppConfig {
  final Environment environment;

  // TheSportsDB or API-Football API key.
  final String footballApiKey;

  // Base URL for TheSportsDB or API-Football data API.
  final String footballApiBaseUrl;

  // Gemini API key for AI insights and notification copy.
  // Empty string in staging if not provided.
  final String geminiApiKey;

  static late AppConfig instance;

  AppConfig._({
    required this.environment,
    required this.footballApiKey,
    required this.footballApiBaseUrl,
    required this.geminiApiKey,
  });

  // Reads configuration from --dart-define build flags.
  factory AppConfig.fromEnvironment() {
    const envString =
        String.fromEnvironment('ENV', defaultValue: 'staging');

    return AppConfig._(
      environment:
          envString == 'prod' ? Environment.prod : Environment.staging,
      footballApiKey: const String.fromEnvironment('FOOTBALL_API_KEY'),
      footballApiBaseUrl: const String.fromEnvironment(
        'FOOTBALL_API_URL',
        defaultValue: 'https://www.thesportsdb.com/api/v1/json',
      ),
      geminiApiKey: const String.fromEnvironment(
        'GEMINI_API_KEY',
        defaultValue: '',
      ),
    );
  }

  bool get isStaging => environment == Environment.staging;

  bool get isProd => environment == Environment.prod;

  bool get hasGeminiKey => geminiApiKey.isNotEmpty;

  @override
  String toString() =>
      'AppConfig(env: $environment, apiUrl: $footballApiBaseUrl)';
}
