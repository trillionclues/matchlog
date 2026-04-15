# MatchLog — Security

> Authentication, authorization, data protection, app store compliance, and secure communications.

---

## Authentication Architecture

### Phase 1-3: Firebase Auth

```
┌─────────────┐     ┌──────────────┐     ┌──────────────┐
│  Flutter App │────▶│ Firebase Auth │────▶│ Google OAuth  │
│              │     │              │     │ Email/Pass    │
│  Stores:     │     │  Provides:   │     └──────────────┘
│  - ID Token  │◀────│  - UID       │
│  - Refresh   │     │  - ID Token  │
│    Token     │     │  - Claims    │
└─────────────┘     └──────────────┘
       │
       │ ID Token in Authorization header
       ▼
┌──────────────┐
│ Firestore     │
│ Security Rules│  ← Validates token server-side
└──────────────┘
```

### Phase 4+: Spring Boot JWT

```
┌─────────────┐     ┌──────────────┐     ┌──────────────┐
│  Flutter App │────▶│ Spring Boot  │────▶│ PostgreSQL   │
│              │     │ /auth/login  │     │ users table  │
│  Stores:     │     │              │     └──────────────┘
│  - JWT Access│◀────│  Returns:    │
│  - Refresh   │     │  - JWT (15m) │
│    Token     │     │  - Refresh   │
└─────────────┘     │    (7d)      │
       │            └──────────────┘
       │ JWT in Authorization header
       ▼
┌──────────────┐
│ Spring Security│
│ Filter Chain  │  ← Validates JWT per request
└──────────────┘
```

---

## Auth Providers

| Provider | Phase | Implementation |
|----------|-------|---------------|
| **Google Sign-In** | Phase 1 | `firebase_auth` + `google_sign_in` plugin |
| **Email/Password** | Phase 1 | `firebase_auth` createUserWithEmailAndPassword |
| **Apple Sign-In** | Phase 1 | Required for iOS App Store. `firebase_auth` + `sign_in_with_apple` |
| **JWT** | Phase 4 | Custom Spring Boot auth with `spring-boot-starter-security` |

### Firebase Auth Implementation

```dart
class FirebaseAuthSource {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Google Sign-In
  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) throw AuthCancelledException();

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await _auth.signInWithCredential(credential);
  }

  // Email/Password
  Future<UserCredential> signUpWithEmail(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Apple Sign-In (required for iOS)
  Future<UserCredential> signInWithApple() async {
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
    );

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );

    return await _auth.signInWithCredential(oauthCredential);
  }

  // Sign out
  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current user
  User? get currentUser => _auth.currentUser;

  // Get ID token for API calls
  Future<String?> getIdToken() async {
    return await _auth.currentUser?.getIdToken();
  }
}
```

---

## Token Management

### Secure Storage

```dart
class TokenManager {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _accessTokenKey = 'ml_access_token';
  static const _refreshTokenKey = 'ml_refresh_token';

  Future<void> saveTokens({required String access, required String refresh}) async {
    await _storage.write(key: _accessTokenKey, value: access);
    await _storage.write(key: _refreshTokenKey, value: refresh);
  }

  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);
  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}
```

### Dio Auth Interceptor

```dart
class AuthInterceptor extends Interceptor {
  final TokenManager _tokenManager;
  final Dio _dio; // Separate Dio instance for token refresh

  AuthInterceptor(this._tokenManager, this._dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _tokenManager.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Attempt token refresh
      final refreshToken = await _tokenManager.getRefreshToken();
      if (refreshToken != null) {
        try {
          final response = await _dio.post('/auth/refresh', data: {
            'refreshToken': refreshToken,
          });

          final newAccess = response.data['accessToken'];
          final newRefresh = response.data['refreshToken'];
          await _tokenManager.saveTokens(access: newAccess, refresh: newRefresh);

          // Retry original request with new token
          err.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
          final retryResponse = await _dio.fetch(err.requestOptions);
          handler.resolve(retryResponse);
          return;
        } catch (_) {
          // Refresh failed → force logout
          await _tokenManager.clearTokens();
        }
      }
    }
    handler.next(err);
  }
}
```

---

## Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper: check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }

    // Helper: check if user owns the document
    function isOwner(userId) {
      return request.auth.uid == userId;
    }

    // Helper: check tier
    function userTier() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.tier;
    }

    // Helper: is Pro or Crew
    function isPaidUser() {
      return userTier() in ['pro', 'crew'];
    }

    // Users
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow create: if isOwner(userId);
      allow update: if isOwner(userId);
      allow delete: if false;  // Users can't delete their account via Firestore
    }

    // Match Entries
    match /match_entries/{entryId} {
      allow create: if isAuthenticated()
        && isOwner(request.resource.data.userId)
        && request.resource.data.rating >= 1
        && request.resource.data.rating <= 5;
      allow read: if isAuthenticated();
      allow update: if isOwner(resource.data.userId);
      allow delete: if isOwner(resource.data.userId);
    }

    // Bet Entries
    match /bet_entries/{betId} {
      allow create: if isAuthenticated()
        && isOwner(request.resource.data.userId);

      // Read: public bets visible to all, friends-only check follow status
      allow read: if isAuthenticated() && (
        resource.data.visibility == 'public'
        || isOwner(resource.data.userId)
        || (resource.data.visibility == 'friends'
            && exists(/databases/$(database)/documents/follows/$(request.auth.uid + '_' + resource.data.userId)))
      );

      allow update: if isOwner(resource.data.userId);
      allow delete: if isOwner(resource.data.userId);
    }

    // Bookie Groups
    match /bookie_groups/{groupId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update: if isOwner(resource.data.adminId);
      allow delete: if isOwner(resource.data.adminId);

      // Tier gate: Free users can only create 1 group
      // This is enforced in app logic + Cloud Functions, not rules

      match /members/{memberId} {
        allow read: if isAuthenticated();
        allow create: if isAuthenticated() && isOwner(memberId);
        allow update: if isOwner(memberId)
          || isOwner(get(/databases/$(database)/documents/bookie_groups/$(groupId)).data.adminId);
        allow delete: if isOwner(memberId)
          || isOwner(get(/databases/$(database)/documents/bookie_groups/$(groupId)).data.adminId);
      }

      match /predictions/{predId} {
        allow read: if isAuthenticated();
        // Can only create predictions before kickoff (enforced in app logic)
        allow create: if isAuthenticated()
          && isOwner(request.resource.data.userId);
        allow update: if isOwner(resource.data.userId);
        allow delete: if false;  // Predictions are permanent
      }
    }

    // Follows
    match /follows/{followId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated()
        && isOwner(request.resource.data.followerId);
      allow delete: if isAuthenticated()
        && isOwner(resource.data.followerId);
    }

    // Activity Feed (read-only for users, written by Cloud Functions)
    match /activity_feed/{activityId} {
      allow read: if isAuthenticated();
      allow write: if false;  // Only Cloud Functions write to feed
    }
  }
}
```

---

## Spring Boot Security (Phase 4)

### Security Filter Chain

```java
@Configuration
@EnableWebSecurity
@EnableMethodSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        return http
            .csrf(csrf -> csrf.disable()) // Mobile API, no CSRF needed
            .cors(cors -> cors.configurationSource(corsConfigurationSource()))
            .sessionManagement(session ->
                session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/auth/**").permitAll()
                .requestMatchers("/api/health").permitAll()
                .requestMatchers("/api/**").authenticated()
            )
            .addFilterBefore(jwtAuthFilter(), UsernamePasswordAuthenticationFilter.class)
            .build();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration config = new CorsConfiguration();
        config.setAllowedOrigins(List.of("*")); // Mobile app, allow all
        config.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "PATCH"));
        config.setAllowedHeaders(List.of("*"));
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
    }
}
```

### JWT Token Provider

```java
@Component
public class JwtTokenProvider {
    @Value("${jwt.secret}")
    private String secret;

    @Value("${jwt.access-expiration-ms}")
    private long accessExpirationMs; // 15 minutes

    @Value("${jwt.refresh-expiration-ms}")
    private long refreshExpirationMs; // 7 days

    public String generateAccessToken(String userId) {
        return Jwts.builder()
            .setSubject(userId)
            .setIssuedAt(new Date())
            .setExpiration(new Date(System.currentTimeMillis() + accessExpirationMs))
            .signWith(Keys.hmacShaKeyFor(secret.getBytes()), SignatureAlgorithm.HS256)
            .compact();
    }

    public String generateRefreshToken(String userId) {
        return Jwts.builder()
            .setSubject(userId)
            .setIssuedAt(new Date())
            .setExpiration(new Date(System.currentTimeMillis() + refreshExpirationMs))
            .signWith(Keys.hmacShaKeyFor(secret.getBytes()), SignatureAlgorithm.HS256)
            .compact();
    }

    public String validateTokenAndGetUserId(String token) {
        return Jwts.parserBuilder()
            .setSigningKey(Keys.hmacShaKeyFor(secret.getBytes()))
            .build()
            .parseClaimsJws(token)
            .getBody()
            .getSubject();
    }
}
```

---

## Data Privacy & Compliance

### User Data Handling

| Data Type | Storage | Encryption | Retention |
|-----------|---------|-----------|-----------|
| **Email/Password** | Firebase Auth (Google infra) | At rest + in transit | Until account deletion |
| **Match diary** | Firestore → PostgreSQL | At rest (Google/AWS) | Until user deletes |
| **Bet entries** | Firestore → PostgreSQL | At rest | Until user deletes |
| **Photos** | Firebase Storage | At rest (AES-256) | Until user deletes |
| **JWT tokens** | flutter_secure_storage | Keychain (iOS) / EncryptedSharedPrefs (Android) | Session duration |
| **Local database** | Drift (SQLite) | Device-level encryption | App lifecycle |

### Privacy Controls

```dart
class PrivacySettings {
  final bool showBettingStats;       // Show ROI on public profile
  final ProfileVisibility profileVisibility;  // public, friends, private
  final bool allowDiscovery;         // Appear in search results
  final bool shareActivityToFeed;    // Post actions to friend feed
}
```

### Account Deletion

Required by both Apple and Google Play Store policies:

```dart
// Must delete ALL user data across all services
Future<void> deleteAccount() async {
  final userId = currentUser.uid;

  // 1. Delete Firestore data
  await _deleteCollection('match_entries', userId);
  await _deleteCollection('bet_entries', userId);
  await _deleteCollection('follows', userId);
  // ... all collections

  // 2. Delete Storage files
  await _deleteStorageFolder('users/$userId');

  // 3. Delete Firebase Auth account
  await FirebaseAuth.instance.currentUser?.delete();

  // 4. Clear local data
  await AppDatabase.instance.deleteAllUserData(userId);
  await TokenManager().clearTokens();
}
```

---

## App Store Compliance

### Betting App Guidelines

| Platform | Key Rule | Our Approach |
|----------|---------|-------------|
| **Google Play** | Apps that facilitate real-money gambling need specific licensing | We don't facilitate gambling. We're a diary/tracker. Manual bet logging only. |
| **Apple App Store** | Guideline 5.3.3: Real-money gaming apps must use native tech for Apple devices | We don't process payments for bets. In-app purchases use Apple's IAP. |
| **Both** | Age rating: must declare gambling-related content | Declare 17+ rating. Include disclaimer: "This app does not facilitate betting." |

### Required App Store Disclaimers

```
"MatchLog is a sports diary and personal journal. It does not
facilitate, process, or encourage real-money gambling. The betting
tracker feature allows users to manually log their existing bets
for personal record-keeping and analytics purposes only."
```

---

## Deep Link Security

### App Links (Android) / Universal Links (iOS)

```json
// /.well-known/assetlinks.json (served from matchlog.app domain)
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.matchlog.app",
    "sha256_cert_fingerprints": ["YOUR_SHA256_FINGERPRINT"]
  }
}]
```

```json
// /.well-known/apple-app-site-association
{
  "applinks": {
    "apps": [],
    "details": [{
      "appID": "TEAM_ID.com.matchlog.app",
      "paths": ["/group/*", "/profile/*", "/prediction/*", "/invite/*"]
    }]
  }
}
```

### Deep Link Validation

```dart
// Validate invite codes before joining
Future<void> handleGroupInvite(String inviteCode) async {
  // 1. Sanitize input (alphanumeric only, 6 chars)
  if (!RegExp(r'^[A-Z0-9]{6}$').hasMatch(inviteCode.toUpperCase())) {
    throw InvalidInviteCodeException();
  }

  // 2. Verify group exists
  final group = await _groupRepo.findByInviteCode(inviteCode);
  if (group == null) throw GroupNotFoundException();

  // 3. Check membership limit (free tier: 5 members)
  if (group.memberCount >= _maxMembers) throw GroupFullException();

  // 4. Check if already a member
  final isMember = await _groupRepo.isMember(group.id, currentUser.id);
  if (isMember) throw AlreadyMemberException();

  // 5. Join group
  await _groupRepo.addMember(group.id, currentUser.id);
}
```

---

## Rate Limiting

### Client-Side

```dart
class RateLimiter {
  final Map<String, List<DateTime>> _requests = {};

  bool canMakeRequest(String endpoint, {int maxPerMinute = 30}) {
    final now = DateTime.now();
    final windowStart = now.subtract(const Duration(minutes: 1));

    _requests[endpoint] = (_requests[endpoint] ?? [])
        .where((t) => t.isAfter(windowStart))
        .toList();

    if (_requests[endpoint]!.length >= maxPerMinute) return false;

    _requests[endpoint]!.add(now);
    return true;
  }
}
```

### Server-Side (Spring Boot, Phase 4)

```java
// Redis-backed rate limiter (same pattern as Mockline)
@Component
public class RateLimitFilter extends OncePerRequestFilter {
    @Autowired
    private RedisTemplate<String, String> redisTemplate;

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                     HttpServletResponse response,
                                     FilterChain filterChain) throws Exception {
        String userId = SecurityContextHolder.getContext()
            .getAuthentication().getName();
        String key = "rate_limit:" + userId;

        Long count = redisTemplate.opsForValue().increment(key);
        if (count == 1) {
            redisTemplate.expire(key, 1, TimeUnit.MINUTES);
        }

        if (count > 60) { // 60 requests per minute per user
            response.setStatus(429);
            response.getWriter().write("{\"error\": \"Rate limit exceeded\"}");
            return;
        }

        filterChain.doFilter(request, response);
    }
}
```
