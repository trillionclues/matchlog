// Deep link handler
// Handles incoming App Links (Android) and Universal Links (iOS).

// - Parse /groups/join/:code URIs
// - Parse /profile/:userId URIs
// - Use app_links package to receive the URI
// - Delegate to AppRouter for navigation

// Android: requires /.well-known/assetlinks.json on matchlog.app domain
// iOS: requires /.well-known/apple-app-site-association on matchlog.app domain
// I might look to deploy these to cloudflare or firebase pages
library;

class DeepLinkHandler {
  const DeepLinkHandler();

  void handle(Uri uri) {
    // TODO(phase2): Parse URI and navigate to the correct screen
    // Examples:
    //   matchlog.app/groups/join/MNC25X → Routes.joinGroupPath('MNC25X')
    //   matchlog.app/profile/user_123   → Routes.userProfilePath('user_123')
  }
}
